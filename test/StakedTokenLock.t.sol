// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/staking/StakedTokenLock.sol";
import "./TestToken.sol";

contract TestStakedTokenLock is Test {
    address public constant OWNER = address(12);
    address public constant USER = address(123_456_789);
    StakedTokenLock public stakedTokenLock;
    uint256 public constant DEPOSIT_DEADLINE = 423_423_423;
    uint256 public constant LOCK_DURATION = 365 days;

    TestToken public stakedToken;
    TestToken public rewardsToken;

    function setUp() public {
        vm.startPrank(OWNER);

        stakedToken = new TestToken();
        rewardsToken = new TestToken();
        vm.mockCall(
            address(stakedToken), abi.encodeWithSelector(IStaking.rewardsToken.selector), abi.encode(rewardsToken)
        );
        stakedTokenLock = new StakedTokenLock(
            address(stakedToken),
            DEPOSIT_DEADLINE,
            LOCK_DURATION
        );
        vm.stopPrank();
    }

    function testDepositOwnerOnly() public {
        vm.prank(USER);
        vm.expectRevert("Ownable: caller is not the owner");
        stakedTokenLock.deposit(2);

        vm.startPrank(OWNER);
        stakedToken.mint(2);
        stakedToken.approve(address(stakedTokenLock), 2);
        stakedTokenLock.deposit(2);
    }

    function testWithdrawOwnerOnly() public {
        vm.prank(USER);
        vm.expectRevert("Ownable: caller is not the owner");
        stakedTokenLock.withdraw(2);

        vm.startPrank(OWNER);
        stakedToken.mint(2);
        stakedToken.approve(address(stakedTokenLock), 2);
        stakedTokenLock.deposit(2);
        stakedTokenLock.withdraw(2);
    }

    function testDepositAfterDeadline() public {
        vm.startPrank(OWNER);
        stakedToken.mint(2);
        stakedToken.approve(address(stakedTokenLock), 2);
        vm.expectRevert(DepositPeriodOver.selector);
        vm.warp(DEPOSIT_DEADLINE + 1);
        stakedTokenLock.deposit(2);
    }

    function testWithdrawBeforeDeadline() public {
        vm.startPrank(OWNER);
        stakedToken.mint(2);
        stakedToken.approve(address(stakedTokenLock), 2);
        stakedTokenLock.deposit(2);

        vm.warp(DEPOSIT_DEADLINE);
        stakedTokenLock.withdraw(2);
    }

    function testWithdrawAfterDeadlineBeforeDurationEnd() public {
        vm.startPrank(OWNER);
        stakedToken.mint(2);
        stakedToken.approve(address(stakedTokenLock), 2);
        stakedTokenLock.deposit(2);

        vm.warp(DEPOSIT_DEADLINE + LOCK_DURATION - 1);
        vm.expectRevert(LockPeriodOngoing.selector);
        stakedTokenLock.withdraw(2);
    }

    function testWithdrawAfterDeadlineAfterDurationEnd() public {
        vm.startPrank(OWNER);
        stakedToken.mint(2);
        stakedToken.approve(address(stakedTokenLock), 2);
        stakedTokenLock.deposit(2);

        vm.warp(DEPOSIT_DEADLINE + LOCK_DURATION);
        stakedTokenLock.withdraw(2);
    }

    function testGetRewardSendsEntireBalanceToOwner() public {
        uint256 amount = 123;
        vm.startPrank(USER);
        vm.mockCall(address(stakedToken), abi.encodeWithSelector(IStaking.getReward.selector), abi.encode(0));

        rewardsToken.mint(amount);
        rewardsToken.transfer(address(stakedTokenLock), amount);
        uint256 preBalance = rewardsToken.balanceOf(address(OWNER));
        stakedTokenLock.getReward();
        assertEq(rewardsToken.balanceOf(address(OWNER)) - preBalance, amount);
    }

    function testDepositPullsStakedTokens() public {
        uint256 amount = 123;
        vm.startPrank(OWNER);
        stakedToken.mint(amount);
        stakedToken.approve(address(stakedTokenLock), amount);
        uint256 preBalance = stakedToken.balanceOf(address(OWNER));
        stakedTokenLock.deposit(amount);
        assertEq(preBalance - stakedToken.balanceOf(address(OWNER)), amount);
    }

    function testWithdrawSendsStakedTokens() public {
        uint256 amount = 123;
        vm.startPrank(OWNER);
        stakedToken.mint(amount);
        stakedToken.approve(address(stakedTokenLock), amount);
        stakedTokenLock.deposit(amount);
        uint256 preBalance = stakedToken.balanceOf(address(OWNER));
        stakedTokenLock.withdraw(amount);
        assertEq(stakedToken.balanceOf(address(OWNER)) - preBalance, amount);
    }
}
