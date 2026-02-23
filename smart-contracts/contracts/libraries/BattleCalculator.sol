// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title BattleCalculator
 * @dev Library for battle resolution logic
 * Gas optimized for on-chain calculations
 */
library BattleCalculator {
    // Battle result enum
    enum BattleResult {
        OverwhelmingVictory,
        NarrowVictory,
        Stalemate,
        Loss,
        DevastatingDefeat
    }
    
    // Terrain types
    uint256 public constant TERRAIN_PLAINS = 0;
    uint256 public constant TERRAIN_FOREST = 1;
    uint256 public constant TERRAIN_MOUNTAIN = 2;
    uint256 public constant TERRAIN_UNDERGROUND = 3;
    
    /**
     * @dev Calculate battle outcome based on ant powers and terrain
     */
    function calculateOutcome(
        uint256[] memory attackerPowers,
        uint256[] memory defenderPowers,
        uint256 terrain,
        uint256 randomNonce
    ) internal view returns (BattleResult, uint256 attackerCasualties, uint256 defenderCasualties) {
        uint256 attackerTotal = 0;
        uint256 defenderTotal = 0;
        
        // Sum powers
        for (uint256 i = 0; i < attackerPowers.length; i++) {
            attackerTotal += attackerPowers[i];
        }
        
        for (uint256 i = 0; i < defenderPowers.length; i++) {
            defenderTotal += defenderPowers[i];
        }
        
        // Apply terrain bonuses
        attackerTotal = applyTerrainBonus(attackerTotal, terrain, true, randomNonce);
        defenderTotal = applyTerrainBonus(defenderTotal, terrain, false, randomNonce);
        
        // Calculate ratio
        if (defenderTotal == 0) {
            return (BattleResult.OverwhelmingVictory, 0, defenderPowers.length);
        }
        
        uint256 ratio = (attackerTotal * 100) / defenderTotal;
        
        // Determine outcome
        BattleResult result;
        if (ratio > 150) {
            result = BattleResult.OverwhelmingVictory;
        } else if (ratio > 115) {
            result = BattleResult.NarrowVictory;
        } else if (ratio > 85) {
            result = BattleResult.Stalemate;
        } else if (ratio > 50) {
            result = BattleResult.Loss;
        } else {
            result = BattleResult.DevastatingDefeat;
        }
        
        // Calculate casualties
        (attackerCasualties, defenderCasualties) = calculateCasualties(
            attackerPowers.length,
            defenderPowers.length,
            ratio,
            randomNonce
        );
        
        return (result, attackerCasualties, defenderCasualties);
    }
    
    /**
     * @dev Apply terrain bonus to army power
     */
    function applyTerrainBonus(
        uint256 power,
        uint256 terrain,
        bool isAttacker,
        uint256 randomNonce
    ) private view returns (uint256) {
        // Random factor for unpredictability (-10% to +10%)
        uint256 randomFactor = 90 + (uint256(keccak256(abi.encodePacked(block.timestamp, randomNonce))) % 21);
        
        // Terrain bonuses (simplified)
        if (terrain == TERRAIN_FOREST && !isAttacker) {
            // Defenders get bonus in forest
            power = power * 115 / 100;
        } else if (terrain == TERRAIN_MOUNTAIN && !isAttacker) {
            power = power * 120 / 100;
        } else if (terrain == TERRAIN_UNDERGROUND && !isAttacker) {
            power = power * 110 / 100;
        }
        
        // Apply random factor
        power = power * randomFactor / 100;
        
        return power;
    }
    
    /**
     * @dev Calculate casualties based on battle ratio
     */
    function calculateCasualties(
        uint256 attackerCount,
        uint256 defenderCount,
        uint256 ratio,
        uint256 randomNonce
    ) private pure returns (uint256 attackerLosses, uint256 defenderLosses) {
        // Base casualties
        if (ratio > 150) {
            attackerLosses = 1;
            defenderLosses = defenderCount;
        } else if (ratio > 115) {
            attackerLosses = attackerCount * 20 / 100;
            defenderLosses = defenderCount * 60 / 100;
        } else if (ratio > 85) {
            attackerLosses = attackerCount * 30 / 100;
            defenderLosses = defenderCount * 30 / 100;
        } else if (ratio > 50) {
            attackerLosses = attackerCount * 60 / 100;
            defenderLosses = defenderCount * 20 / 100;
        } else {
            attackerLosses = attackerCount;
            defenderLosses = 1;
        }
        
        // Add randomness
        uint256 random = uint256(keccak256(abi.encodePacked(randomNonce, ratio))) % 10;
        if (random < 3) {
            // Reduce losses
            attackerLosses = attackerLosses * 90 / 100;
            defenderLosses = defenderLosses * 90 / 100;
        } else if (random > 6) {
            // Increase losses
            attackerLosses = attackerLosses * 110 / 100;
            defenderLosses = defenderLosses * 110 / 100;
        }
        
        // Ensure minimum and maximum bounds
        if (attackerLosses > attackerCount) attackerLosses = attackerCount;
        if (defenderLosses > defenderCount) defenderLosses = defenderCount;
        if (attackerLosses == 0 && attackerCount > 0 && ratio < 100) attackerLosses = 1;
        if (defenderLosses == 0 && defenderCount > 0 && ratio > 100) defenderLosses = 1;
        
        return (attackerLosses, defenderLosses);
    }
    
    /**
     * @dev Calculate loot amount based on battle result
     */
    function calculateLoot(
        uint256 defenderResources,
        BattleResult result
    ) internal pure returns (uint256) {
        if (result == BattleResult.OverwhelmingVictory) {
            return defenderResources * 30 / 100; // 30% loot
        } else if (result == BattleResult.NarrowVictory) {
            return defenderResources * 20 / 100; // 20% loot
        } else if (result == BattleResult.Stalemate) {
            return defenderResources * 10 / 100; // 10% loot (mutual destruction)
        }
        
        return 0; // No loot on loss
    }
}