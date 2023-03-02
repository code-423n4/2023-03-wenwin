// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
import "src/interfaces/IVRFv2RNSource.sol";
import "src/RNSourceBase.sol";

contract VRFv2RNSource is IVRFv2RNSource, RNSourceBase, VRFV2WrapperConsumerBase {
    uint16 public immutable override requestConfirmations;
    uint32 public immutable override callbackGasLimit;

    constructor(
        address _authorizedConsumer,
        address _linkAddress,
        address _wrapperAddress,
        uint16 _requestConfirmations,
        uint32 _callbackGasLimit
    )
        RNSourceBase(_authorizedConsumer)
        VRFV2WrapperConsumerBase(_linkAddress, _wrapperAddress)
    {
        requestConfirmations = _requestConfirmations;
        callbackGasLimit = _callbackGasLimit;
    }

    /// @dev Assumes the contract is funded sufficiently
    function requestRandomnessFromUnderlyingSource() internal override returns (uint256 requestId) {
        requestId = requestRandomness(callbackGasLimit, requestConfirmations, 1);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        if (randomWords.length != 1) {
            revert WrongRandomNumberCountReceived(requestId, randomWords.length);
        }

        fulfill(requestId, randomWords[0]);
    }
}
