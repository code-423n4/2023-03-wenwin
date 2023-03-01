// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./LotteryTestBase.sol";

abstract contract ReferralSystemBase is LotteryTestBase {
    address public immutable user;

    IReferralSystem internal referralSystem;

    constructor() {
        user = makeAddr("user");
    }

    function setUp() public override {
        super.setUp();
        referralSystem = lottery;
    }

    function testAddTicket() public {
        uint128 unclaimedPlayerCount;
        uint128 unclaimedReferrerCount;
        uint128 currentDraw = lottery.currentDraw();

        // Buy tickets for the drawId = 0
        vm.startPrank(user);

        buySameTickets(currentDraw, uint120(0x0F), address(0), 1);
        (, unclaimedPlayerCount) = referralSystem.unclaimedTickets(currentDraw, user);
        assertEq(unclaimedPlayerCount, 1);

        address randomReferrer = makeAddr("randomReferrer");

        buySameTickets(currentDraw, uint120(0x1E), address(randomReferrer), 1);

        (, unclaimedPlayerCount) = referralSystem.unclaimedTickets(currentDraw, user);
        assertEq(unclaimedPlayerCount, 2);
        (unclaimedReferrerCount,) = referralSystem.unclaimedTickets(currentDraw, randomReferrer);
        assertEq(unclaimedReferrerCount, 1);
        assertEq(referralSystem.totalTicketsForReferrersPerDraw(currentDraw), 1);

        buySameTickets(currentDraw, uint120(0x0F), address(0), 4);
        (, unclaimedPlayerCount) = referralSystem.unclaimedTickets(currentDraw, user);
        assertEq(unclaimedPlayerCount, 6);
        (unclaimedReferrerCount,) = referralSystem.unclaimedTickets(currentDraw, randomReferrer);
        assertEq(unclaimedReferrerCount, 1);
        assertEq(referralSystem.totalTicketsForReferrersPerDraw(currentDraw), 1);

        buySameTickets(currentDraw, uint120(0x0F), randomReferrer, 594);
        (, unclaimedPlayerCount) = referralSystem.unclaimedTickets(currentDraw, user);
        assertEq(unclaimedPlayerCount, 600);
        (unclaimedReferrerCount,) = referralSystem.unclaimedTickets(currentDraw, randomReferrer);
        assertEq(unclaimedReferrerCount, 595);
        assertEq(referralSystem.totalTicketsForReferrersPerDraw(currentDraw), 595);
        vm.stopPrank();

        executeDraw();
        currentDraw = lottery.currentDraw();

        vm.startPrank(user);

        // Buy tickets when there are sold tickets in the previous draw
        buySameTickets(currentDraw, uint120(0x1E), randomReferrer, 1);
        (, unclaimedPlayerCount) = referralSystem.unclaimedTickets(currentDraw, user);
        assertEq(unclaimedPlayerCount, 1);
        (unclaimedReferrerCount,) = referralSystem.unclaimedTickets(currentDraw, randomReferrer);
        assertEq(unclaimedReferrerCount, 1);
        assertEq(referralSystem.totalTicketsForReferrersPerDraw(currentDraw), 0);

        buySameTickets(currentDraw, uint120(0x0F), randomReferrer, 4);
        (, unclaimedPlayerCount) = referralSystem.unclaimedTickets(currentDraw, user);
        assertEq(unclaimedPlayerCount, 5);
        (unclaimedReferrerCount,) = referralSystem.unclaimedTickets(currentDraw, randomReferrer);
        assertEq(unclaimedReferrerCount, 5);
        assertEq(referralSystem.totalTicketsForReferrersPerDraw(currentDraw), 0);

        buySameTickets(currentDraw, uint120(0x1E), address(randomReferrer), 1);
        (, unclaimedPlayerCount) = referralSystem.unclaimedTickets(currentDraw, user);
        assertEq(unclaimedPlayerCount, 6);
        (unclaimedReferrerCount,) = referralSystem.unclaimedTickets(currentDraw, randomReferrer);
        assertEq(unclaimedReferrerCount, 6);
        assertEq(referralSystem.totalTicketsForReferrersPerDraw(currentDraw), 6);
        vm.stopPrank();

        executeDraw();
        currentDraw = lottery.currentDraw();

        executeDraw();
        currentDraw = lottery.currentDraw();

        // Buy tickets when there are not sold tickets in the previous draw
        vm.startPrank(user);
        buySameTickets(currentDraw, uint120(0x0F), randomReferrer, 1);
        (, unclaimedPlayerCount) = referralSystem.unclaimedTickets(currentDraw, user);
        assertEq(unclaimedPlayerCount, 1);
        (unclaimedReferrerCount,) = referralSystem.unclaimedTickets(currentDraw, randomReferrer);
        assertEq(unclaimedReferrerCount, 1);
        assertEq(referralSystem.totalTicketsForReferrersPerDraw(currentDraw), 1);
        vm.stopPrank();

        buySameTickets(currentDraw, uint120(0x0F), randomReferrer, 100_000);

        executeDraw();
        currentDraw = lottery.currentDraw();

        // Buy tickets when is FIXED factor type
        vm.startPrank(user);
        buySameTickets(currentDraw, uint120(0x0F), randomReferrer, 1);
        (, unclaimedPlayerCount) = referralSystem.unclaimedTickets(currentDraw, user);
        assertEq(unclaimedPlayerCount, 1);
        (unclaimedReferrerCount,) = referralSystem.unclaimedTickets(currentDraw, randomReferrer);
        assertEq(unclaimedReferrerCount, 1);
        assertEq(referralSystem.totalTicketsForReferrersPerDraw(currentDraw), 0);

        buySameTickets(currentDraw, uint120(0x0F), randomReferrer, 498);
        (, unclaimedPlayerCount) = referralSystem.unclaimedTickets(currentDraw, user);
        assertEq(unclaimedPlayerCount, 499);
        (unclaimedReferrerCount,) = referralSystem.unclaimedTickets(currentDraw, randomReferrer);
        assertEq(unclaimedReferrerCount, 499);
        assertEq(referralSystem.totalTicketsForReferrersPerDraw(currentDraw), 0);

        buySameTickets(currentDraw, uint120(0x0F), randomReferrer, 1);
        (, unclaimedPlayerCount) = referralSystem.unclaimedTickets(currentDraw, user);
        assertEq(unclaimedPlayerCount, 500);
        (unclaimedReferrerCount,) = referralSystem.unclaimedTickets(currentDraw, randomReferrer);
        assertEq(unclaimedReferrerCount, 500);
        assertEq(referralSystem.totalTicketsForReferrersPerDraw(currentDraw), 500);
        vm.stopPrank();
    }

    function testClaimReferrer() public {
        address randomReferrer = makeAddr("randomReferrer");
        uint128 currentDraw = lottery.currentDraw();

        vm.startPrank(user);
        buySameTickets(currentDraw, uint120(0x0F), address(randomReferrer), 1);
        vm.stopPrank();

        executeDraw();

        uint128[] memory drawIds = new uint128[](1);
        drawIds[0] = 0;
        vm.prank(randomReferrer);
        referralSystem.claimReferralReward(drawIds);

        assertEq(lotteryToken.balanceOf(randomReferrer), rewardsToReferrersPerDraw[0]);
    }

    function testClaimReferrerMultipleDraws() public {
        address randomReferrer = makeAddr("randomReferrer");
        uint128 currentDraw = lottery.currentDraw();

        vm.startPrank(user);
        buySameTickets(currentDraw, uint120(0x0F), address(randomReferrer), 1);
        vm.stopPrank();

        executeDraw();

        currentDraw = lottery.currentDraw();

        vm.startPrank(user);
        buySameTickets(currentDraw, uint120(0x0F), address(randomReferrer), 1);
        vm.stopPrank();

        executeDraw();

        uint128[] memory drawIds = new uint128[](2);
        drawIds[0] = 0;
        drawIds[1] = 1;
        vm.prank(randomReferrer);
        referralSystem.claimReferralReward(drawIds);

        assertEq(lotteryToken.balanceOf(randomReferrer), rewardsToReferrersPerDraw[0] + rewardsToReferrersPerDraw[1]);
    }

    function testCannotClaimReferrer() public {
        address randomReferrer = makeAddr("randomReferrer");
        uint128 currentDraw = lottery.currentDraw();

        uint128[] memory drawIds = new uint128[](1);
        drawIds[0] = currentDraw;
        vm.prank(randomReferrer);
        vm.expectRevert(abi.encodeWithSelector(DrawNotFinished.selector, currentDraw));
        referralSystem.claimReferralReward(drawIds);
    }

    function testClaimPlayer() public {
        uint128 currentDraw = lottery.currentDraw();

        vm.startPrank(user);
        buySameTickets(currentDraw, uint120(0x0F), address(0), 1);
        vm.stopPrank();

        executeDraw();

        uint128[] memory drawIds = new uint128[](1);
        drawIds[0] = 0;
        vm.prank(user);
        referralSystem.claimReferralReward(drawIds);

        assertEq(lotteryToken.balanceOf(user), rewardsToReferrersPerDraw[0]);
    }

    function testClaimPlayerMultipleDraws() public {
        uint128 currentDraw = lottery.currentDraw();

        vm.startPrank(user);
        buySameTickets(currentDraw, uint120(0x0F), address(0), 1);
        vm.stopPrank();

        executeDraw();

        currentDraw = lottery.currentDraw();

        vm.startPrank(user);
        buySameTickets(currentDraw, uint120(0x0F), address(0), 1);
        vm.stopPrank();

        executeDraw();

        uint128[] memory drawIds = new uint128[](2);
        drawIds[0] = 0;
        drawIds[1] = 1;
        vm.prank(user);
        referralSystem.claimReferralReward(drawIds);

        assertEq(lotteryToken.balanceOf(user), rewardsToReferrersPerDraw[0] + rewardsToReferrersPerDraw[1]);
    }

    function testCannotClaimPlayer() public {
        uint128 currentDraw = lottery.currentDraw();

        uint128[] memory drawIds = new uint128[](1);
        drawIds[0] = currentDraw;
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(DrawNotFinished.selector, currentDraw));
        referralSystem.claimReferralReward(drawIds);
        vm.stopPrank();
    }

    function executeDraw() private {
        vm.warp(block.timestamp + 60 * 60 * 24);
        lottery.executeDraw();
        uint256 randomNumber = 0x00000000;

        vm.prank(randomNumberSource);
        lottery.onRandomNumberFulfilled(randomNumber);
    }
}
