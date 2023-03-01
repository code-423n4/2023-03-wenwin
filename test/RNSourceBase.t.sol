// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/VRFv2RNSource.sol";
import "src/RNSourceBase.sol";
import "src/interfaces/IRNSource.sol";

interface IRNSourceBaseHarness {
    function requestRandomnessFromUnderlyingSourceMock() external returns (uint256 requestId);
}

/// @dev exposing internal methods from RNSourceBase since it's abstract
contract RNSourceBaseHarness is IRNSourceBaseHarness, RNSourceBase {
    // solhint-disable-next-line no-empty-blocks
    constructor(address _authorizedConsumer) RNSourceBase(_authorizedConsumer) { }

    function fulfillHarness(uint256 requestId, uint256 randomNumber) external {
        fulfill(requestId, randomNumber);
    }

    function requestsHarness(uint256 requestId) external view returns (RandomnessRequest memory) {
        return requests[requestId];
    }

    // solhint-disable-next-line no-empty-blocks
    function requestRandomnessFromUnderlyingSourceMock() external pure override returns (uint256 requestId) { }

    function requestRandomnessFromUnderlyingSource() internal view override returns (uint256 requestId) {
        requestId = this.requestRandomnessFromUnderlyingSourceMock();
    }
}

contract RNSourceBaseTest is Test {
    address public constant AUTHORIZED_CONSUMER = address(12_345_123_123_123);

    RNSourceBaseHarness public sourceBaseHarness;

    function setUp() public {
        sourceBaseHarness = new RNSourceBaseHarness(AUTHORIZED_CONSUMER);
    }

    function testRequestRandomNumbers() public {
        vm.prank(address(111));
        vm.expectRevert(abi.encodeWithSelector(IRNSource.UnauthorizedConsumer.selector, address(111)));
        sourceBaseHarness.requestRandomNumber();

        vm.prank(AUTHORIZED_CONSUMER);
        vm.mockCall(
            address(sourceBaseHarness),
            abi.encodeWithSelector(IRNSourceBaseHarness.requestRandomnessFromUnderlyingSourceMock.selector),
            abi.encode(1)
        );
        sourceBaseHarness.requestRandomNumber();
        IRNSource.RandomnessRequest memory request = sourceBaseHarness.requestsHarness(1);
        assertEq(uint256(request.status), uint256(IRNSource.RequestStatus.Pending));
        assertEq(request.randomNumber, 0);
    }

    function testFulfillRandomNumber() public {
        uint256 randomNumber = 21;
        uint256 requestId = 78;

        vm.prank(AUTHORIZED_CONSUMER);
        vm.mockCall(
            address(sourceBaseHarness),
            abi.encodeWithSelector(IRNSourceBaseHarness.requestRandomnessFromUnderlyingSourceMock.selector),
            abi.encode(requestId)
        );
        sourceBaseHarness.requestRandomNumber();
        vm.mockCall(
            AUTHORIZED_CONSUMER,
            abi.encodeWithSelector(IRNSourceConsumer.onRandomNumberFulfilled.selector, randomNumber),
            abi.encode(0)
        );
        sourceBaseHarness.fulfillHarness(requestId, randomNumber);

        IRNSource.RandomnessRequest memory request = sourceBaseHarness.requestsHarness(requestId);
        assertEq(uint256(request.status), uint256(IRNSource.RequestStatus.Fulfilled));
        assertEq(request.randomNumber, randomNumber);
    }
}
