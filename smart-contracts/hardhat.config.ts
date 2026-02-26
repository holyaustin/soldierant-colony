import hardhatToolboxMochaEthersPlugin from "@nomicfoundation/hardhat-toolbox-mocha-ethers";
import { configVariable, defineConfig } from "hardhat/config";
//import "@nomicfoundation/hardhat-toolbox";
import hardhatEthers from "@nomicfoundation/hardhat-ethers";
import hardhatTypechain from "@nomicfoundation/hardhat-typechain";
import hardhatMocha from "@nomicfoundation/hardhat-mocha";
import hardhatEthersChaiMatchers from "@nomicfoundation/hardhat-ethers-chai-matchers";
import hardhatNetworkHelpers from "@nomicfoundation/hardhat-network-helpers";
import hardhatVerify from "@nomicfoundation/hardhat-verify";
import * as dotenv from "dotenv";

dotenv.config();

const AVALANCHE_FUJI_RPC = process.env.AVALANCHE_FUJI_RPC || "https://api.avax-test.network/ext/bc/C/rpc";
const AVALANCHE_MAINNET_RPC = process.env.AVALANCHE_MAINNET_RPC || "https://api.avax.network/ext/bc/C/rpc";
const PRIVATE_KEY = process.env.PRIVATE_KEY || "";
const SNOWTRACE_API_KEY = process.env.SNOWTRACE_API_KEY || "";

export default defineConfig({
  plugins: [
    hardhatVerify,
    hardhatToolboxMochaEthersPlugin,
    hardhatEthers,
    hardhatTypechain,
    hardhatMocha,
    hardhatEthersChaiMatchers,
    hardhatNetworkHelpers,
  ],
  solidity: {
    profiles: {
      default: {
        version: "0.8.30",
      },
      production: {
        version: "0.8.30",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
          viaIR: true,  // Add this line - critical for stack too deep errors
        },
      },
    },
  },
  networks: {
    hardhatMainnet: {
      type: "edr-simulated",
      chainType: "l1",
    },
    hardhatOp: {
      type: "edr-simulated",
      chainType: "op",
    },
    sepolia: {
      type: "http",
      chainType: "l1",
      url: configVariable("SEPOLIA_RPC_URL"),
      accounts: [configVariable("SEPOLIA_PRIVATE_KEY")],
    },
    fuji: {
      type: "http",
      chainType: "l1",
      url: process.env.AVALANCHE_FUJI_RPC || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 43113,
    },
    avalanche: {
      type: "http",
      chainType: "l1",
      url: process.env.AVALANCHE_MAINNET_RPC || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 43114,
      gasPrice: 25000000000,
    }
  },
  verify: {
    etherscan: {
      apiKey: SNOWTRACE_API_KEY,
    },
    blockscout: {
       enabled: false, // Disable Blockscout for Avalanche
    },
  },

    chainDescriptors: {
    43113: {
      name: "Avalanche Fuji Testnet",
      blockExplorers: {
        etherscan: {
          name: "Snowtrace",
          url: "https://testnet.snowtrace.io",
          apiUrl: "https://api-testnet.snowtrace.io/api",
        },
      },
    },
    43114: {
      name: "Avalanche Mainnet",
      blockExplorers: {
        etherscan: {
          name: "Snowtrace",
          url: "https://snowtrace.io",
          apiUrl: "https://api.snowtrace.io/api",
        },
      },
    },
  },
  
});
