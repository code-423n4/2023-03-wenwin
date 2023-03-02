// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Hevm } from "./Hevm.sol";
import { ILottery } from "src/interfaces/ILottery.sol";
import { ILotteryToken } from "src/interfaces/ILotteryToken.sol";
import { IStaking, ZeroAmountInput } from "src/staking/interfaces/IStaking.sol";
import { LotteryMath } from "src/LotteryMath.sol";
import { PercentageMath } from "src/PercentageMath.sol";

contract StakingEchidna {
    address internal constant HEVM_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

    ILottery public immutable lottery;
    IERC20 public immutable rewardToken;
    IStaking public immutable stakingContract;
    ILotteryToken public immutable stakingToken;

    uint256 public stakingTotalSupply;
    uint256 public sumOfRewards;

    event Debug(string, uint256);

    constructor(ILottery lottery_, ILotteryToken stakingToken_) {
        lottery = lottery_;
        rewardToken = lottery_.rewardToken();
        stakingContract = IStaking(lottery.stakingRewardRecipient());
        stakingToken = stakingToken_;
    }

    function stake(uint256 amount) external {
        // Pre-condition
        require(stakingToken.balanceOf(msg.sender) > 0, "Balance must be greater than zero");
        if (amount > stakingToken.balanceOf(msg.sender)) {
            amount = stakingToken.balanceOf(msg.sender);
        }

        uint256 lotSenderBalanceBefore = stakingToken.balanceOf(msg.sender);
        uint256 lotStakingContractBalanceBefore = stakingToken.balanceOf(address(stakingContract));
        uint256 stakingSenderBalanceBefore = stakingContract.balanceOf(msg.sender);

        Hevm(HEVM_ADDRESS).prank(msg.sender);
        stakingToken.approve(address(stakingContract), amount);

        // Action
        Hevm(HEVM_ADDRESS).prank(msg.sender);
        try stakingContract.stake(amount) {
            // Post-condition
            uint256 lotSenderBalanceAfter = stakingToken.balanceOf(msg.sender);
            assert(lotSenderBalanceBefore - amount == lotSenderBalanceAfter);
            uint256 lotStakingContractBalanceAfter = stakingToken.balanceOf(address(stakingContract));
            assert(lotStakingContractBalanceBefore + amount == lotStakingContractBalanceAfter);
            uint256 stakingSenderBalanceAfter = stakingContract.balanceOf(msg.sender);
            assert(stakingSenderBalanceBefore + amount == stakingSenderBalanceAfter);
            stakingTotalSupply += amount;
        } catch (bytes memory reason) {
            // Reverts
            bytes32 reasonInBytes32 = keccak256(reason);
            // ZeroAmountInput revert
            if (amount == 0) {
                assert(reasonInBytes32 == keccak256(abi.encodeWithSelector(ZeroAmountInput.selector)));
                return;
            }

            assert(false);
        }
    }

    function withdraw(uint256 amount) external {
        // Pre-condition
        require(stakingContract.balanceOf(msg.sender) > 0, "Balance must be greater than zero");
        if (amount > stakingContract.balanceOf(msg.sender)) {
            amount = stakingContract.balanceOf(msg.sender);
        }

        uint256 stakingSenderBalanceBefore = stakingContract.balanceOf(msg.sender);
        uint256 lotSenderBalanceBefore = stakingToken.balanceOf(msg.sender);
        uint256 lotStakingContractBalanceBefore = stakingToken.balanceOf(address(stakingContract));

        // Action
        Hevm(HEVM_ADDRESS).prank(msg.sender);
        try stakingContract.withdraw(amount) {
            // Post-condition
            withdrawPostCondition(
                stakingSenderBalanceBefore, lotSenderBalanceBefore, lotStakingContractBalanceBefore, amount
            );
        } catch (bytes memory reason) {
            // Reverts
            bytes32 reasonInBytes32 = keccak256(reason);
            // ZeroAmountInput revert
            if (amount == 0) {
                assert(reasonInBytes32 == keccak256(abi.encodeWithSelector(ZeroAmountInput.selector)));
                return;
            }

            assert(false);
        }
    }

    function getReward() external {
        // Pre-conditon
        uint256 rewardTokenSenderBefore = rewardToken.balanceOf(msg.sender);

        // Action
        Hevm(HEVM_ADDRESS).prank(msg.sender);
        try stakingContract.getReward() {
            // Post-condtion
            getRewardPostCondition(rewardTokenSenderBefore);
        } catch (bytes memory) {
            // Reverts
            assert(false);
        }
    }

    function exit() external {
        // Pre-condtion
        uint256 stakingSenderBalanceBefore = stakingContract.balanceOf(msg.sender);
        uint256 lotSenderBalanceBefore = stakingToken.balanceOf(msg.sender);
        uint256 lotStakingContractBalanceBefore = stakingToken.balanceOf(address(stakingContract));
        uint256 rewardTokenSenderBefore = rewardToken.balanceOf(msg.sender);

        // Action
        Hevm(HEVM_ADDRESS).prank(msg.sender);
        try stakingContract.exit() {
            // Post-condtion
            withdrawPostCondition(
                stakingSenderBalanceBefore,
                lotSenderBalanceBefore,
                lotStakingContractBalanceBefore,
                stakingSenderBalanceBefore
            );
            getRewardPostCondition(rewardTokenSenderBefore);
        } catch (bytes memory reason) {
            // Reverts
            bytes32 reasonInBytes32 = keccak256(reason);
            // ZeroAmountInput revert
            if (stakingSenderBalanceBefore == 0) {
                assert(reasonInBytes32 == keccak256(abi.encodeWithSelector(ZeroAmountInput.selector)));
                return;
            }
            assert(false);
        }
    }

    function getMaxRewardAmount() public view returns (uint256 maxRewardAmount) {
        uint256 ticketPrice = lottery.ticketPrice();
        uint256 totalTickets = lottery.nextTicketId();
        maxRewardAmount = (totalTickets * ticketPrice * LotteryMath.STAKING_REWARD) / PercentageMath.PERCENTAGE_BASE;
    }

    function withdrawPostCondition(
        uint256 stakingSenderBalanceBefore,
        uint256 lotSenderBalanceBefore,
        uint256 lotStakingContractBalanceBefore,
        uint256 amount
    )
        private
    {
        uint256 stakingSenderBalanceAfter = stakingContract.balanceOf(msg.sender);
        assert(stakingSenderBalanceBefore - amount == stakingSenderBalanceAfter);
        uint256 lotSenderBalanceAfter = stakingToken.balanceOf(msg.sender);
        assert(lotSenderBalanceBefore + amount == lotSenderBalanceAfter);
        uint256 lotStakingContractBalanceAfter = stakingToken.balanceOf(address(stakingContract));
        assert(lotStakingContractBalanceBefore - amount == lotStakingContractBalanceAfter);
        stakingTotalSupply -= amount;
    }

    function getRewardPostCondition(uint256 rewardTokenSenderBefore) private {
        uint256 rewardTokenSenderAfter = rewardToken.balanceOf(msg.sender);
        assert(rewardTokenSenderAfter - rewardTokenSenderBefore <= getMaxRewardAmount());
        sumOfRewards += rewardTokenSenderAfter - rewardTokenSenderBefore;
    }
}
