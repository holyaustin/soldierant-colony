// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IBattleCalculator
 * @dev Interface for Battle Calculator library
 */
interface IBattleCalculator {
    // Battle result enum
    enum BattleResult {
        OverwhelmingVictory,
        NarrowVictory,
        Stalemate,
        Loss,
        DevastatingDefeat
    }
    
    // Terrain types
    function TERRAIN_PLAINS() external view returns (uint256);
    function TERRAIN_FOREST() external view returns (uint256);
    function TERRAIN_MOUNTAIN() external view returns (uint256);
    function TERRAIN_UNDERGROUND() external view returns (uint256);
    
    // Core functions
    function calculateOutcome(
        uint256[] memory attackerPowers,
        uint256[] memory defenderPowers,
        uint256 terrain,
        uint256 randomNonce
    ) external view returns (
        BattleResult result,
        uint256 attackerCasualties,
        uint256 defenderCasualties
    );
    
    function calculateLoot(
        uint256 defenderResources,
        BattleResult result
    ) external pure returns (uint256);
}