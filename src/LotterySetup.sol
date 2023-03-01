// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "src/PercentageMath.sol";
import "src/LotteryToken.sol";
import "src/interfaces/ILotterySetup.sol";
import "src/Ticket.sol";

contract LotterySetup is ILotterySetup {
    using PercentageMath for uint256;

    uint256 public immutable override minInitialPot;
    uint256 public immutable override jackpotBound;

    IERC20 public immutable override rewardToken;
    IERC20 public immutable override nativeToken;

    uint256 public immutable override ticketPrice;

    uint256 public override initialPot;

    uint256 public immutable override initialPotDeadline;
    uint256 internal immutable firstDrawSchedule;
    uint256 public immutable override drawPeriod;
    uint256 public immutable override drawCoolDownPeriod;

    uint8 public immutable override selectionSize;
    uint8 public immutable override selectionMax;
    uint256 public immutable override expectedPayout;

    uint256 private immutable nonJackpotFixedRewards;

    uint256 private constant BASE_JACKPOT_PERCENTAGE = 30_030; // 30.03%

    /// @dev Constructs a new lottery contract
    /// @param lotterySetupParams Setup parameter for the lottery
    // solhint-disable-next-line code-complexity
    constructor(LotterySetupParams memory lotterySetupParams) {
        if (address(lotterySetupParams.token) == address(0)) {
            revert RewardTokenZero();
        }
        if (lotterySetupParams.ticketPrice == uint256(0)) {
            revert TicketPriceZero();
        }
        if (lotterySetupParams.selectionSize == 0) {
            revert SelectionSizeZero();
        }
        if (lotterySetupParams.selectionMax >= 120) {
            revert SelectionSizeMaxTooBig();
        }
        if (
            lotterySetupParams.expectedPayout < lotterySetupParams.ticketPrice / 100
                || lotterySetupParams.expectedPayout >= lotterySetupParams.ticketPrice
        ) {
            revert InvalidExpectedPayout();
        }
        if (
            lotterySetupParams.selectionSize > 16 || lotterySetupParams.selectionSize >= lotterySetupParams.selectionMax
        ) {
            revert SelectionSizeTooBig();
        }
        if (
            lotterySetupParams.drawSchedule.drawCoolDownPeriod >= lotterySetupParams.drawSchedule.drawPeriod
                || lotterySetupParams.drawSchedule.firstDrawScheduledAt < lotterySetupParams.drawSchedule.drawPeriod
        ) {
            revert DrawPeriodInvalidSetup();
        }
        initialPotDeadline =
            lotterySetupParams.drawSchedule.firstDrawScheduledAt - lotterySetupParams.drawSchedule.drawPeriod;
        // slither-disable-next-line timestamp
        if (initialPotDeadline < (block.timestamp + lotterySetupParams.drawSchedule.drawPeriod)) {
            revert InitialPotPeriodTooShort();
        }

        nativeToken = new LotteryToken();
        uint256 tokenUnit = 10 ** IERC20Metadata(address(lotterySetupParams.token)).decimals();
        minInitialPot = 4 * tokenUnit;
        jackpotBound = 2_000_000 * tokenUnit;
        rewardToken = lotterySetupParams.token;
        firstDrawSchedule = lotterySetupParams.drawSchedule.firstDrawScheduledAt;
        drawPeriod = lotterySetupParams.drawSchedule.drawPeriod;
        drawCoolDownPeriod = lotterySetupParams.drawSchedule.drawCoolDownPeriod;
        ticketPrice = lotterySetupParams.ticketPrice;
        selectionSize = lotterySetupParams.selectionSize;
        selectionMax = lotterySetupParams.selectionMax;
        expectedPayout = lotterySetupParams.expectedPayout;

        nonJackpotFixedRewards = packFixedRewards(lotterySetupParams.fixedRewards);

        emit LotteryDeployed(
            lotterySetupParams.token,
            lotterySetupParams.drawSchedule,
            lotterySetupParams.ticketPrice,
            lotterySetupParams.selectionSize,
            lotterySetupParams.selectionMax,
            lotterySetupParams.expectedPayout,
            lotterySetupParams.fixedRewards
        );
    }

    modifier requireJackpotInitialized() {
        // slither-disable-next-line incorrect-equality
        if (initialPot == 0) {
            revert JackpotNotInitialized();
        }
        _;
    }

    modifier beforeTicketRegistrationDeadline(uint128 drawId) {
        // slither-disable-next-line timestamp
        if (block.timestamp > ticketRegistrationDeadline(drawId)) {
            revert TicketRegistrationClosed(drawId);
        }
        _;
    }

    function fixedReward(uint8 winTier) public view override returns (uint256 amount) {
        if (winTier == selectionSize) {
            return _baseJackpot(initialPot);
        } else if (winTier == 0 || winTier > selectionSize) {
            return 0;
        } else {
            uint256 mask = uint256(type(uint16).max) << (winTier * 16);
            uint256 extracted = (nonJackpotFixedRewards & mask) >> (winTier * 16);
            return extracted * (10 ** (IERC20Metadata(address(rewardToken)).decimals() - 1));
        }
    }

    function finalizeInitialPotRaise() external override {
        if (initialPot > 0) {
            revert JackpotAlreadyInitialized();
        }
        // slither-disable-next-line timestamp
        if (block.timestamp <= initialPotDeadline) {
            revert FinalizingInitialPotBeforeDeadline();
        }
        uint256 raised = rewardToken.balanceOf(address(this));
        if (raised < minInitialPot) {
            revert RaisedInsufficientFunds(raised);
        }
        initialPot = raised;

        // must hold after this call, this will be used as a check that jackpot is initialized
        assert(initialPot > 0);

        emit InitialPotPeriodFinalized(raised);
    }

    function drawScheduledAt(uint128 drawId) public view override returns (uint256 time) {
        time = firstDrawSchedule + (drawId * drawPeriod);
    }

    function ticketRegistrationDeadline(uint128 drawId) public view override returns (uint256 time) {
        time = drawScheduledAt(drawId) - drawCoolDownPeriod;
    }

    function _baseJackpot(uint256 _initialPot) internal view returns (uint256) {
        return Math.min(_initialPot.getPercentage(BASE_JACKPOT_PERCENTAGE), jackpotBound);
    }

    function packFixedRewards(uint256[] memory rewards) private view returns (uint256 packed) {
        if (rewards.length != (selectionSize) || rewards[0] != 0) {
            revert InvalidFixedRewardSetup();
        }
        uint256 divisor = 10 ** (IERC20Metadata(address(rewardToken)).decimals() - 1);
        for (uint8 winTier = 1; winTier < selectionSize; ++winTier) {
            uint16 reward = uint16(rewards[winTier] / divisor);
            if ((rewards[winTier] % divisor) != 0) {
                revert InvalidFixedRewardSetup();
            }
            packed |= uint256(reward) << (winTier * 16);
        }
    }
}
