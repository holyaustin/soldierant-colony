import { run } from "hardhat";

async function main() {
  console.log("Verifying contracts on Snowtrace...");

  // Replace with actual deployed addresses
  const addresses = {
    honeyDewToken: "0x...",
    antNFT: "0x...",
    colonyManager: "0x...",
    territoryStaking: "0x...",
    tournamentSystem: "0x...",
  };

  // Verify HoneyDewToken
  await run("verify:verify", {
    address: addresses.honeyDewToken,
    constructorArguments: [],
  });

  // Verify AntNFT
  await run("verify:verify", {
    address: addresses.antNFT,
    constructorArguments: [],
  });

  // Verify ColonyManager
  await run("verify:verify", {
    address: addresses.colonyManager,
    constructorArguments: [
      addresses.antNFT,
      addresses.honeyDewToken,
      addresses.territoryStaking,
      addresses.tournamentSystem,
    ],
  });

  // Verify TerritoryStaking
  await run("verify:verify", {
    address: addresses.territoryStaking,
    constructorArguments: [addresses.antNFT, addresses.colonyManager],
  });

  // Verify TournamentSystem
  await run("verify:verify", {
    address: addresses.tournamentSystem,
    constructorArguments: [
      addresses.antNFT,
      addresses.honeyDewToken,
      addresses.colonyManager,
    ],
  });

  console.log("All contracts verified!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });