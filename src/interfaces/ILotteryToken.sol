// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Caller is not allowed to mint tokens.
error UnauthorizedMint();

/// @dev Interface for the Lottery token.
interface ILotteryToken is IERC20 {
    /// @dev Initial supply minted at the token deployment.
    function INITIAL_SUPPLY() external view returns (uint256 initialSupply);

    /// @return _owner The owner of the contract
    function owner() external view returns (address _owner);

    /// @dev Mints number of tokens for particular draw and assigns them to `account`, increasing the total supply.
    /// Mint is done for the `nextDrawToBeMintedFor`
    /// @param account The recipient of tokens
    /// @param amount Number of tokens to be minted
    function mint(address account, uint256 amount) external;
}
