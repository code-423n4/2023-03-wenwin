// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "src/interfaces/ILottery.sol";

/// @dev Thrown when a zero amount is provided as input.
error ZeroAmountInput();

/// @dev Thrown when a zero address is provided as input.
error ZeroAddressInput();

interface IStaking is IERC20 {
    /// @dev Stakes the stakeToken. Caller must pre-approve the staking contract.
    /// @param amount Amount of tokens to be staked
    function stake(uint256 amount) external;

    /// @dev Withdraws staked tokens.
    /// @param amount Amount of tokens to be withdrawn
    function withdraw(uint256 amount) external;

    /// @dev Claims accrued rewards.
    function getReward() external;

    /// @dev Withdraws the entire staked balance and claims accrued rewards.
    function exit() external;

    /// @dev Caches the latest rewardPerToken index at which rewards were paid.
    function rewardPerTokenStored() external view returns (uint256);

    /// @dev Keeps track of the latest ticket ID at the time of the last rewardPerToken index update.
    function lastUpdateTicketId() external view returns (uint256);

    /// @dev Caches the latest rewardPerToken index at which a given `account`'s pending rewards update was made.
    function userRewardPerTokenPaid(address account) external view returns (uint256);

    /// @dev Caches the amount of pending rewards for a given `account`, expressed in `rewardsToken`.
    function rewards(address account) external view returns (uint256);

    /// @return _lottery Lottery the contract is dependent on
    function lottery() external view returns (ILottery _lottery);

    /// @return _rewardPerToken Global tracker of rewards per staked token
    function rewardPerToken() external view returns (uint256 _rewardPerToken);

    /// @dev Retrieves the amount of unclaimed rewards of an account.
    /// @param account Address of the account to check its earnings
    /// @return _earned Earned rewards of the account
    function earned(address account) external view returns (uint256 _earned);

    /// @dev Retrieves the token in which staking rewards are paid.
    function rewardsToken() external view returns (IERC20);

    /// @dev Retrieves the token that is being staked in order to get rewards.
    function stakingToken() external view returns (IERC20);

    /// @dev Emitted when a user stakes tokens.
    /// @param user Address of the staking user
    /// @param amount Amount of tokens staked
    event Staked(address indexed user, uint256 indexed amount);

    /// @dev Emitted when a user withdraws staked tokens.
    /// @param user Address of the withdrawing user
    /// @param amount Amount of tokens withdrawn
    event Withdrawn(address indexed user, uint256 indexed amount);

    /// @dev Emitted when a user claims their rewards.
    /// @param user Address of the user claiming rewards
    /// @param reward Amount of rewards claimed
    event RewardPaid(address indexed user, uint256 indexed reward);
}
