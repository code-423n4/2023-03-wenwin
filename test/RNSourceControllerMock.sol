// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/RNSourceController.sol";

contract RNSourceControllerMock is RNSourceController {
    // solhint-disable-next-line no-empty-blocks
    constructor() RNSourceController(3, 30 minutes) { }

    function request() public {
        super.requestRandomNumber();
    }

    // solhint-disable-next-line no-empty-blocks
    function receiveRandomNumber(uint256 randomNumber) internal override { }
}
