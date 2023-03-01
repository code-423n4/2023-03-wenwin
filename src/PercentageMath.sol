// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

/// @dev Implementation of percentage math.
library PercentageMath {
    /// @dev percentage base we use for 100%.
    uint256 public constant PERCENTAGE_BASE = 100_000;

    /// @dev percentage number representing 1%.
    uint256 public constant ONE_PERCENT = 1000;

    /// @dev Calculates percentage of the number.
    /// @param number Input to calculate percentage for.
    /// @param percentage Percentage to calculate in `PERCENTAGE_BASE` precision.
    /// @return result Resulting number representing `percentage` of `number`.
    function getPercentage(uint256 number, uint256 percentage) internal pure returns (uint256 result) {
        return number * percentage / PERCENTAGE_BASE;
    }

    /// @dev Calculates percentage of signed number. See `getPercentage`.
    function getPercentageInt(int256 number, uint256 percentage) internal pure returns (int256 result) {
        return number * int256(percentage) / int256(PERCENTAGE_BASE);
    }
}
