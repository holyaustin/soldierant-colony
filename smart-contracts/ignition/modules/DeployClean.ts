import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DeployCleanModule = buildModule("DeployClean", (m) => {
  // Deploy HoneyDewToken - no constructor args
  const honeyDewToken = m.contract("HoneyDewToken", [], {
    id: "HoneyDewToken",
  });

  // Deploy AntNFT - no constructor args
  const antNFT = m.contract("AntNFT", [], {
    id: "AntNFT",
    after: [honeyDewToken],
  });

  // Deploy ColonyManager
  const colonyManager = m.contract("ColonyManager", [
    antNFT,
    honeyDewToken,
    m.getParameter("territoryStakingAddress", "0x0000000000000000000000000000000000000000"),
    m.getParameter("tournamentSystemAddress", "0x0000000000000000000000000000000000000000"),
  ], {
    id: "ColonyManager",
    after: [antNFT],
  });

  // Deploy TerritoryStaking
  const territoryStaking = m.contract("TerritoryStaking", [
    antNFT,
    colonyManager,
  ], {
    id: "TerritoryStaking",
    after: [colonyManager],
  });

  // Deploy TournamentSystem
  const tournamentSystem = m.contract("TournamentSystem", [
    antNFT,
    honeyDewToken,
    colonyManager,
  ], {
    id: "TournamentSystem",
    after: [territoryStaking],
  });

  // Set addresses in ColonyManager
  m.call(colonyManager, "setTerritoryStaking", [territoryStaking], {
    id: "SetTerritoryStaking",
    after: [territoryStaking],
  });

  m.call(colonyManager, "setTournamentSystem", [tournamentSystem], {
    id: "SetTournamentSystem",
    after: [tournamentSystem],
  });

  // Set addresses in AntNFT
  m.call(antNFT, "setColonyManager", [colonyManager], {
    id: "SetColonyManager",
    after: [colonyManager],
  });

  m.call(antNFT, "setTournamentSystem", [tournamentSystem], {
    id: "SetTournamentSystemInAntNFT",
    after: [tournamentSystem],
  });

  return {
    honeyDewToken,
    antNFT,
    colonyManager,
    territoryStaking,
    tournamentSystem,
  };
});

export default DeployCleanModule;