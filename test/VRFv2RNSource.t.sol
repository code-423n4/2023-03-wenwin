// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/VRFv2RNSource.sol";

contract VRFv2RNSourceTest is Test {
    address public constant AUTHORIZED_CONSUMER = address(192_929_292);
    address public constant LINK_TOKEN = address(432);
    address public constant WRAPPER = address(432_111);
    uint16 public constant CONFIRMATIONS = 3;
    uint32 public constant GAS_LIMIT = 400_000;

    VRFv2RNSource public source;

    function setUp() public {
        source = new VRFv2RNSource(AUTHORIZED_CONSUMER, LINK_TOKEN, WRAPPER, CONFIRMATIONS, GAS_LIMIT);
    }

    function testRawFulfillRandomWords() public {
        uint256 requestId = 23;
        uint256[] memory randomWords = new uint256[](2);

        vm.prank(AUTHORIZED_CONSUMER);
        vm.mockCall(LINK_TOKEN, abi.encodeWithSelector(LinkTokenInterface.transferAndCall.selector), abi.encode(true));
        vm.mockCall(
            WRAPPER,
            abi.encodeWithSelector(VRFV2WrapperInterface.calculateRequestPrice.selector, GAS_LIMIT),
            abi.encode(1000)
        );
        vm.mockCall(
            WRAPPER, abi.encodeWithSelector(VRFV2WrapperInterface.lastRequestId.selector), abi.encode(requestId)
        );
        source.requestRandomNumber();

        vm.prank(WRAPPER);
        vm.expectRevert(abi.encodeWithSelector(WrongRandomNumberCountReceived.selector, requestId, 2));
        source.rawFulfillRandomWords(requestId, randomWords);

        randomWords = new uint256[](1);
        randomWords[0] = 1_234_527_234_309;
        vm.prank(WRAPPER);
        vm.mockCall(
            AUTHORIZED_CONSUMER,
            abi.encodeWithSelector(IRNSourceConsumer.onRandomNumberFulfilled.selector, randomWords[0]),
            abi.encode(0)
        );
        vm.expectCall(
            AUTHORIZED_CONSUMER,
            abi.encodeWithSelector(IRNSourceConsumer.onRandomNumberFulfilled.selector, randomWords[0])
        );
        source.rawFulfillRandomWords(requestId, randomWords);

        vm.prank(WRAPPER);
        vm.expectRevert(abi.encodeWithSelector(IRNSource.RequestAlreadyFulfilled.selector, requestId));
        source.rawFulfillRandomWords(requestId, randomWords);
    }
}
