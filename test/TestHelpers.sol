// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/TicketUtils.sol";

library TestHelpers {
    function generateRandomNumberForTicket(
        uint256 ticket,
        uint8 selectionSize,
        uint8 selectionMax
    )
        internal
        pure
        returns (uint256 randomNumber)
    {
        uint8[] memory combination = new uint8[](selectionSize);
        uint256 currentIndex = selectionSize - 1;
        for (uint8 i = 0; i < selectionMax; ++i) {
            if (ticket & (1 << i) != 0) {
                combination[currentIndex] = i;
                if (currentIndex == 0) {
                    break;
                }
                --currentIndex;
            }
        }
        randomNumber = generateRandomNumberForCombination(combination, selectionSize, selectionMax);
    }

    function generateRandomNumberForCombination(
        uint8[] memory combination,
        uint8 selectionSize,
        uint8 selectionMax
    )
        internal
        pure
        returns (uint256 randomNumber)
    {
        require(combination.length == selectionSize, "Combination length is not equal to selection size");
        uint256 multi = 1;
        uint256 currentSelectionCount = selectionMax;
        for (uint8 i = 0; i < combination.length; ++i) {
            require(combination[i] < selectionMax, "Number from combination is out of range");
            if (i > 0) {
                require(combination[i - 1] > combination[i], "Combination is not sorted");
            }
            randomNumber += combination[i] * multi;
            multi *= currentSelectionCount;
            currentSelectionCount--;
        }
        assert(
            generateTicketForCombination(combination, selectionSize, selectionMax)
                == TicketUtils.reconstructTicket(randomNumber, selectionSize, selectionMax)
        );
    }

    function generateTicketForCombination(
        uint8[] memory combination,
        uint8 selectionSize,
        uint8 selectionMax
    )
        internal
        pure
        returns (uint256 ticket)
    {
        require(combination.length == selectionSize, "Combination length is not equal to selection size");
        for (uint8 i = 0; i < combination.length; ++i) {
            require(combination[i] < selectionMax, "Number from combination is out of range");
            if (i > 0) {
                require(combination[i - 1] > combination[i], "Combination is not sorted");
            }
            ticket |= 1 << combination[i];
        }
    }
}
