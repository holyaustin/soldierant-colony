// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/utils/Strings.sol";

library AntGenetics {
    using Strings for uint256;
    
    uint256 private constant STRENGTH_OFFSET = 0;
    uint256 private constant SPEED_OFFSET = 8;
    uint256 private constant DEFENSE_OFFSET = 16;
    uint256 private constant INTELLIGENCE_OFFSET = 24;
    uint256 private constant RARITY_OFFSET = 32;
    uint256 private constant CLASS_OFFSET = 40;
    
    uint256 private constant RARITY_COMMON = 60;
    uint256 private constant RARITY_RARE = 130;
    uint256 private constant RARITY_EPIC = 180;
    uint256 private constant RARITY_LEGENDARY = 220;
    uint256 private constant RARITY_MYTHIC = 250;
    
    uint256 private constant CLASS_SOLDIER = 0;
    uint256 private constant CLASS_WORKER = 1;
    uint256 private constant CLASS_SCOUT = 2;
    uint256 private constant CLASS_QUEEN = 3;
    
    struct Traits {
        uint256 strength;
        uint256 speed;
        uint256 defense;
        uint256 intelligence;
        uint256 rarity;
        uint256 class;
    }
    
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
    
    function generateRandomDNA(uint256 nonce1, uint256 nonce2, uint256 nonce3) internal view returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, nonce1, nonce2, nonce3)));
        
        uint256 strength = (random % 100) + 1;
        uint256 speed = ((random >> 8) % 100) + 1;
        uint256 defense = ((random >> 16) % 100) + 1;
        uint256 intelligence = ((random >> 24) % 100) + 1;
        
        uint256 rarityRoll = (random >> 32) % 100;
        uint256 rarity = rarityRoll < 60 ? RARITY_COMMON :
                         rarityRoll < 85 ? RARITY_RARE :
                         rarityRoll < 95 ? RARITY_EPIC :
                         rarityRoll < 99 ? RARITY_LEGENDARY : RARITY_MYTHIC;
        
        uint256 class;
        if (strength > speed && strength > defense) class = CLASS_SOLDIER;
        else if (speed > strength && speed > defense) class = CLASS_SCOUT;
        else if (defense > strength && defense > speed) class = CLASS_WORKER;
        else class = CLASS_QUEEN;
        
        uint256 dna = strength;
        dna |= speed << SPEED_OFFSET;
        dna |= defense << DEFENSE_OFFSET;
        dna |= intelligence << INTELLIGENCE_OFFSET;
        dna |= rarity << RARITY_OFFSET;
        dna |= class << CLASS_OFFSET;
        
        return dna;
    }
    
    function mixDNA(uint256 dna1, uint256 dna2, uint256 timestamp, uint256 nonce) internal view returns (uint256) {
        Traits memory t1 = extractTraits(dna1);
        Traits memory t2 = extractTraits(dna2);
        
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, timestamp, nonce)));
        
        uint256 strength = _mixTrait(t1.strength, t2.strength, random, 0);
        uint256 speed = _mixTrait(t1.speed, t2.speed, random, 4);
        uint256 defense = _mixTrait(t1.defense, t2.defense, random, 8);
        uint256 intelligence = _mixTrait(t1.intelligence, t2.intelligence, random, 12);
        
        uint256 rarity = (t1.rarity + t2.rarity) / 2;
        if ((random >> 16) % 20 == 0) rarity = (rarity + 50) > 255 ? 255 : rarity + 50;
        
        uint256 maxTrait = strength;
        if (speed > maxTrait) maxTrait = speed;
        if (defense > maxTrait) maxTrait = defense;
        if (intelligence > maxTrait) maxTrait = intelligence;
        
        uint256 class = strength == maxTrait ? CLASS_SOLDIER :
                        speed == maxTrait ? CLASS_SCOUT :
                        defense == maxTrait ? CLASS_WORKER : CLASS_QUEEN;
        
        uint256 newDna = strength;
        newDna |= speed << SPEED_OFFSET;
        newDna |= defense << DEFENSE_OFFSET;
        newDna |= intelligence << INTELLIGENCE_OFFSET;
        newDna |= rarity << RARITY_OFFSET;
        newDna |= class << CLASS_OFFSET;
        
        return newDna;
    }
    
    function _mixTrait(uint256 t1, uint256 t2, uint256 random, uint256 shift) private pure returns (uint256) {
        uint256 mixed = (t1 + t2) / 2;
        if ((random >> shift) % 10 == 0) {
            mixed = uint256(keccak256(abi.encodePacked(random, mixed))) % 100 + 1;
        }
        return mixed;
    }
    
    function calculatePower(uint256 dna, uint256 level) internal pure returns (uint256) {
        Traits memory t = extractTraits(dna);
        uint256 base = t.strength + t.speed + t.defense + t.intelligence;
        uint256 bonus = t.class == CLASS_SOLDIER ? t.strength * 20 / 100 :
                        t.class == CLASS_WORKER ? t.defense * 20 / 100 :
                        t.class == CLASS_SCOUT ? t.speed * 20 / 100 :
                        t.intelligence * 20 / 100;
        return (base + bonus) * (100 + t.rarity / 5) * (100 + (level - 1) * 10) / 10000;
    }
    
    function getTraitMetadata(uint256 dna) internal pure returns (string memory) {
        Traits memory t = extractTraits(dna);
        
        string memory rarityStr = t.rarity < RARITY_RARE ? "Common" :
                                  t.rarity < RARITY_EPIC ? "Rare" :
                                  t.rarity < RARITY_LEGENDARY ? "Epic" :
                                  t.rarity < RARITY_MYTHIC ? "Legendary" : "Mythic";
        
        string memory classStr = t.class == CLASS_SOLDIER ? "Soldier" :
                                 t.class == CLASS_WORKER ? "Worker" :
                                 t.class == CLASS_SCOUT ? "Scout" : "Queen";
        
        return string(abi.encodePacked(
            '{"trait_type":"Class","value":"', classStr, '"},',
            '{"trait_type":"Rarity","value":"', rarityStr, '"},',
            '{"trait_type":"Strength","value":', t.strength.toString(), '},',
            '{"trait_type":"Speed","value":', t.speed.toString(), '},',
            '{"trait_type":"Defense","value":', t.defense.toString(), '},',
            '{"trait_type":"Intelligence","value":', t.intelligence.toString(), '}'
        ));
    }
}