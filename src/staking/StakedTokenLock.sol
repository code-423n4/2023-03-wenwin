// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "src/staking/interfaces/IStakedTokenLock.sol";
import "src/staking/interfaces/IStaking.sol";

contract StakedTokenLock is IStakedTokenLock, Ownable2Step {
    IStaking public immutable override stakedToken;
    IERC20 public immutable override rewardsToken;
    uint256 public immutable override depositDeadline;
    uint256 public immutable override lockDuration;
    uint256 public override depositedBalance;

    constructor(address _stakedToken, uint256 _depositDeadline, uint256 _lockDuration) {
        _transferOwnership(msg.sender);
        stakedToken = IStaking(_stakedToken);
        rewardsToken = stakedToken.rewardsToken();
        depositDeadline = _depositDeadline;
        lockDuration = _lockDuration;
    }

    function deposit(uint256 amount) external override onlyOwner {
        // slither-disable-next-line timestamp
        if (block.timestamp > depositDeadline) {
            revert DepositPeriodOver();
        }

        depositedBalance += amount;

        // No need for SafeTransferFrom, only trusted staked token is used.
        // slither-disable-next-line unchecked-transfer
        stakedToken.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) external override onlyOwner {
        // slither-disable-next-line timestamp
        if (block.timestamp > depositDeadline && block.timestamp < depositDeadline + lockDuration) {
            revert LockPeriodOngoing();
        }

        depositedBalance -= amount;

        // No need for SafeTransfer, only trusted staked token is used.
        // slither-disable-next-line unchecked-transfer
        stakedToken.transfer(msg.sender, amount);
    }

    function getReward() external override {
        stakedToken.getReward();

        // No need for SafeTransfer, only trusted reward token is used.
        // slither-disable-next-line unchecked-transfer
        rewardsToken.transfer(owner(), rewardsToken.balanceOf(address(this)));
    }
}
