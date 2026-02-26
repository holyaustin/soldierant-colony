import hre from "hardhat";

async function main() {
  const { ethers } = await hre.network.connect();
  const [deployer] = await ethers.getSigners();
  
  console.log(`\n📊 Deployer: ${deployer.address}`);
  console.log(`💰 Balance: ${ethers.formatEther(await ethers.provider.getBalance(deployer.address))} AVAX\n`);

  // Step 1: Deploy HoneyDewToken
  console.log("📝 Step 1: Deploying HoneyDewToken...");
  const HoneyDewToken = await ethers.getContractFactory("HoneyDewToken");
  const token = await HoneyDewToken.deploy();
  await token.waitForDeployment();
  const tokenAddress = await token.getAddress();
  console.log(`   ✅ HoneyDewToken deployed to: ${tokenAddress}`);
  console.log(`   Gas used: ${(await ethers.provider.getTransactionReceipt(token.deploymentTransaction()!.hash))!.gasUsed}`);

  // Step 2: Deploy AntNFT
  console.log("\n📝 Step 2: Deploying AntNFT...");
  const AntNFT = await ethers.getContractFactory("AntNFT");
  const antNFT = await AntNFT.deploy();
  await antNFT.waitForDeployment();
  const antNFTAddress = await antNFT.getAddress();
  console.log(`   ✅ AntNFT deployed to: ${antNFTAddress}`);

  // Step 3: Deploy ColonyManager
  console.log("\n📝 Step 3: Deploying ColonyManager...");
  const ColonyManager = await ethers.getContractFactory("ColonyManager");
  const colonyManager = await ColonyManager.deploy(
    antNFTAddress,
    tokenAddress,
    "0x0000000000000000000000000000000000000000",
    "0x0000000000000000000000000000000000000000"
  );
  await colonyManager.waitForDeployment();
  const colonyManagerAddress = await colonyManager.getAddress();
  console.log(`   ✅ ColonyManager deployed to: ${colonyManagerAddress}`);

  // Step 4: Deploy TerritoryStaking
  console.log("\n📝 Step 4: Deploying TerritoryStaking...");
  const TerritoryStaking = await ethers.getContractFactory("TerritoryStaking");
  const territoryStaking = await TerritoryStaking.deploy(
    antNFTAddress,
    colonyManagerAddress
  );
  await territoryStaking.waitForDeployment();
  const territoryStakingAddress = await territoryStaking.getAddress();
  console.log(`   ✅ TerritoryStaking deployed to: ${territoryStakingAddress}`);

  // Step 5: Deploy TournamentSystem
  console.log("\n📝 Step 5: Deploying TournamentSystem...");
  const TournamentSystem = await ethers.getContractFactory("TournamentSystem");
  const tournamentSystem = await TournamentSystem.deploy(
    antNFTAddress,
    tokenAddress,
    colonyManagerAddress
  );
  await tournamentSystem.waitForDeployment();
  const tournamentSystemAddress = await tournamentSystem.getAddress();
  console.log(`   ✅ TournamentSystem deployed to: ${tournamentSystemAddress}`);

  // Step 6: Set up contract relationships
  console.log("\n📝 Step 6: Setting up contract relationships...");
  
  // Set addresses in ColonyManager
  await colonyManager.setTerritoryStaking(territoryStakingAddress);
  console.log("   ✅ ColonyManager.territoryStaking set");
  
  await colonyManager.setTournamentSystem(tournamentSystemAddress);
  console.log("   ✅ ColonyManager.tournamentSystem set");
  
  // Set addresses in AntNFT
  await antNFT.setColonyManager(colonyManagerAddress);
  console.log("   ✅ AntNFT.colonyManager set");
  
  await antNFT.setTournamentSystem(tournamentSystemAddress);
  console.log("   ✅ AntNFT.tournamentSystem set");

  console.log("\n✅ All contracts deployed successfully!");
  console.log("\n📋 Deployment Summary:");
  console.log(`   HoneyDewToken: ${tokenAddress}`);
  console.log(`   AntNFT: ${antNFTAddress}`);
  console.log(`   ColonyManager: ${colonyManagerAddress}`);
  console.log(`   TerritoryStaking: ${territoryStakingAddress}`);
  console.log(`   TournamentSystem: ${tournamentSystemAddress}`);
  
  // Final balance check
  const finalBalance = await ethers.provider.getBalance(deployer.address);
  console.log(`\n💰 Remaining balance: ${ethers.formatEther(finalBalance)} AVAX`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });