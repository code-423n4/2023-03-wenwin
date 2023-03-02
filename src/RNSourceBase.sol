// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "src/interfaces/IRNSource.sol";

abstract contract RNSourceBase is IRNSource {
    address internal immutable authorizedConsumer;
    mapping(uint256 => RandomnessRequest) internal requests;

    constructor(address _authorizedConsumer) {
        authorizedConsumer = _authorizedConsumer;
    }

    /// @notice Requests a random number from the underlying source.
    /// @dev Can only be called by the `authorizedConsumer`.
    function requestRandomNumber() external override {
        if (authorizedConsumer != msg.sender) {
            revert UnauthorizedConsumer(msg.sender);
        }

        uint256 requestId = requestRandomnessFromUnderlyingSource();
        if (requests[requestId].status != RequestStatus.None) {
            revert requestIdAlreadyExists(requestId);
        }

        requests[requestId] = RandomnessRequest({ status: RequestStatus.Pending, randomNumber: 0 });

        emit RequestedRandomNumber(msg.sender, requestId);
    }

    /// @dev Must be called in the deriving contract's `requestRandomnessFromUnderlyingSource` function
    function fulfill(uint256 requestId, uint256 randomNumber) internal {
        if (requests[requestId].status == RequestStatus.None) {
            revert RequestNotFound(requestId);
        }
        if (requests[requestId].status == RequestStatus.Fulfilled) {
            revert RequestAlreadyFulfilled(requestId);
        }

        requests[requestId].randomNumber = randomNumber;
        requests[requestId].status = RequestStatus.Fulfilled;
        IRNSourceConsumer(authorizedConsumer).onRandomNumberFulfilled(randomNumber);

        emit RequestFulfilled(requestId, randomNumber);
    }

    function requestRandomnessFromUnderlyingSource() internal virtual returns (uint256 requestId);
}
