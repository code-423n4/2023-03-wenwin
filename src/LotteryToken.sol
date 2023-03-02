// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "src/interfaces/ILotteryToken.sol";
import "src/LotteryMath.sol";

/// @dev Lottery token contract. The token has a fixed initial supply.
/// Additional tokens can be minted after each draw is finalized. Inflation rates (per draw) are defined for each year.
contract LotteryToken is ILotteryToken, ERC20 {
    uint256 public constant override INITIAL_SUPPLY = 1_000_000_000e18;

    address public immutable override owner;

    /// @dev Initializes lottery token with `INITIAL_SUPPLY` pre-minted tokens
    constructor() ERC20("Wenwin Lottery", "LOT") {
        owner = msg.sender;
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function mint(address account, uint256 amount) external override {
        if (msg.sender != owner) {
            revert UnauthorizedMint();
        }
        _mint(account, amount);
    }
}
