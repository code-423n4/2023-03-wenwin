// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "src/interfaces/IReferralSystem.sol";
import "src/PercentageMath.sol";

abstract contract ReferralSystem is IReferralSystem {
    using PercentageMath for uint256;

    uint256 public immutable override playerRewardFirstDraw;
    uint256 public immutable override playerRewardDecreasePerDraw;

    uint256[] public override rewardsToReferrersPerDraw;

    mapping(uint128 => mapping(address => UnclaimedTicketsData)) public override unclaimedTickets;

    mapping(uint128 => uint256) public override totalTicketsForReferrersPerDraw;

    mapping(uint128 => uint256) public override referrerRewardPerDrawForOneTicket;

    mapping(uint128 => uint256) public override playerRewardsPerDrawForOneTicket;

    mapping(uint128 => uint256) public override minimumEligibleReferrals;

    constructor(
        uint256 _playerRewardFirstDraw,
        uint256 _playerRewardDecreasePerDraw,
        uint256[] memory _rewardsToReferrersPerDraw
    ) {
        if (_rewardsToReferrersPerDraw.length == 0) {
            revert ReferrerRewardsInvalid();
        }
        for (uint256 i = 0; i < _rewardsToReferrersPerDraw.length; ++i) {
            if (_rewardsToReferrersPerDraw[i] == 0) {
                revert ReferrerRewardsInvalid();
            }
        }

        rewardsToReferrersPerDraw = _rewardsToReferrersPerDraw;

        playerRewardFirstDraw = _playerRewardFirstDraw;
        playerRewardDecreasePerDraw = _playerRewardDecreasePerDraw;
    }

    /// @dev Registers tickets for player and referrer (if an address is not zero)
    /// @param currentDraw Currently active draw
    /// @param referrer The address of the referrer
    /// @param player The address of the player
    /// @param numberOfTickets Number of tickets we are registering
    function referralRegisterTickets(
        uint128 currentDraw,
        address referrer,
        address player,
        uint256 numberOfTickets
    )
        internal
    {
        if (referrer != address(0)) {
            uint256 minimumEligible = minimumEligibleReferrals[currentDraw];
            if (unclaimedTickets[currentDraw][referrer].referrerTicketCount + numberOfTickets >= minimumEligible) {
                if (unclaimedTickets[currentDraw][referrer].referrerTicketCount < minimumEligible) {
                    totalTicketsForReferrersPerDraw[currentDraw] +=
                        unclaimedTickets[currentDraw][referrer].referrerTicketCount;
                }
                totalTicketsForReferrersPerDraw[currentDraw] += numberOfTickets;
            }
            unclaimedTickets[currentDraw][referrer].referrerTicketCount += uint128(numberOfTickets);
        }
        unclaimedTickets[currentDraw][player].playerTicketCount += uint128(numberOfTickets);
    }

    function mintNativeTokens(address mintTo, uint256 amount) internal virtual;

    function claimReferralReward(uint128[] memory drawIds) external override returns (uint256 claimedReward) {
        for (uint256 counter = 0; counter < drawIds.length; ++counter) {
            claimedReward += claimPerDraw(drawIds[counter]);
        }

        mintNativeTokens(msg.sender, claimedReward);
    }

    /// @dev Draw is being finalized, does the rewards calculations for the draw
    /// @param drawFinalized Draw being finalized
    /// @param ticketsSoldDuringDraw Number of tickets sold during the draw that is finalized
    function referralDrawFinalize(uint128 drawFinalized, uint256 ticketsSoldDuringDraw) internal {
        // if no tickets sold there is no incentives, so no rewards to be set
        if (ticketsSoldDuringDraw == 0) {
            return;
        }

        minimumEligibleReferrals[drawFinalized + 1] =
            getMinimumEligibleReferralsFactorCalculation(ticketsSoldDuringDraw);

        uint256 referrerRewardForDraw = referrerRewardsPerDraw(drawFinalized);
        uint256 totalTicketsForReferrersPerCurrentDraw = totalTicketsForReferrersPerDraw[drawFinalized];
        if (totalTicketsForReferrersPerCurrentDraw > 0) {
            referrerRewardPerDrawForOneTicket[drawFinalized] =
                referrerRewardForDraw / totalTicketsForReferrersPerCurrentDraw;
        }

        uint256 playerRewardForDraw = playerRewardsPerDraw(drawFinalized);
        if (playerRewardForDraw > 0) {
            playerRewardsPerDrawForOneTicket[drawFinalized] = playerRewardForDraw / ticketsSoldDuringDraw;
        }

        emit CalculatedRewardsForDraw(drawFinalized, referrerRewardForDraw, playerRewardForDraw);
    }

    function getMinimumEligibleReferralsFactorCalculation(uint256 totalTicketsSoldPrevDraw)
        internal
        view
        virtual
        returns (uint256 minimumEligible)
    {
        if (totalTicketsSoldPrevDraw < 10_000) {
            // 1%
            return totalTicketsSoldPrevDraw.getPercentage(PercentageMath.ONE_PERCENT);
        }
        if (totalTicketsSoldPrevDraw < 100_000) {
            // 0.75%
            return totalTicketsSoldPrevDraw.getPercentage(PercentageMath.ONE_PERCENT * 75 / 100);
        }
        if (totalTicketsSoldPrevDraw < 1_000_000) {
            // 0.5%
            return totalTicketsSoldPrevDraw.getPercentage(PercentageMath.ONE_PERCENT * 50 / 100);
        }
        return 5000;
    }

    /// @dev Reverts if draw is not yet finalized
    /// @param drawId Draw identifier we are checking
    function requireFinishedDraw(uint128 drawId) internal view virtual;

    function claimPerDraw(uint128 drawId) private returns (uint256 claimedReward) {
        requireFinishedDraw(drawId);

        UnclaimedTicketsData memory _unclaimedTickets = unclaimedTickets[drawId][msg.sender];
        if (_unclaimedTickets.referrerTicketCount >= minimumEligibleReferrals[drawId]) {
            claimedReward = referrerRewardPerDrawForOneTicket[drawId] * _unclaimedTickets.referrerTicketCount;
            unclaimedTickets[drawId][msg.sender].referrerTicketCount = 0;
        }

        _unclaimedTickets = unclaimedTickets[drawId][msg.sender];
        if (_unclaimedTickets.playerTicketCount > 0) {
            claimedReward += playerRewardsPerDrawForOneTicket[drawId] * _unclaimedTickets.playerTicketCount;
            unclaimedTickets[drawId][msg.sender].playerTicketCount = 0;
        }

        if (claimedReward > 0) {
            emit ClaimedReferralReward(drawId, msg.sender, claimedReward);
        }
    }

    function playerRewardsPerDraw(uint128 drawId) internal view returns (uint256 rewards) {
        uint256 decrease = uint256(drawId) * playerRewardDecreasePerDraw;
        return playerRewardFirstDraw > decrease ? (playerRewardFirstDraw - decrease) : 0;
    }

    function referrerRewardsPerDraw(uint128 drawId) internal view returns (uint256 rewards) {
        return rewardsToReferrersPerDraw[Math.min(rewardsToReferrersPerDraw.length - 1, drawId)];
    }
}
