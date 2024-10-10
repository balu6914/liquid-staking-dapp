// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";



contract LiquidToken is ERC20, Ownable {
    constructor(address initialOwner) ERC20("Liquid Staking Token", "LST") Ownable(initialOwner) {}

    // Only the owner (Staking contract) can call the mint function
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

contract Staking is Ownable, ReentrancyGuard {
    LiquidToken public liquidToken;
    mapping(address => uint256) public stakedETH;

    event Stake(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);

    constructor() Ownable(msg.sender) {
        liquidToken = new LiquidToken(address(this));
        liquidToken.transferOwnership(address(this)); // Transfer minting rights to the Staking contract
    }

    function stakeETH() external payable {
        require(msg.value > 0, "Cannot stake 0 ETH");
        stakedETH[msg.sender] += msg.value;
        liquidToken.mint(msg.sender, msg.value); // Mint 1 LST per 1 staked ETH

        emit Stake(msg.sender, msg.value);
    }

    function redeemETH(uint256 _amount) external nonReentrant {
        require(stakedETH[msg.sender] >= _amount, "Insufficient balance");
        stakedETH[msg.sender] -= _amount;

        // The user must approve the transfer of LST to the staking contract
        require(
            liquidToken.transferFrom(msg.sender, address(this), _amount),
            "Transfer of LST failed. Ensure you have approved the contract."
        );

        payable(msg.sender).transfer(_amount);

        emit Redeem(msg.sender, _amount);
    }
}
