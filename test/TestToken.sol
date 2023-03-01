// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "src/interfaces/ILottery.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    // solhint-disable-next-line no-empty-blocks
    constructor() ERC20("Test Token", "RWT") { }

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}
