// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "src/RNSourceController.sol";
import "src/VRFv2RNSource.sol";
import "test/RNSource.sol";

contract RNSourceConfig is Script {
    function getRNSource(address authorizedConsumer) internal returns (IRNSource rnSource) {
        address vrfWrapper = vm.envAddress("VRFv2_WRAPPER_ADDRESS");
        address linkToken = vm.envAddress("VRFv2_LINK_TOKEN_ADDRESS");

        if (vrfWrapper == address(0) || linkToken == address(0)) {
            rnSource = new RNSource(authorizedConsumer);
        } else {
            uint16 maxAttempts = uint16(vm.envUint("VRFv2_MAX_ATTEMPTS"));
            uint32 gasLimit = uint32(vm.envUint("VRFv2_GAS_LIMIT"));
            rnSource = new VRFv2RNSource(
                authorizedConsumer,
                linkToken,
                vrfWrapper,
                maxAttempts,
                gasLimit
            );
        }
    }
}
