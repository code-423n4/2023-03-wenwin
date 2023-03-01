// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "src/interfaces/IRNSource.sol";

contract RNSourceConsumerMock is IRNSourceConsumer {
    event RNFulfilled(address indexed rnSource, uint256 randomNumber);

    function requestRandomNumber(address rnSource) external {
        IRNSource(rnSource).requestRandomNumber();
    }

    function onRandomNumberFulfilled(uint256 randomNumber) external override {
        emit RNFulfilled(msg.sender, randomNumber);
    }
}
