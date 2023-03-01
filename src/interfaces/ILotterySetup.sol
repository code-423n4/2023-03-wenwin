// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "src/interfaces/ITicket.sol";

/// @dev Provided reward token is zero
error RewardTokenZero();

/// @dev Provided draw cooldown period >= drawPeriod
error DrawPeriodInvalidSetup();

/// @dev Provided initial pot deadline set to be in past
error InitialPotPeriodTooShort();

/// @dev Provided ticket price is zero
error TicketPriceZero();

/// @dev Provided selection size iz zero
error SelectionSizeZero();

/// @dev Provided selection size max is too big
error SelectionSizeMaxTooBig();

/// @dev Provided selection size is too big
error SelectionSizeTooBig();

/// @dev Provided expected payout is too low or too big
error InvalidExpectedPayout();

/// @dev Invalid fixed rewards setup was provided
error InvalidFixedRewardSetup();

/// @dev Trying to finalize initial pot raise before the deadline
error FinalizingInitialPotBeforeDeadline();

/// @dev Raised insufficient funds for the initial pot
/// @param potSize size of the pot raised
error RaisedInsufficientFunds(uint256 potSize);

/// @dev Jackpot is not yet initialized, it means we are still in initial pot raise timeframe
error JackpotNotInitialized();

/// @dev Trying to initialize already initialized jackpot
error JackpotAlreadyInitialized();

/// @dev Cannot buy tickets for this draw anymore as it is in cooldown mode
/// @param drawId Draw identifier that is in cooldown mode
error TicketRegistrationClosed(uint128 drawId);

/// @dev Lottery draw schedule parameters
struct LotteryDrawSchedule {
    /// @dev First draw is scheduled to take place at this timestamp
    uint256 firstDrawScheduledAt;
    /// @dev Period for running lottery
    uint256 drawPeriod;
    /// @dev Cooldown period when users cannot register tickets for draw anymore
    uint256 drawCoolDownPeriod;
}

/// @dev Parameters used to setup a new lottery
struct LotterySetupParams {
    /// @dev Token to be used as reward token for the lottery
    IERC20 token;
    /// @dev Parameters of the draw schedule for the lottery
    LotteryDrawSchedule drawSchedule;
    /// @dev Price to pay for playing single game (including fee)
    uint256 ticketPrice;
    /// @dev Count of numbers user picks for the ticket
    uint8 selectionSize;
    /// @dev Max number user can pick
    uint8 selectionMax;
    /// @dev Expected payout for one ticket, expressed in `rewardToken`
    uint256 expectedPayout;
    /// @dev Array of fixed rewards per each non jackpot win
    uint256[] fixedRewards;
}

interface ILotterySetup {
    /// @dev Triggered when new Lottery is deployed
    /// @param token Token to be used as reward token for the lottery
    /// @param drawSchedule Parameters of the draw schedule for the lottery
    /// @param ticketPrice Price to pay for playing single game (including fee)
    /// @param selectionSize Count of numbers user picks for the ticket
    /// @param selectionMax Max number user can pick
    /// @param expectedPayout Expected payout for one ticket, expressed in `rewardToken`
    /// @param fixedRewards List of fixed non jackpot rewards
    event LotteryDeployed(
        IERC20 token,
        LotteryDrawSchedule indexed drawSchedule,
        uint256 ticketPrice,
        uint8 indexed selectionSize,
        uint8 indexed selectionMax,
        uint256 expectedPayout,
        uint256[] fixedRewards
    );

    /// @dev Triggered when the initial pot raise period is over
    /// @param amountRaised Total amount raised during this period
    event InitialPotPeriodFinalized(uint256 indexed amountRaised);

    /// @return minPot Minimum amount to be raised in initial funding period
    function minInitialPot() external view returns (uint256 minPot);

    /// @return bound Maximum base jackpot
    function jackpotBound() external view returns (uint256 bound);

    /// @dev Token to be used as reward token for the lottery
    /// It is used for both rewards and paying for tickets
    /// @return token Reward token address
    function rewardToken() external view returns (IERC20 token);

    /// @return token Native token of the lottery. Used for staking and for referral rewards.
    function nativeToken() external view returns (IERC20 token);

    /// @dev Price to pay for playing single game of lottery
    /// User pays it when registering the ticket for the game
    /// It is expressed in `rewardToken`
    /// @return price Price per ticket
    function ticketPrice() external view returns (uint256 price);

    /// @param winTier Tier of the win (selectionSize for jackpot)
    /// @return amount Fixed reward for particular win tier
    function fixedReward(uint8 winTier) external view returns (uint256 amount);

    /// @return potSize The size of the pot after initial pot period is over
    function initialPot() external view returns (uint256 potSize);

    /// @dev When registering ticket, user selects total of `selectionSize` numbers
    /// @return size Count of numbers user picks for the ticket
    function selectionSize() external view returns (uint8 size);

    /// @dev When registering ticket, user selects total of `selectionSize` numbers
    /// These numbers must be in range [1, `selectionMax`]
    /// @return max Max number user can pick
    function selectionMax() external view returns (uint8 max);

    /// @return payout Expected payout for one ticket in reward token
    function expectedPayout() external view returns (uint256 payout);

    /// @return period Period between 2 draws
    function drawPeriod() external view returns (uint256 period);

    /// @return topUpEndsAt Timestamp when initial pot raising is finished
    function initialPotDeadline() external view returns (uint256 topUpEndsAt);

    /// @return period Cooldown period, just before draw is scheduled, at this time tickets cannot be registered
    function drawCoolDownPeriod() external view returns (uint256 period);

    /// @dev Checks for the scheduled time for particular draw
    /// @param drawId Draw identifier we check schedule for
    /// @return time Timestamp after which draw can be executed
    function drawScheduledAt(uint128 drawId) external view returns (uint256 time);

    /// @dev Checks for the last time at which tickets can be bought
    /// @param drawId Draw identifier we check deadline for
    /// @return time Timestamp after which tickets can not be bought
    function ticketRegistrationDeadline(uint128 drawId) external view returns (uint256 time);

    /// @dev Finalize the initial pot raising and initialize jackpot
    function finalizeInitialPotRaise() external;
}
