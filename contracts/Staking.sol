// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract DPNToken is ERC20, Ownable {
    constructor(address initialOwner) ERC20("Decentralized Proof of Network", "DPN") Ownable(initialOwner) {}

    // Only the owner (Staking contract) can call the mint function
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

contract Staking is Ownable, ReentrancyGuard {
    DPNToken public dpnToken;
    mapping(address => uint256) public stakedETH;
    address[] public stakers;

    event Stake(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);

    constructor() Ownable(msg.sender) {
        dpnToken = new DPNToken(address(this));
        dpnToken.transferOwnership(address(this)); // Transfer minting rights to the Staking contract
    }

    function stakeETH() external payable {
        require(msg.value > 0, "Cannot stake 0 ETH");

        if (stakedETH[msg.sender] == 0) {
            stakers.push(msg.sender); // Add the staker if they are staking for the first time.
        }

        stakedETH[msg.sender] += msg.value;
        dpnToken.mint(msg.sender, msg.value); // Mint 1 DPN per 1 staked ETH

        emit Stake(msg.sender, msg.value);
    }

    function distributeRewards(uint256 rewardAmount) external onlyOwner {
        require(address(this).balance >= rewardAmount, "Not enough ETH in contract");
        require(rewardAmount > 0, "Reward amount must be greater than 0");

        uint256 totalStaked = address(this).balance - rewardAmount; // Total ETH staked by users.
        require(totalStaked > 0, "No staked ETH available for rewards");

        // Distribute rewards proportionally to each staker based on their share of total staked ETH.
        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            uint256 stakerShare = (stakedETH[staker] * rewardAmount) / totalStaked;
            stakedETH[staker] += stakerShare;
        }
    }

    function redeemETH(uint256 _amount) external nonReentrant {
        require(stakedETH[msg.sender] >= _amount, "Insufficient balance");
        stakedETH[msg.sender] -= _amount;

        // The user must approve the transfer of DPN to the staking contract
        require(
            dpnToken.transferFrom(msg.sender, address(this), _amount),
            "Transfer of DPN failed. Ensure you have approved the contract."
        );

        payable(msg.sender).transfer(_amount);

        emit Redeem(msg.sender, _amount);
    }
}
