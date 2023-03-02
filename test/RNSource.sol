// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "src/interfaces/IRNSource.sol";
import "src/interfaces/ILottery.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RNSource is IRNSource {
    error MockReverted();

    address internal authorizedConsumer;
    RequestRandomNumberMockMode public mode;

    enum RequestRandomNumberMockMode {
        Success,
        Revert,
        Require
    }

    constructor(address _authorizedConsumer) {
        authorizedConsumer = _authorizedConsumer;
    }

    function setMockMode(RequestRandomNumberMockMode _mode) external {
        mode = _mode;
    }

    function requestRandomNumber() external view {
        if (mode == RequestRandomNumberMockMode.Revert) {
            revert MockReverted();
        } else if (mode == RequestRandomNumberMockMode.Require) {
            require(false, "mockFailed");
        }
    }

    function fulfillRandomNumber(uint256 randomNumber) external {
        IRNSourceConsumer(authorizedConsumer).onRandomNumberFulfilled(randomNumber);
    }
}
