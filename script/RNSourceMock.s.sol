// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "test/RNSource.sol";

contract RNSourceMockScript is Script {
    // solhint-disable-next-line no-empty-blocks
    function setUp() public { }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address authorizedConsumer = vm.envAddress("SOURCE_AUTHORIZED_CONSUMER_ADDRESS");
        vm.broadcast(deployerPrivateKey);

        new RNSource(authorizedConsumer);

        vm.stopBroadcast();
    }
}
