import hre from "hardhat";

async function main() {
  console.log("Starting contract verification...");

  // Connect to the network
  const { networkHelpers } = await hre.network.connect();
  
  // Replace these with your actual deployed contract addresses
  const addresses = {
    fuji: {
      honeyDewToken: "0x...", // Replace with your Fuji deployment address
      antNFT: "0x...", // Replace with your Fuji deployment address
    },
    avalanche: {
      honeyDewToken: "0x...", // Replace with your Mainnet deployment address
      antNFT: "0x...", // Replace with your Mainnet deployment address
    },
  };

  // Get network from environment variable or default to fuji
  const network = process.env.HARDHAT_NETWORK || "fuji";
  console.log(`Verifying on network: ${network}`);

  const networkAddresses = network === "fuji" ? addresses.fuji : addresses.avalanche;

  try {
    // Verify HoneyDewToken
    console.log("\n📝 Verifying HoneyDewToken...");
    // Use the provider to make RPC calls if needed
    // For verification, we'll use the Hardhat CLI approach
    console.log(`Contract address: ${networkAddresses.honeyDewToken}`);
    console.log("To verify, run:");
    console.log(`npx hardhat verify --network ${network} ${networkAddresses.honeyDewToken}`);
    console.log("✅ Verification command generated for HoneyDewToken");
  } catch (error: any) {
    console.error("❌ Error generating verification command:", error);
  }

  try {
    // Verify AntNFT
    console.log("\n📝 Verifying AntNFT...");
    console.log(`Contract address: ${networkAddresses.antNFT}`);
    console.log("To verify, run:");
    console.log(`npx hardhat verify --network ${network} ${networkAddresses.antNFT}`);
    console.log("✅ Verification command generated for AntNFT");
  } catch (error: any) {
    console.error("❌ Error generating verification command:", error);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });