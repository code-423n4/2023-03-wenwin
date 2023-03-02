// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "src/interfaces/IRNSourceController.sol";

contract RNSourceEchidna is IRNSource {
    address private rnSourceController;
    bool public isRequested;

    constructor(address _rnSourceController) {
        rnSourceController = _rnSourceController;
    }

    function requestRandomNumber() external {
        isRequested = true;
    }

    function fulfillRandomNumber(uint256 randomNumber) external {
        require(isRequested, "RNSourceEchidna: not requested");
        if (isRequested) {
            IRNSourceController(rnSourceController).onRandomNumberFulfilled(randomNumber);
        }
        isRequested = false;
    }
}
