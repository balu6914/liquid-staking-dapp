require("@nomicfoundation/hardhat-ethers");
require("dotenv").config();

module.exports = {
  solidity: "0.8.20",
  networks: {
    amoy: {
      url: process.env.POLYGON_RPC_URL, // The RPC URL for Polygon Amoy Testnet
      accounts: [process.env.PRIVATE_KEY], // Your wallet private key
      chainId: 80002, // Chain ID for Polygon Amoy Testnet
    },
  },
};
