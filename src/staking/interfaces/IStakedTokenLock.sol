// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "src/staking/interfaces/IStaking.sol";

/// @dev Thrown when trying to deposit after the deposit period ends.
error DepositPeriodOver();

/// @dev Thrown when trying to withdraw before the lock period ends.
error LockPeriodOngoing();

interface IStakedTokenLock {
    /// @dev Retrieves the staked token which can be locked in the contract.
    function stakedToken() external view returns (IStaking);

    /// @dev Retrieves the token in which rewards are paid (via the staking contract).
    function rewardsToken() external view returns (IERC20);

    /// @dev Retrieves the timestamp after which deposits cannot be made.
    /// After this timestamp, the lock duration starts.
    function depositDeadline() external view returns (uint256);

    /// @dev Retrieves the duration for which funds will be locked.
    function lockDuration() external view returns (uint256);

    /// @dev Retrieves the balance of `stakedToken` which were deposited.
    function depositedBalance() external view returns (uint256);

    /// @dev Deposit tokens to be locked until the end of the locking period (or before the deposit deadline).
    /// @param amount The amount of tokens to deposit
    function deposit(uint256 amount) external;

    /// @dev Withdraw tokens after the end of the locking period or during the deposit period.
    /// @param amount The amount of tokens to withdraw
    function withdraw(uint256 amount) external;

    /// @dev Claims rewards from the staking contract and sends the contract's entire reward token balance
    /// to the contract owner.
    function getReward() external;
}
