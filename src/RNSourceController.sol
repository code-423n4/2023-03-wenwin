// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "src/interfaces/IRNSource.sol";
import "src/interfaces/IRNSourceController.sol";

/// @dev A contract that controls the list of random number sources and dispatches random number requests to them.
abstract contract RNSourceController is Ownable2Step, IRNSourceController {
    IRNSource public override source;

    uint256 public override failedSequentialAttempts;
    uint256 public override maxFailedAttemptsReachedAt;
    uint256 public override lastRequestTimestamp;
    bool public override lastRequestFulfilled = true;
    uint256 public immutable override maxFailedAttempts;
    uint256 public immutable override maxRequestDelay;
    uint256 private constant MAX_MAX_FAILED_ATTEMPTS = 10;
    uint256 private constant MAX_REQUEST_DELAY = 5 hours;

    /// @dev Constructs a new random number source controller.
    /// @param _maxFailedAttempts The maximum number of sequential failed attempts to use a random number source before
    /// it is removed from the list of sources
    /// @param _maxRequestDelay The maximum delay between random number request and its fulfillment
    constructor(uint256 _maxFailedAttempts, uint256 _maxRequestDelay) {
        if (_maxFailedAttempts > MAX_MAX_FAILED_ATTEMPTS) {
            revert MaxFailedAttemptsTooBig();
        }
        if (_maxRequestDelay > MAX_REQUEST_DELAY) {
            revert MaxRequestDelayTooBig();
        }
        maxFailedAttempts = _maxFailedAttempts;
        maxRequestDelay = _maxRequestDelay;
    }

    /// @dev Requests a random number from the current random number source.
    function requestRandomNumber() internal {
        if (!lastRequestFulfilled) {
            revert PreviousRequestNotFulfilled();
        }

        requestRandomNumberFromSource();
    }

    function onRandomNumberFulfilled(uint256 randomNumber) external override {
        if (msg.sender != address(source)) {
            revert RandomNumberFulfillmentUnauthorized();
        }

        lastRequestFulfilled = true;
        failedSequentialAttempts = 0;
        maxFailedAttemptsReachedAt = 0;

        receiveRandomNumber(randomNumber);
    }

    function receiveRandomNumber(uint256 randomNumber) internal virtual;

    function retry() external override {
        if (lastRequestFulfilled) {
            revert CannotRetrySuccessfulRequest();
        }
        if (block.timestamp - lastRequestTimestamp <= maxRequestDelay) {
            revert CurrentRequestStillActive();
        }

        uint256 failedAttempts = ++failedSequentialAttempts;
        if (failedAttempts == maxFailedAttempts) {
            maxFailedAttemptsReachedAt = block.timestamp;
        }

        emit Retry(source, failedSequentialAttempts);
        requestRandomNumberFromSource();
    }

    function initSource(IRNSource rnSource) external override onlyOwner {
        if (address(rnSource) == address(0)) {
            revert RNSourceZeroAddress();
        }
        if (address(source) != address(0)) {
            revert AlreadyInitialized();
        }

        source = rnSource;
        emit SourceSet(rnSource);
    }

    function swapSource(IRNSource newSource) external override onlyOwner {
        if (address(newSource) == address(0)) {
            revert RNSourceZeroAddress();
        }
        bool notEnoughRetryInvocations = failedSequentialAttempts < maxFailedAttempts;
        bool notEnoughTimeReachingMaxFailedAttempts = block.timestamp < maxFailedAttemptsReachedAt + maxRequestDelay;
        if (notEnoughRetryInvocations || notEnoughTimeReachingMaxFailedAttempts) {
            revert NotEnoughFailedAttempts();
        }
        source = newSource;
        failedSequentialAttempts = 0;
        maxFailedAttemptsReachedAt = 0;

        emit SourceSet(newSource);
        requestRandomNumberFromSource();
    }

    function requestRandomNumberFromSource() private {
        lastRequestTimestamp = block.timestamp;
        lastRequestFulfilled = false;

        // slither-disable-start uninitialized-local
        // See Slither issue: https://github.com/crytic/slither/issues/511
        try source.requestRandomNumber() {
            emit SuccessfulRNRequest(source);
        } catch Error(string memory reason) {
            emit FailedRNRequest(source, bytes(reason));
        } catch (bytes memory reason) {
            emit FailedRNRequest(source, reason);
        }
        // slither-disable-end uninitialized-local
    }
}
