// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity ^0.8.7;

import "src/interfaces/IRNSource.sol";

/// @dev Thrown if a wrong count of random numbers is received
/// @param requestId id of the request for random number
/// @param numbersCount count of random numbers received for the request
error WrongRandomNumberCountReceived(uint256 requestId, uint256 numbersCount);

interface IVRFv2RNSource is IRNSource {
    /// @return gasLimit Maximum amount of gas to be spent for fulfilling the request
    function callbackGasLimit() external returns (uint32 gasLimit);

    /// @return minConfirmations Minimum number of confirmations before request can be fulfilled
    function requestConfirmations() external returns (uint16 minConfirmations);
}
