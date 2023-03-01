// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "forge-std/Test.sol";
import "../src/LotteryToken.sol";

contract LotteryTokenTest is Test {
    address public constant OWNER = address(0x111);
    uint256 public constant FIRST_YEAR_INFLATION_PER_DRAW = 1000e18;
    uint256 public constant SECOND_YEAR_INFLATION_PER_DRAW = 500e18;
    uint256 public constant THIRD_YEAR_INFLATION_PER_DRAW = 250e18;

    LotteryToken public lotteryToken;

    address public constant MINT_TO = address(0x123);

    function setUp() public {
        vm.prank(OWNER);
        lotteryToken = new LotteryToken();
    }

    function testInflation(uint256 amount) public {
        amount = bound(amount, 1, 1e30);

        uint256 initialSupply = lotteryToken.INITIAL_SUPPLY();
        assertEq(lotteryToken.totalSupply(), initialSupply);

        vm.prank(OWNER);
        lotteryToken.mint(MINT_TO, amount);

        assertEq(lotteryToken.totalSupply(), initialSupply + amount);
        assertEq(lotteryToken.balanceOf(MINT_TO), (lotteryToken.totalSupply() - initialSupply));
    }

    function testUnauthorizedMinting() public {
        vm.prank(address(0x222));
        vm.expectRevert(UnauthorizedMint.selector);
        lotteryToken.mint(MINT_TO, 1);
    }
}
