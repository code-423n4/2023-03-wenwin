// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "src/TicketUtils.sol";
import "test/TestHelpers.sol";

contract TicketTest is Test {
    uint8 public constant SELECTION_SIZE = 4;
    uint8 public constant SELECTION_MAX = 10;

    function testReconstructTicket() public {
        assertEq(TicketUtils.reconstructTicket(0, 4, 10), 0x0F);
        assertEq(
            TicketUtils.reconstructTicket(
                TestHelpers.generateRandomNumberForTicket(0x0F, SELECTION_SIZE, SELECTION_MAX),
                SELECTION_SIZE,
                SELECTION_MAX
            ),
            0x0F
        );
        assertEq(
            TicketUtils.reconstructTicket(
                TestHelpers.generateRandomNumberForTicket(0x1E, SELECTION_SIZE, SELECTION_MAX),
                SELECTION_SIZE,
                SELECTION_MAX
            ),
            0x1E
        );
    }

    function testRandomNumberReconstruct(uint256 randomNumber) public {
        uint256 ticket = TicketUtils.reconstructTicket(randomNumber, SELECTION_SIZE, SELECTION_MAX);
        assertTrue(TicketUtils.isValidTicket(ticket, SELECTION_SIZE, SELECTION_MAX));
    }

    function testTicketWinTier(
        uint256 ticketRandomNumber,
        uint256 winningTicketRandomNumber,
        uint8 _selectionSize,
        uint8 _selectionMax
    )
        public
    {
        _selectionMax = uint8(bound(_selectionMax, 2, 120));
        _selectionSize = uint8(bound(_selectionSize, 1, _selectionMax - 1));
        uint120 ticket = TicketUtils.reconstructTicket(ticketRandomNumber, _selectionSize, _selectionMax);
        uint120 winning = TicketUtils.reconstructTicket(winningTicketRandomNumber, _selectionSize, _selectionMax);
        assertLe(TicketUtils.ticketWinTier(ticket, winning, _selectionSize, _selectionMax), _selectionSize);
    }
}
