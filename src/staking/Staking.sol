// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "src/interfaces/ILottery.sol";
import "src/LotteryMath.sol";
import "src/staking/interfaces/IStaking.sol";

contract Staking is IStaking, ERC20 {
    using SafeERC20 for IERC20;

    ILottery public immutable override lottery;
    IERC20 public immutable override rewardsToken;
    IERC20 public immutable override stakingToken;
    uint256 public override rewardPerTokenStored;
    uint256 public override lastUpdateTicketId;
    mapping(address => uint256) public override userRewardPerTokenPaid;
    mapping(address => uint256) public override rewards;

    constructor(
        ILottery _lottery,
        IERC20 _rewardsToken,
        IERC20 _stakingToken,
        string memory name,
        string memory symbol
    )
        ERC20(name, symbol)
    {
        if (address(_lottery) == address(0)) {
            revert ZeroAddressInput();
        }
        if (address(_rewardsToken) == address(0)) {
            revert ZeroAddressInput();
        }
        if (address(_stakingToken) == address(0)) {
            revert ZeroAddressInput();
        }

        lottery = _lottery;
        rewardsToken = _rewardsToken;
        stakingToken = _stakingToken;
    }

    /* ========== VIEWS ========== */

    function rewardPerToken() public view override returns (uint256 _rewardPerToken) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }

        uint256 ticketsSoldSinceUpdate = lottery.nextTicketId() - lastUpdateTicketId;
        uint256 unclaimedRewards =
            LotteryMath.calculateRewards(lottery.ticketPrice(), ticketsSoldSinceUpdate, LotteryRewardType.STAKING);

        return rewardPerTokenStored + (unclaimedRewards * 1e18 / _totalSupply);
    }

    function earned(address account) public view override returns (uint256 _earned) {
        return balanceOf(account) * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18 + rewards[account];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external override {
        // _updateReward is not needed here as it's handled by _beforeTokenTransfer
        if (amount == 0) {
            revert ZeroAmountInput();
        }

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override {
        // _updateReward is not needed here as it's handled by _beforeTokenTransfer
        if (amount == 0) {
            revert ZeroAmountInput();
        }

        _burn(msg.sender, amount);
        stakingToken.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public override {
        _updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            // slither-disable-next-line unused-return
            lottery.claimRewards(LotteryRewardType.STAKING);
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external override {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function _beforeTokenTransfer(address from, address to, uint256) internal override {
        if (from != address(0)) {
            _updateReward(from);
        }

        if (to != address(0)) {
            _updateReward(to);
        }
    }

    function _updateReward(address account) internal {
        uint256 currentRewardPerToken = rewardPerToken();
        rewardPerTokenStored = currentRewardPerToken;
        lastUpdateTicketId = lottery.nextTicketId();
        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = currentRewardPerToken;
    }
}
