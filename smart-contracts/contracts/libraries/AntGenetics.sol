// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title AntGenetics
 * @dev Library for ant DNA manipulation and trait calculation
 * REFACTORED: Fixed stack too deep error by using structs and reducing local variables
 */
library AntGenetics {
    using Strings for uint256;
    
    // Trait bit positions (each trait uses 8 bits)
    uint256 private constant STRENGTH_OFFSET = 0;
    uint256 private constant SPEED_OFFSET = 8;
    uint256 private constant DEFENSE_OFFSET = 16;
    uint256 private constant INTELLIGENCE_OFFSET = 24;
    uint256 private constant RARITY_OFFSET = 32;
    uint256 private constant CLASS_OFFSET = 40;
    
    // Rarity values (0-255)
    uint256 private constant RARITY_COMMON = 60;
    uint256 private constant RARITY_RARE = 130;
    uint256 private constant RARITY_EPIC = 180;
    uint256 private constant RARITY_LEGENDARY = 220;
    uint256 private constant RARITY_MYTHIC = 250;
    
    // Ant classes
    uint256 private constant CLASS_SOLDIER = 0;
    uint256 private constant CLASS_WORKER = 1;
    uint256 private constant CLASS_SCOUT = 2;
    uint256 private constant CLASS_QUEEN = 3;
    
    // Struct to group DNA traits - helps with stack management
    struct Traits {
        uint256 strength;
        uint256 speed;
        uint256 defense;
        uint256 intelligence;
        uint256 rarity;
        uint256 class;
    }
    
    /**
     * @dev Generate random DNA for new ant
     */
    function generateRandomDNA(
        uint256 nonce1,
        uint256 nonce2,
        uint256 nonce3
    ) internal view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    msg.sender,
                    nonce1,
                    nonce2,
                    nonce3
                )
            )
        );
        
        // Set base traits (1-100)
        uint256 strength = (random % 100) + 1;
        uint256 speed = ((random >> 8) % 100) + 1;
        uint256 defense = ((random >> 16) % 100) + 1;
        uint256 intelligence = ((random >> 24) % 100) + 1;
        
        // Determine rarity
        uint256 rarityRoll = (random >> 32) % 100;
        uint256 rarity;
        if (rarityRoll < 60) rarity = RARITY_COMMON;
        else if (rarityRoll < 85) rarity = RARITY_RARE;
        else if (rarityRoll < 95) rarity = RARITY_EPIC;
        else if (rarityRoll < 99) rarity = RARITY_LEGENDARY;
        else rarity = RARITY_MYTHIC;
        
        // Determine class based on traits
        uint256 class;
        if (strength > speed && strength > defense) class = CLASS_SOLDIER;
        else if (speed > strength && speed > defense) class = CLASS_SCOUT;
        else if (defense > strength && defense > speed) class = CLASS_WORKER;
        else class = CLASS_QUEEN;
        
        // Pack DNA
        uint256 dna = strength;
        dna |= speed << SPEED_OFFSET;
        dna |= defense << DEFENSE_OFFSET;
        dna |= intelligence << INTELLIGENCE_OFFSET;
        dna |= rarity << RARITY_OFFSET;
        dna |= class << CLASS_OFFSET;
        
        return dna;
    }
    
    /**
     * @dev Extract traits from DNA
     */
    function extractTraits(uint256 dna) internal pure returns (Traits memory) {
        return Traits({
            strength: dna & 0xFF,
            speed: (dna >> SPEED_OFFSET) & 0xFF,
            defense: (dna >> DEFENSE_OFFSET) & 0xFF,
            intelligence: (dna >> INTELLIGENCE_OFFSET) & 0xFF,
            rarity: (dna >> RARITY_OFFSET) & 0xFF,
            class: (dna >> CLASS_OFFSET) & 0xFF
        });
    }
    
    /**
     * @dev Mix two parent DNAs to create offspring
     * REFACTORED: Using struct to reduce stack pressure
     */
    function mixDNA(
        uint256 dna1,
        uint256 dna2,
        uint256 timestamp,
        uint256 nonce
    ) internal view returns (uint256) {
        // Extract traits from both parents
        Traits memory t1 = extractTraits(dna1);
        Traits memory t2 = extractTraits(dna2);
        
        // Generate random factor for mixing
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    timestamp,
                    nonce
                )
            )
        );
        
        // Mix traits with mutation
        uint256 strength = _mixTraitWithMutation(t1.strength, t2.strength, random, 0);
        uint256 speed = _mixTraitWithMutation(t1.speed, t2.speed, random, 4);
        uint256 defense = _mixTraitWithMutation(t1.defense, t2.defense, random, 8);
        uint256 intelligence = _mixTraitWithMutation(t1.intelligence, t2.intelligence, random, 12);
        
        // Determine rarity (can be higher than parents)
        uint256 rarity = (t1.rarity + t2.rarity) / 2;
        if ((random >> 16) % 20 == 0) {
            // Mutation to higher rarity
            rarity = (rarity + 50) > 255 ? 255 : rarity + 50;
        }
        
        // Determine class based on dominant trait
        uint256 class = _determineClass(strength, speed, defense, intelligence);
        
        // Pack DNA
        uint256 newDna = strength;
        newDna |= speed << SPEED_OFFSET;
        newDna |= defense << DEFENSE_OFFSET;
        newDna |= intelligence << INTELLIGENCE_OFFSET;
        newDna |= rarity << RARITY_OFFSET;
        newDna |= class << CLASS_OFFSET;
        
        return newDna;
    }
    
    /**
     * @dev Helper function to mix a single trait with mutation
     */
    function _mixTraitWithMutation(
        uint256 trait1,
        uint256 trait2,
        uint256 random,
        uint256 shift
    ) private pure returns (uint256) {
        uint256 mixed = (trait1 + trait2) / 2;
        if ((random >> shift) % 10 == 0) {
            mixed = uint256(keccak256(abi.encodePacked(random, mixed))) % 100 + 1;
        }
        return mixed;
    }
    
    /**
     * @dev Helper function to determine class based on dominant trait
     */
    function _determineClass(
        uint256 strength,
        uint256 speed,
        uint256 defense,
        uint256 intelligence
    ) private pure returns (uint256) {
        uint256 maxTrait = strength;
        if (speed > maxTrait) maxTrait = speed;
        if (defense > maxTrait) maxTrait = defense;
        if (intelligence > maxTrait) maxTrait = intelligence;
        
        if (strength == maxTrait) return CLASS_SOLDIER;
        if (speed == maxTrait) return CLASS_SCOUT;
        if (defense == maxTrait) return CLASS_WORKER;
        return CLASS_QUEEN;
    }
    
    /**
     * @dev Calculate ant power based on DNA and level
     */
    function calculatePower(uint256 dna, uint256 level) internal pure returns (uint256) {
        Traits memory t = extractTraits(dna);
        
        // Base power calculation
        uint256 basePower = t.strength + t.speed + t.defense + t.intelligence;
        
        // Rarity multiplier
        uint256 rarityMultiplier = 100 + (t.rarity / 5); // e.g., 60 -> 112%, 250 -> 150%
        
        // Class bonus
        uint256 classBonus = 0;
        if (t.class == CLASS_SOLDIER) {
            classBonus = t.strength * 20 / 100;
        } else if (t.class == CLASS_WORKER) {
            classBonus = t.defense * 20 / 100;
        } else if (t.class == CLASS_SCOUT) {
            classBonus = t.speed * 20 / 100;
        } else if (t.class == CLASS_QUEEN) {
            classBonus = t.intelligence * 20 / 100;
        }
        
        // Level multiplier
        uint256 levelMultiplier = 100 + (level - 1) * 10; // Level 1: 100%, Level 10: 190%
        
        return ((basePower + classBonus) * rarityMultiplier * levelMultiplier) / 10000;
    }
    
    /**
     * @dev Get trait metadata for tokenURI
     */
    function getTraitMetadata(uint256 dna) internal pure returns (string memory) {
        Traits memory t = extractTraits(dna);
        
        string memory rarityStr;
        if (t.rarity < RARITY_RARE) rarityStr = "Common";
        else if (t.rarity < RARITY_EPIC) rarityStr = "Rare";
        else if (t.rarity < RARITY_LEGENDARY) rarityStr = "Epic";
        else if (t.rarity < RARITY_MYTHIC) rarityStr = "Legendary";
        else rarityStr = "Mythic";
        
        string memory classStr;
        if (t.class == CLASS_SOLDIER) classStr = "Soldier";
        else if (t.class == CLASS_WORKER) classStr = "Worker";
        else if (t.class == CLASS_SCOUT) classStr = "Scout";
        else classStr = "Queen";
        
        return string(abi.encodePacked(
            '{"trait_type":"Class","value":"', classStr, '"},',
            '{"trait_type":"Rarity","value":"', rarityStr, '"},',
            '{"trait_type":"Strength","value":', Strings.toString(t.strength), '},',
            '{"trait_type":"Speed","value":', Strings.toString(t.speed), '},',
            '{"trait_type":"Defense","value":', Strings.toString(t.defense), '},',
            '{"trait_type":"Intelligence","value":', Strings.toString(t.intelligence), '}'
        ));
    }
}