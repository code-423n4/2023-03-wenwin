// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "src/LotteryToken.sol";
import "src/ReferralSystem.sol";

contract ReferralSystemConfig is Script {
    uint256 internal constant INITIAL_TOKEN_SUPPLY = 1_000_000_000e18;

    function getLotteryRewardsData()
        internal
        pure
        returns (
            uint256 playerRewardFirstDraw,
            uint256 playerRewardDecrease,
            uint256[] memory rewardsToReferrersPerDraw
        )
    {
        playerRewardFirstDraw = 961_538.5e18;
        playerRewardDecrease = 9335.3e18;

        rewardsToReferrersPerDraw = new uint256[](105);
        rewardsToReferrersPerDraw[0] = 700_000e18;
        rewardsToReferrersPerDraw[52] = 500_000e18;
        rewardsToReferrersPerDraw[104] = 300_000e18;
        for (uint256 i = 1; i < 104; i++) {
            if (i % 52 != 0) {
                rewardsToReferrersPerDraw[i] = rewardsToReferrersPerDraw[i - 1];
            }
        }
    }
}
