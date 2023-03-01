// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "src/ReferralSystem.sol";
import "src/RNSourceController.sol";
import "src/staking/Staking.sol";
import "src/LotterySetup.sol";
import "src/TicketUtils.sol";

/// @dev Lottery contract
/// It runs `selectionSize` / `selectionMax` type of lottery.
/// User buys the ticket by selecting total of `selectionSize` numbers from [1, selectionMax] range.
/// Ticket price is paid each time user buys a ticket.
/// Part of the price is staking reward, which is claimable to `stakingRewardRecipient`.
/// Part of the price is frontend reward which is claimable by frontend operators selling the ticket.
/// All fees, as well as rewards are paid in `rewardToken`.
/// All prizes are dynamic and dependant on the actual ticket sales.
contract Lottery is ILottery, Ticket, LotterySetup, ReferralSystem, RNSourceController {
    using SafeERC20 for IERC20;
    using TicketUtils for uint256;

    uint256 private claimedStakingRewardAtTicketId;
    mapping(address => uint256) private frontendDueTicketSales;
    mapping(uint128 => mapping(uint120 => uint256)) private unclaimedCount;

    address public immutable override stakingRewardRecipient;

    uint256 public override lastDrawFinalTicketId;

    bool public override drawExecutionInProgress;
    uint128 public override currentDraw;

    mapping(uint128 => uint120) public override winningTicket;
    mapping(uint128 => mapping(uint8 => uint256)) public override winAmount;

    mapping(uint128 => uint256) public override ticketsSold;
    int256 public override currentNetProfit;

    /// @dev Checks if ticket is a valid ticket, and reverts if invalid
    /// @param ticket Ticket being checked
    modifier requireValidTicket(uint256 ticket) {
        if (!ticket.isValidTicket(selectionSize, selectionMax)) {
            revert InvalidTicket();
        }
        _;
    }

    /// @dev Checks if we are not executing draw already.
    modifier whenNotExecutingDraw() {
        if (drawExecutionInProgress) {
            revert DrawAlreadyInProgress();
        }
        _;
    }

    /// @dev Checks if draw is being executed right now.
    modifier onlyWhenExecutingDraw() {
        if (!drawExecutionInProgress) {
            revert DrawNotInProgress();
        }
        _;
    }

    /// @dev Checks that ticket owner is caller of the function. Reverts if not called by ticket owner.
    /// @param ticketId Ticket id we are checking owner for.
    modifier onlyTicketOwner(uint256 ticketId) {
        if (ownerOf(ticketId) != msg.sender) {
            revert UnauthorizedClaim(ticketId, msg.sender);
        }
        _;
    }

    /// @dev Constructs a new lottery contract.
    /// @param lotterySetupParams Setup parameter for the lottery.
    /// @param playerRewardFirstDraw Rewards for players in native token for first draw.
    /// @param playerRewardDecreasePerDraw Decrease of rewards for players per each draw.
    /// @param rewardsToReferrersPerDraw Percentage of native token rewards going to players.
    /// @param maxRNFailedAttempts Maximum number of consecutive failed attempts for random number source.
    /// @param maxRNRequestDelay Time considered as maximum delay for RN request.
    // solhint-disable-next-line code-complexity
    constructor(
        LotterySetupParams memory lotterySetupParams,
        uint256 playerRewardFirstDraw,
        uint256 playerRewardDecreasePerDraw,
        uint256[] memory rewardsToReferrersPerDraw,
        uint256 maxRNFailedAttempts,
        uint256 maxRNRequestDelay
    )
        Ticket()
        LotterySetup(lotterySetupParams)
        ReferralSystem(playerRewardFirstDraw, playerRewardDecreasePerDraw, rewardsToReferrersPerDraw)
        RNSourceController(maxRNFailedAttempts, maxRNRequestDelay)
    {
        stakingRewardRecipient = address(
            new Staking(
            this,
            lotterySetupParams.token,
            nativeToken,
            "Staked LOT",
            "stLOT"
            )
        );

        nativeToken.safeTransfer(msg.sender, ILotteryToken(address(nativeToken)).INITIAL_SUPPLY());
    }

    function buyTickets(
        uint128[] calldata drawIds,
        uint120[] calldata tickets,
        address frontend,
        address referrer
    )
        external
        override
        requireJackpotInitialized
        returns (uint256[] memory ticketIds)
    {
        if (drawIds.length != tickets.length) {
            revert DrawsAndTicketsLenMismatch(drawIds.length, tickets.length);
        }
        ticketIds = new uint256[](tickets.length);
        for (uint256 i = 0; i < drawIds.length; ++i) {
            ticketIds[i] = registerTicket(drawIds[i], tickets[i], frontend, referrer);
        }
        referralRegisterTickets(currentDraw, referrer, msg.sender, tickets.length);
        frontendDueTicketSales[frontend] += tickets.length;
        rewardToken.safeTransferFrom(msg.sender, address(this), ticketPrice * tickets.length);
    }

    function executeDraw() external override whenNotExecutingDraw {
        // slither-disable-next-line timestamp
        if (block.timestamp < drawScheduledAt(currentDraw)) {
            revert ExecutingDrawTooEarly();
        }
        returnUnclaimedJackpotToThePot();
        drawExecutionInProgress = true;
        requestRandomNumber();
        emit StartedExecutingDraw(currentDraw);
    }

    function unclaimedRewards(LotteryRewardType rewardType) external view override returns (uint256 rewards) {
        uint256 dueTicketsSold = (rewardType == LotteryRewardType.FRONTEND)
            ? frontendDueTicketSales[msg.sender]
            : nextTicketId - claimedStakingRewardAtTicketId;
        rewards = LotteryMath.calculateRewards(ticketPrice, dueTicketsSold, rewardType);
    }

    function claimRewards(LotteryRewardType rewardType) external override returns (uint256 claimedAmount) {
        address beneficiary = (rewardType == LotteryRewardType.FRONTEND) ? msg.sender : stakingRewardRecipient;
        claimedAmount = LotteryMath.calculateRewards(ticketPrice, dueTicketsSoldAndReset(beneficiary), rewardType);

        emit ClaimedRewards(beneficiary, claimedAmount, rewardType);
        rewardToken.safeTransfer(beneficiary, claimedAmount);
    }

    function claimable(uint256 ticketId) external view override returns (uint256 claimableAmount, uint8 winTier) {
        TicketInfo memory ticketInfo = ticketsInfo[ticketId];
        if (!ticketInfo.claimed) {
            uint120 _winningTicket = winningTicket[ticketInfo.drawId];
            winTier = TicketUtils.ticketWinTier(ticketInfo.combination, _winningTicket, selectionSize, selectionMax);
            if (block.timestamp <= ticketRegistrationDeadline(ticketInfo.drawId + LotteryMath.DRAWS_PER_YEAR)) {
                claimableAmount = winAmount[ticketInfo.drawId][winTier];
            }
        }
    }

    function claimWinningTickets(uint256[] calldata ticketIds) external override returns (uint256 claimedAmount) {
        uint256 totalTickets = ticketIds.length;
        for (uint256 i = 0; i < totalTickets; ++i) {
            claimedAmount += claimWinningTicket(ticketIds[i]);
        }
        rewardToken.safeTransfer(msg.sender, claimedAmount);
    }

    /// @dev Registers the ticket in the system. To be called when user is buying the ticket.
    /// @param drawId Draw identifier ticket is bought for.
    /// @param ticket Combination packed as uint120.
    function registerTicket(
        uint128 drawId,
        uint120 ticket,
        address frontend,
        address referrer
    )
        private
        beforeTicketRegistrationDeadline(drawId)
        requireValidTicket(ticket)
        returns (uint256 ticketId)
    {
        ticketId = mint(msg.sender, drawId, ticket);
        unclaimedCount[drawId][ticket]++;
        ticketsSold[drawId]++;
        emit NewTicket(currentDraw, ticketId, drawId, msg.sender, ticket, frontend, referrer);
    }

    /// @dev Finalizes the draw after getting random number from source.
    /// Calculates the winning ticket. Splits jackpot rewards if there are matching tickets.
    /// Stores claimable amounts for each win tier and calculates net profit.
    /// Triggers referral system's mint for current draw to split the incentives.
    /// @param randomNumber The number that is received from source.
    function receiveRandomNumber(uint256 randomNumber) internal override onlyWhenExecutingDraw {
        uint120 _winningTicket = TicketUtils.reconstructTicket(randomNumber, selectionSize, selectionMax);
        uint128 drawFinalized = currentDraw++;
        uint256 jackpotWinners = unclaimedCount[drawFinalized][_winningTicket];

        if (jackpotWinners > 0) {
            winAmount[drawFinalized][selectionSize] = drawRewardSize(drawFinalized, selectionSize) / jackpotWinners;
        } else {
            for (uint8 winTier = 1; winTier < selectionSize; ++winTier) {
                winAmount[drawFinalized][winTier] = drawRewardSize(drawFinalized, winTier);
            }
        }

        currentNetProfit = LotteryMath.calculateNewProfit(
            currentNetProfit,
            ticketsSold[drawFinalized],
            ticketPrice,
            jackpotWinners > 0,
            fixedReward(selectionSize),
            expectedPayout
        );
        winningTicket[drawFinalized] = _winningTicket;
        drawExecutionInProgress = false;

        uint256 ticketsSoldDuringDraw = nextTicketId - lastDrawFinalTicketId;
        lastDrawFinalTicketId = nextTicketId;
        referralDrawFinalize(drawFinalized, ticketsSoldDuringDraw);

        emit FinishedExecutingDraw(drawFinalized, randomNumber, _winningTicket);
    }

    function currentRewardSize(uint8 winTier) public view override returns (uint256 rewardSize) {
        return drawRewardSize(currentDraw, winTier);
    }

    function drawRewardSize(uint128 drawId, uint8 winTier) private view returns (uint256 rewardSize) {
        return LotteryMath.calculateReward(
            currentNetProfit,
            fixedReward(winTier),
            fixedReward(selectionSize),
            ticketsSold[drawId],
            winTier == selectionSize,
            expectedPayout
        );
    }

    function dueTicketsSoldAndReset(address beneficiary) private returns (uint256 dueTickets) {
        if (beneficiary == stakingRewardRecipient) {
            dueTickets = nextTicketId - claimedStakingRewardAtTicketId;
            claimedStakingRewardAtTicketId = nextTicketId;
        } else {
            dueTickets = frontendDueTicketSales[beneficiary];
            frontendDueTicketSales[beneficiary] = 0;
        }
    }

    function claimWinningTicket(uint256 ticketId) private onlyTicketOwner(ticketId) returns (uint256 claimedAmount) {
        uint256 winTier;
        (claimedAmount, winTier) = this.claimable(ticketId);
        if (claimedAmount == 0) {
            revert NothingToClaim(ticketId);
        }

        unclaimedCount[ticketsInfo[ticketId].drawId][ticketsInfo[ticketId].combination]--;
        markAsClaimed(ticketId);
        emit ClaimedTicket(msg.sender, ticketId, claimedAmount);
    }

    function returnUnclaimedJackpotToThePot() private {
        if (currentDraw >= LotteryMath.DRAWS_PER_YEAR) {
            uint128 drawId = currentDraw - LotteryMath.DRAWS_PER_YEAR;
            uint256 unclaimedJackpotTickets = unclaimedCount[drawId][winningTicket[drawId]];
            currentNetProfit += int256(unclaimedJackpotTickets * winAmount[drawId][selectionSize]);
        }
    }

    function requireFinishedDraw(uint128 drawId) internal view override {
        if (drawId >= currentDraw) {
            revert DrawNotFinished(drawId);
        }
    }

    function mintNativeTokens(address mintTo, uint256 amount) internal override {
        ILotteryToken(address(nativeToken)).mint(mintTo, amount);
    }
}
