require("@nomicfoundation/hardhat-ethers");
require("@nomicfoundation/hardhat-verify");
require('dotenv').config();
// import "@nomicfoundation/hardhat-verify";
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "avax",
  solidity: {
    version: "0.8.24",
    settings: {
      evmVersion: "cancun",
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
    },
  },
  sourcify: {
    enabled: true,
  },
  networks: {
    avax: {
      url: "https://api.avax.network/ext/bc/C/rpc",
      accounts: [process.env.PRIVATE_KEY]
    },
    base: {
      url: 'https://mainnet.base.org',
      // chainId: 8453,
      accounts: [process.env.PRIVATE_KEY],
      // gasPrice: 10000000000,
    },
    bsc: {
      url: "https://bsc-dataseed.bnbchain.org/",
      chainId: 56,
      gasPrice: 20000000000,
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: {
      avalanche: "avalanche", // apiKey is not required, just set a placeholder
      bsc: process.env.BSC_API_KEY
    },
    customChains: [
      {
        network: "avalanche",
        chainId: 43114,
        urls: {
          apiURL: "https://api.routescan.io/v2/network/mainnet/evm/43114/etherscan",
          browserURL: "https://avalanche.routescan.io"
        }
      }
    ]
  },
  paths: {
    sources: "./contracts",
    tests: "./tests",
    cache: "./cache",
    artifacts: "./artifacts",
    scripts: "./scripts",
  },
};
