// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./LotteryTestBase.sol";
import "../src/Lottery.sol";
import "./TestToken.sol";
import "./RNSource.sol";

contract LotteryInvariantChecksTest is LotteryTestBase {
    function invariantSufficientFunds() public view {
        uint256 contractBalance = lottery.rewardToken().balanceOf(address(lottery));
        assert(contractBalance > 0);
    }

    function testBuyClaimFinalize(uint256[] memory tickets, address[] memory users, uint256 randomNumber) public {
        vm.assume(tickets.length > 0);
        vm.assume(users.length > 0);

        buyRandomTickets(tickets, users);
        claimRewards();

        finalizeDraw(randomNumber);
    }

    function buyRandomTickets(uint256[] memory tickets, address[] memory users) internal {
        for (uint256 i = 0; i < tickets.length; ++i) {
            address userAddress =
                address(uint160(bound(uint256(uint160(users[i % users.length])), 1, uint256(type(uint160).max))));
            vm.startPrank(userAddress);
            rewardToken.mint(TICKET_PRICE);
            rewardToken.approve(address(lottery), TICKET_PRICE);
            buyTicket(
                lottery.currentDraw(),
                TicketUtils.reconstructTicket(tickets[i], SELECTION_SIZE, SELECTION_MAX),
                address(0)
            );
            vm.stopPrank();
        }
    }

    function unclaimedRewards() internal returns (uint256 totalUnclaimed) {
        totalUnclaimed = lottery.unclaimedRewards(LotteryRewardType.STAKING);
        vm.prank(FRONTEND_ADDRESS);
        totalUnclaimed += lottery.unclaimedRewards(LotteryRewardType.FRONTEND);
    }

    function claimRewards() internal {
        lottery.claimRewards(LotteryRewardType.STAKING);
        vm.prank(FRONTEND_ADDRESS);
        lottery.claimRewards(LotteryRewardType.FRONTEND);
        assertEq(unclaimedRewards(), 0);
    }
}
