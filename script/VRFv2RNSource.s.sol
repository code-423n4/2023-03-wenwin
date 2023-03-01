// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "script/config/RNSourceConfig.sol";
import "src/VRFv2RNSource.sol";

contract VRFv2RNSourceScript is Script, RNSourceConfig {
    // solhint-disable-next-line no-empty-blocks
    function setUp() public { }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address authorizedConsumer = vm.envAddress("SOURCE_AUTHORIZED_CONSUMER_ADDRESS");

        vm.broadcast(deployerPrivateKey);
        getRNSource(authorizedConsumer);
        vm.stopBroadcast();
    }
}
