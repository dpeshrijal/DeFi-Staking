//SPDX-License-Identifier:MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.4;

error Staking__TransferFailed();
error Staking__NotEnoughToken();

contract Staking {
    IERC20 public s_stakingToken;
    IERC20 public s_rewardToken;

    mapping(address => uint256) public s_balances;
    mapping(address => uint256) public s_rewards;
    mapping(address => uint256) public s_userRewardPerTokenPaid;

    uint256 public constant REWARD_RATE = 100;
    uint256 public s_totalSupply;
    uint256 public s_rewardPerTokenStored;
    uint256 public s_lastUpdatedTime;

    constructor(address _stakingToken, address _rewardToken) {
        s_stakingToken = IERC20(_stakingToken);
        s_rewardToken = IERC20(_rewardToken);
    }

    function staking(uint256 _amount) external updateReward(msg.sender) {
        s_balances[msg.sender] += _amount;
        s_totalSupply += _amount;

        bool success = s_stakingToken.transferFrom(
            msg.sender,
            address(this),
            _amount
        );

        if (!success) {
            revert Staking__TransferFailed();
        }
    }

    function withdraw(uint256 _amount) external updateReward(msg.sender) {
        if (s_balances[msg.sender] < _amount) {
            revert Staking__NotEnoughToken();
        }

        s_balances[msg.sender] -= _amount;
        s_totalSupply -= _amount;

        bool success = s_stakingToken.transfer(msg.sender, _amount);
        if (!success) {
            revert Staking__TransferFailed();
        }
    }

    function claimReward() external updateReward(msg.sender) {
        uint rewards = s_rewards[msg.sender];
        s_rewards[msg.sender] = 0;
        s_rewardToken.transfer(msg.sender, rewards);
    }

    modifier updateReward(address account) {
        s_rewardPerTokenStored = rewardPerToken();
        s_lastUpdatedTime = block.timestamp;
        s_rewards[account] = earned(account);
        s_userRewardPerTokenPaid[account] = s_rewardPerTokenStored;
        _;
    }

    function rewardPerToken() public view returns (uint256) {
        if (s_totalSupply == 0) {
            return 0;
        }

        return
            s_rewardPerTokenStored +
            (((block.timestamp - s_lastUpdatedTime) * REWARD_RATE * 1e18) /
                s_totalSupply);
    }

    function earned(address account) public view returns (uint256) {
        return
            ((s_balances[account] *
                (rewardPerToken() - s_userRewardPerTokenPaid[account])) /
                1e18) + s_rewards[account];
    }
}
