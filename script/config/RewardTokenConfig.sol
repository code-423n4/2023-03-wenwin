// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "test/TestToken.sol";

contract RewardTokenConfig is Script {
    function getRewardToken() internal returns (IERC20 token) {
        address rewardTokenAddress = vm.envAddress("REWARD_TOKEN_ADDRESS");
        if (rewardTokenAddress == address(0)) {
            token = new TestToken();
        } else {
            token = IERC20(rewardTokenAddress);
        }
    }
}
