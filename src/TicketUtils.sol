// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

/// @dev Helper library used for ticket utilities
/// Ticket is represented as uint120 packed ticket:
/// If `x`th bit of ticket is set, it means ticket contains number x + 1
library TicketUtils {
    /// @dev Checks if ticket is valid
    /// In order to be a valid ticket, it must:
    ///    - Have exactly `selectionSize` bits set to `1`
    ///    - Each bit after bit `selectionMax` must be set to `0`
    /// @param ticket Ticked represented as packed uint120
    /// @param selectionSize Selection size of the lottery
    /// @param selectionMax Selection max number for the lottery
    /// @return isValid Is ticked valid
    function isValidTicket(
        uint256 ticket,
        uint8 selectionSize,
        uint8 selectionMax
    )
        internal
        pure
        returns (bool isValid)
    {
        unchecked {
            uint256 ticketSize;
            for (uint8 i = 0; i < selectionMax; ++i) {
                ticketSize += (ticket & uint256(1));
                ticket >>= 1;
            }
            return (ticketSize == selectionSize) && (ticket == uint256(0));
        }
    }

    /// @dev Reconstructs ticket from random number. Each number is selected from appropriate 8 bits from random number.
    /// In each iteration, we calculate the modulo of a random number and then shift it for 8 bits to the right.
    /// The modulo is used to select one number from the numbers that are not already selected.
    /// @param randomNumber Random number used to reconstruct ticket
    /// @param selectionSize Selection size of the lottery
    /// @param selectionMax Selection max number for the lottery
    /// @return ticket Resulting ticket, packed as uint120
    function reconstructTicket(
        uint256 randomNumber,
        uint8 selectionSize,
        uint8 selectionMax
    )
        internal
        pure
        returns (uint120 ticket)
    {
        /// Ticket must contain unique numbers, so we are using smaller selection count in each iteration
        /// It basically means that, once `x` numbers are selected our choice is smaller for `x` numbers
        uint8[] memory numbers = new uint8[](selectionSize);
        uint256 currentSelectionCount = uint256(selectionMax);

        for (uint256 i = 0; i < selectionSize; ++i) {
            numbers[i] = uint8(randomNumber % currentSelectionCount);
            randomNumber /= currentSelectionCount;
            currentSelectionCount--;
        }

        bool[] memory selected = new bool[](selectionMax);

        for (uint256 i = 0; i < selectionSize; ++i) {
            uint8 currentNumber = numbers[i];
            // check current selection for numbers smaller than current and increase if needed
            for (uint256 j = 0; j <= currentNumber; ++j) {
                if (selected[j]) {
                    currentNumber++;
                }
            }
            selected[currentNumber] = true;
            ticket |= ((uint120(1) << currentNumber));
        }
    }

    /// @dev Checks how many hits particular ticket has compared to winning ticket combination.
    /// @param ticket Ticket we are checking hits for
    /// @param winningTicket Winning ticket for the draw
    /// @param selectionSize Selection size for lottery
    /// @param selectionMax Selection max for the lottery
    function ticketWinTier(
        uint120 ticket,
        uint120 winningTicket,
        uint8 selectionSize,
        uint8 selectionMax
    )
        internal
        pure
        returns (uint8 winTier)
    {
        unchecked {
            uint120 intersection = ticket & winningTicket;
            for (uint8 i = 0; i < selectionMax; ++i) {
                winTier += uint8(intersection & uint120(1));
                intersection >>= 1;
            }
            assert((winTier <= selectionSize) && (intersection == uint256(0)));
        }
    }
}
