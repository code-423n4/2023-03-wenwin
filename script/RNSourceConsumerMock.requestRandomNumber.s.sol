// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "test/RNSourceConsumerMock.sol";

contract RNSourceConsumerMockRequestRandomNumberScript is Script {
    // solhint-disable-next-line no-empty-blocks
    function setUp() public { }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        RNSourceConsumerMock rnSourceConsumer = RNSourceConsumerMock(vm.envAddress("RNSOURCE_CONSUMER_ADDRESS"));
        address rnSource = vm.envAddress("RNSOURCE_ADDRESS");
        vm.broadcast(deployerPrivateKey);
        rnSourceConsumer.requestRandomNumber(rnSource);
        vm.stopBroadcast();
    }
}
