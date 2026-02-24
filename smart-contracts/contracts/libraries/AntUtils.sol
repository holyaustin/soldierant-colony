// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "./AntGenetics.sol";

/**
 * @title AntUtils
 * @dev Library containing common utility functions for AntNFT
 * Helps reduce contract size by moving reusable logic here
 */
library AntUtils {
    using AntGenetics for uint256;
    
    // Custom errors
    error Unauthorized();
    error InvalidAddress();
    error AntDoesNotExist();
    error AntStaked();  // Keep this one
    error NotAntOwner();
    error InvalidBreedingPair();
    error MaxBreedsReached();
    error BreedingCooldownActive();
    error SoulboundBreedingLimit();
    error InsufficientPayment();
    error TransferFailed();
    error AlreadyMaxLevel();
    error InsufficientExperience();
    
    struct BreedParams {
        uint256 parent1Id;
        uint256 parent2Id;
        uint256 breedingCost;
        uint256 breedingFeeBps;
        uint256 maxBreedingAttempts;
        uint256 breedingCooldown;
    }
    
    /**
     * @dev Validate breeding requirements
     * FIXED: Changed from pure to view because it uses block.timestamp
     */
    function validateBreeding(
        uint256 parent1Id,
        uint256 parent2Id,
        address sender,
        address owner1,
        address owner2,
        uint256 breedCount1,
        uint256 breedCount2,
        uint256 lastBreed1,
        uint256 lastBreed2,
        bool soulbound1,
        bool soulbound2,
        uint256 maxBreeds,
        uint256 cooldown,
        uint256 msgValue,
        uint256 requiredCost
    ) internal view {  // Changed from pure to view
        if (msgValue < requiredCost) revert InsufficientPayment();
        if (owner1 != sender || owner2 != sender) revert NotAntOwner();
        if (parent1Id == parent2Id) revert InvalidBreedingPair();
        if (breedCount1 >= maxBreeds) revert MaxBreedsReached();
        if (breedCount2 >= maxBreeds) revert MaxBreedsReached();
        if (block.timestamp < lastBreed1 + cooldown) revert BreedingCooldownActive();  // Uses block.timestamp
        if (block.timestamp < lastBreed2 + cooldown) revert BreedingCooldownActive();  // Uses block.timestamp
        if (soulbound1 && breedCount1 >= 1) revert SoulboundBreedingLimit();
        if (soulbound2 && breedCount2 >= 1) revert SoulboundBreedingLimit();
    }
    
    /**
     * @dev Calculate fee and remainder
     * This can remain pure - no state access
     */
    function calculateFees(uint256 value, uint256 feeBps) internal pure returns (uint256 fee, uint256 remainder) {
        fee = (value * feeBps) / 10000;
        remainder = value - fee;
    }
    
    /**
     * @dev Remove token ID from array
     * This modifies storage, so it's not pure or view
     */
    function removeFromArray(uint256[] storage arr, uint256 tokenId) internal {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == tokenId) {
                arr[i] = arr[arr.length - 1];
                arr.pop();
                break;
            }
        }
    }
}