// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "src/interfaces/ITicket.sol";

/// @dev Ticket ownership is represented as NFT. Whoever owns NFT is the owner of particular ticket in Lottery.
/// If it represents a winning ticket, it can be used to claim a reward from Lottery.
/// Ticket can change ownership before or after ticket has been claimed.
/// Since mint is internal, only derived contracts can mint tickets.
abstract contract Ticket is ITicket, ERC721 {
    uint256 public override nextTicketId;
    mapping(uint256 => ITicket.TicketInfo) public override ticketsInfo;

    // solhint-disable-next-line no-empty-blocks
    constructor() ERC721("Wenwin Lottery Ticket", "WLT") { }

    function markAsClaimed(uint256 ticketId) internal {
        ticketsInfo[ticketId].claimed = true;
    }

    function mint(address to, uint128 drawId, uint120 combination) internal returns (uint256 ticketId) {
        ticketId = nextTicketId++;
        ticketsInfo[ticketId] = TicketInfo(drawId, combination, false);
        _mint(to, ticketId);
    }
}
