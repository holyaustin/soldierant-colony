// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "./IAntNFT.sol";
import "./IColonyManager.sol";

/**
 * @title ITerritoryStaking
 * @dev Interface for Territory Staking contract
 */
interface ITerritoryStaking {
    // Structs
    struct Territory {
        uint256 id;
        uint256 tier;
        address owner;
        uint256[] stakedAnts;
        uint256 lastClaimTime;
        uint256 totalPower;
        bool isActive;
    }
    
    struct BattleRequest {
        address attacker;
        uint256 territoryId;
        uint256[] attackerAnts;
        uint256 requestTime;
        bool resolved;
    }
    
    // Events
    event TerritoryCreated(uint256 indexed territoryId, uint256 tier);
    event TerritoryStaked(uint256 indexed territoryId, address indexed owner, uint256[] antIds);
    event TerritoryUnstaked(uint256 indexed territoryId, address indexed owner);
    event ResourcesClaimed(address indexed owner, uint256 territoryId, uint256 amount);
    event BattleInitiated(uint256 indexed battleId, address attacker, uint256 territoryId);
    event BattleResolved(uint256 indexed battleId, address winner, uint256 loot);
    
    // Core Functions
    function stakeAnts(uint256 territoryId, uint256[] calldata antIds) external;
    function unstakeAnts(uint256 territoryId, uint256[] calldata antIds) external;
    function claimResources(uint256 territoryId) external;
    function initiateBattle(uint256 territoryId, uint256[] calldata attackerAnts) external;
    function resolveBattle(uint256 battleId) external;
    
    // View Functions
    function getTerritoryDetails(uint256 territoryId) external view returns (
        uint256 tier,
        address owner,
        uint256[] memory stakedAnts,
        uint256 totalPower,
        uint256 unclaimedRewards,
        bool isActive
    );
    function getPlayerTerritories(address player) external view returns (uint256[] memory);
    function getUnclaimedRewards(uint256 territoryId) external view returns (uint256);
    function getTierSlots(uint256 tier) external pure returns (uint256);
    function getTierBaseReward(uint256 tier) external pure returns (uint256);
    
    // Admin Functions
    function createTerritory(uint256 tier) external;
    function setAntNFT(address _antNFT) external;
    function setColonyManager(address _colonyManager) external;
}