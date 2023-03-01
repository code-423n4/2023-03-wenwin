// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

interface IRNSource {
    /// @dev Non existent request, this should never happen as it means the underlying source
    /// reported number for a non-existent request ID
    /// @param requestId id of the request that is being checked
    error RequestNotFound(uint256 requestId);

    /// @dev The generated request ID was used before
    /// @param requestId The duplicate generated request ID
    error RequestAlreadyFulfilled(uint256 requestId);

    /// @dev Consumer is not allowed to request random numbers
    /// @param consumer Address of consumer that tried requesting random number
    error UnauthorizedConsumer(address consumer);

    /// @dev The generated request ID was used before
    /// @param requestId The duplicate generated request ID
    error requestIdAlreadyExists(uint256 requestId);

    /// @dev Emitted when a random number is requested
    /// @param consumer Consumer requested random number
    /// @param requestId identifier of the request
    event RequestedRandomNumber(address indexed consumer, uint256 indexed requestId);

    /// @dev Request is fulfilled
    /// @param requestId identifier of the request being fulfilled
    /// @param randomNumber random number generated
    event RequestFulfilled(uint256 indexed requestId, uint256 indexed randomNumber);

    enum RequestStatus {
        None,
        Pending,
        Fulfilled
    }

    struct RandomnessRequest {
        /// @dev specifies the request status
        RequestStatus status;
        /// @dev Random number generated for particular request
        uint256 randomNumber;
    }

    /// @dev Requests a new random number from the source
    function requestRandomNumber() external;
}

interface IRNSourceConsumer {
    /// @dev After requesting random number from IRNSource
    /// this method will be called by IRNSource to deliver generated number
    /// @param randomNumber Generated random number
    function onRandomNumberFulfilled(uint256 randomNumber) external;
}
