// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IColonyManager
 * @dev Interface for Colony Manager contract
 */
interface IColonyManager {
    // Structs
    struct Colony {
        uint256 level;
        uint256 experience;
        uint256 territoryCount;
        uint256 totalPower;
        uint256 lastResetTime;
        uint256 resetCount;
    }
    
    struct ResetBenefits {
        uint256 hnyReward;
        uint256 wisdomFragments;
        bool hasReset;
    }
    
    // Events
    event ColonyReset(address indexed player, uint256 resetCount, uint256 hnyReward);
    event ColonyLevelUp(address indexed player, uint256 newLevel);
    event ExperienceGained(address indexed player, uint256 amount);
    event TerritoryAdded(address indexed player, uint256 territoryId);
    event TerritoryRemoved(address indexed player, uint256 territoryId);
    
    // Core Functions
    function initializeColony() external;
    function resetColony(uint256 paymentToken) external payable;
    function addExperience(address player, uint256 amount) external;
    
    // View Functions
    function getColonyDetails(address player) external view returns (
        uint256 level,
        uint256 experience,
        uint256 territoryCount,
        uint256 totalPower,
        uint256 resetCount,
        uint256 nextLevelXP
    );
    function getResetBenefits(address player) external view returns (
        uint256 hnyReward,
        uint256 wisdomFragments,
        bool hasReset
    );
    function getResetCooldown(uint256 resetCount) external view returns (uint256);
    function getResetCostHNY(uint256 resetNumber) external view returns (uint256);
    function getResetCostAVAX(uint256 resetNumber) external view returns (uint256);
    
    // Territory management
    function addTerritory(address player, uint256 territoryId) external;
    function removeTerritory(address player, uint256 territoryId) external;
    
    // Admin Functions
    function setAntNFT(address _antNFT) external;
    function setHNYToken(address _hnyToken) external;
    function setTerritoryStaking(address _territoryStaking) external;
    function setTournamentSystem(address _tournamentSystem) external;
}