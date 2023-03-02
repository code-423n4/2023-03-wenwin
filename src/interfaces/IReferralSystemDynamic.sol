// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

/// @dev The number for a minimum ticket sold is greater than the number for a maximum ticket sold for the same index
error MinimumTicketsSoldNotGreaterThanPrevious();

/// @dev The number for a maximum ticket sold for the last index is not uint256 maximum
error MinimumTicketsSoldAtFirstIndexNotZero();

/// @dev List of different factor type
/// @param PERCENT The factor will be a percentage of the total sold tickets for the previous draw
/// @param FIXED The factor will be fixed amount
enum ReferralRequirementFactorType {
    PERCENT,
    FIXED
}

/// @dev The struct that is setup for a minimum eligible referrals calculation
/// @param minimumTicketsSold The number for a minimum tickets sold
/// @param factor A constant that represents a percentage of the previous draw` total ticket sold if @param factorType
///                 is PERCENT or fixed amount if @param factorType is FIXED
/// @param factorType Different factor types - PERCENT and FIXED
struct MinimumReferralsRequirement {
    uint256 minimumTicketsSold;
    uint256 factor;
    ReferralRequirementFactorType factorType;
}

interface IReferralSystemDynamic {
    /// @dev Referral requirement needed for minimum eligible referrals factor calculation
    function referralRequirements(uint256 index)
        external
        view
        returns (uint256 referralRequirements, uint256 factor, ReferralRequirementFactorType factorType);
}
