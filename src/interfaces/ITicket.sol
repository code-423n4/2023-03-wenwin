// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @dev Interface representing Ticket NTF.
/// Ticket NFT represents ownership of the lottery ticket.
interface ITicket is IERC721 {
    /// @dev Information about the ticket.
    struct TicketInfo {
        /// @dev Unique identifier of the draw ticket was bought for.
        uint128 drawId;
        /// @dev Ticket combination that is packed as uint120.
        uint120 combination;
        /// @dev If ticket is already claimed, in case of winning ticket.
        bool claimed;
    }

    /// @dev Identifier that will be assigned to the next minted token
    /// @return nextId Next identifier to be assigned
    function nextTicketId() external view returns (uint256 nextId);

    /// @dev Retrieves information about a ticket given a `ticketId`.
    /// @param ticketId Unique identifier of the ticket.
    /// @return drawId Unique identifier of the draw ticket was bought for.
    /// @return combination Ticket combination that is packed as uint120.
    /// @return claimed If ticket is already claimed, in case of winning ticket.
    function ticketsInfo(uint256 ticketId) external view returns (uint128 drawId, uint120 combination, bool claimed);
}
