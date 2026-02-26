import hre from "hardhat";

async function main() {
  const { ethers } = await hre.network.connect();
  const [deployer] = await ethers.getSigners();
  
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log(`\n📊 Deployer: ${deployer.address}`);
  console.log(`💰 Balance: ${ethers.formatEther(balance)} AVAX\n`);
  
  if (balance < ethers.parseEther("1")) {
    console.log("⚠️  Low balance! Get testnet AVAX from:");
    console.log("   https://faucet.avax.network/");
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });