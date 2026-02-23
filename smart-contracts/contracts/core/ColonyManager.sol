// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IAntNFT.sol";
import "../interfaces/ITerritoryStaking.sol";
import "../interfaces/ITournamentSystem.sol";
import "../tokens/HoneyDewToken.sol";

/**
 * @title ColonyManager
 * @dev Manages colony state, resets, and overall game progression
 * Compatible with OpenZeppelin 5.0 (Counters.sol removed)
 */
contract ColonyManager is Ownable, ReentrancyGuard {
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
    
    // Constants
    uint256 public constant RESET_COOLDOWN_1 = 7 days;
    uint256 public constant RESET_COOLDOWN_2 = 14 days;
    uint256 public constant RESET_COOLDOWN_3 = 30 days;
    uint256 public constant RESET_COOLDOWN_4 = 60 days;
    
    uint256 public constant RESET_COST_HNY_2 = 2000 * 10**18;
    uint256 public constant RESET_COST_HNY_3 = 5000 * 10**18;
    uint256 public constant RESET_COST_HNY_4 = 10000 * 10**18;
    
    uint256 public constant RESET_COST_AVAX_2 = 0.05 ether;
    uint256 public constant RESET_COST_AVAX_3 = 0.1 ether;
    uint256 public constant RESET_COST_AVAX_4 = 0.2 ether;
    
    uint256 public constant FRESH_START_HNY = 30 * 10**18;
    uint256 public constant WISDOM_FRAGMENTS_FIRST = 1;
    
    // State variables - Store as addresses
    address private _antNFTAddress;
    address private _hnyTokenAddress;
    address private _territoryStakingAddress;
    address private _tournamentSystemAddress;
    
    // Colony data
    mapping(address => Colony) public colonies;
    mapping(address => ResetBenefits) public resetBenefits;
    mapping(address => uint256) public colonyLevels;
    mapping(address => uint256) public totalExperience;
    mapping(address => mapping(uint256 => bool)) public playerTerritories;
    
    // Events
    event ColonyReset(address indexed player, uint256 resetCount, uint256 hnyReward);
    event ColonyLevelUp(address indexed player, uint256 newLevel);
    event ExperienceGained(address indexed player, uint256 amount);
    event TerritoryAdded(address indexed player, uint256 territoryId);
    event TerritoryRemoved(address indexed player, uint256 territoryId);
    
    constructor(
        address antNFT_,
        address hnyToken_,
        address territoryStaking_,
        address tournamentSystem_
    ) Ownable(msg.sender) {
        _antNFTAddress = antNFT_;
        _hnyTokenAddress = hnyToken_;
        _territoryStakingAddress = territoryStaking_;
        _tournamentSystemAddress = tournamentSystem_;
    }
    
    /**
     * @dev Get AntNFT contract instance - FIXED: Use payable address conversion
     */
    function antNFT() public view returns (IAntNFT) {
        return IAntNFT(_antNFTAddress);
    }
    
    /**
     * @dev Get HoneyDewToken contract instance - FIXED: Use payable address conversion
     */
    function hnyToken() public view returns (HoneyDewToken) {
        // FIX: Convert to payable address first, then to contract type
        return HoneyDewToken(payable(_hnyTokenAddress));
    }
    
    /**
     * @dev Get TerritoryStaking contract instance
     */
    function territoryStaking() public view returns (ITerritoryStaking) {
        return ITerritoryStaking(_territoryStakingAddress);
    }
    
    /**
     * @dev Get TournamentSystem contract instance
     */
    function tournamentSystem() public view returns (ITournamentSystem) {
        return ITournamentSystem(_tournamentSystemAddress);
    }
    
    /**
     * @dev Initialize a new colony for player
     */
    function initializeColony() external {
        require(colonies[msg.sender].level == 0, "Colony already initialized");
        
        Colony storage colony = colonies[msg.sender];
        colony.level = 1;
        colony.lastResetTime = block.timestamp;
        
        emit ColonyLevelUp(msg.sender, 1);
    }
    
    /**
     * @dev Reset colony to start fresh
     * @param paymentToken 0 for HNY, 1 for AVAX
     */
    function resetColony(uint256 paymentToken) external payable nonReentrant {
        Colony storage colony = colonies[msg.sender];
        require(colony.level > 0, "Colony not initialized");
        require(block.timestamp >= colony.lastResetTime + getResetCooldown(colony.resetCount), "Cooldown active");
        
        uint256 resetNumber = colony.resetCount + 1;
        
        // Handle payment
        if (resetNumber > 1) {
            if (paymentToken == 0) {
                // Pay with HNY - FIXED: Use IERC20 interface for transferFrom
                uint256 hnyCost = getResetCostHNY(resetNumber);
                require(IERC20(_hnyTokenAddress).balanceOf(msg.sender) >= hnyCost, "Insufficient HNY");
                require(IERC20(_hnyTokenAddress).transferFrom(msg.sender, address(this), hnyCost), "Transfer failed");
                // Burn HNY on reset - FIXED: Use payable conversion for burn
                HoneyDewToken(payable(_hnyTokenAddress)).burn(hnyCost);
            } else {
                // Pay with AVAX
                uint256 avaxCost = getResetCostAVAX(resetNumber);
                require(msg.value >= avaxCost, "Insufficient AVAX");
                
                // Refund excess
                if (msg.value > avaxCost) {
                    (bool refundSuccess, ) = payable(msg.sender).call{value: msg.value - avaxCost}("");
                    require(refundSuccess, "Refund failed");
                }
            }
        }
        
        // Store old ants as Legacy Eggs
        uint256[] memory oldAnts = antNFT().getOwnerAnts(msg.sender);
        
        // Transfer ants to contract as legacy
        for (uint256 i = 0; i < oldAnts.length; i++) {
            antNFT().transferFrom(msg.sender, address(this), oldAnts[i]);
        }
        
        // Reset colony state
        colony.level = 1;
        colony.experience = 0;
        colony.territoryCount = 0;
        colony.totalPower = 0;
        colony.lastResetTime = block.timestamp;
        colony.resetCount++;
        
        // Give fresh start benefits
        if (colony.resetCount == 1) {
            resetBenefits[msg.sender].hnyReward += FRESH_START_HNY;
            resetBenefits[msg.sender].wisdomFragments += WISDOM_FRAGMENTS_FIRST;
            resetBenefits[msg.sender].hasReset = true;
        }
        
        emit ColonyReset(msg.sender, colony.resetCount, FRESH_START_HNY);
    }
    
    /**
     * @dev Add experience to colony
     */
    function addExperience(address player, uint256 amount) external {
        require(
            msg.sender == _antNFTAddress || 
            msg.sender == _territoryStakingAddress || 
            msg.sender == _tournamentSystemAddress ||
            msg.sender == owner(),
            "Unauthorized"
        );
        
        Colony storage colony = colonies[player];
        require(colony.level > 0, "Colony not initialized");
        
        colony.experience += amount;
        totalExperience[player] += amount;
        
        // Check for level up (100 * level^2 required)
        while (colony.level < 10 && colony.experience >= 100 * (colony.level ** 2)) {
            colony.experience -= 100 * (colony.level ** 2);
            colony.level++;
            
            // Mint HNY reward for level up - FIXED: Use payable conversion
            uint256 hnyReward = getLevelUpReward(colony.level);
            if (hnyReward > 0) {
                HoneyDewToken(payable(_hnyTokenAddress)).mintReward(player, hnyReward);
            }
            
            emit ColonyLevelUp(player, colony.level);
        }
        
        emit ExperienceGained(player, amount);
    }
    
    /**
     * @dev Get level up HNY reward
     */
    function getLevelUpReward(uint256 newLevel) internal pure returns (uint256) {
        if (newLevel == 5) return 50 * 10**18;
        if (newLevel == 10) return 75 * 10**18;
        if (newLevel == 15) return 100 * 10**18;
        if (newLevel == 20) return 150 * 10**18;
        if (newLevel == 25) return 200 * 10**18;
        if (newLevel == 30) return 250 * 10**18;
        return 0;
    }
    
    /**
     * @dev Get reset cooldown based on reset count
     */
    function getResetCooldown(uint256 resetCount) public pure returns (uint256) {
        if (resetCount == 0) return RESET_COOLDOWN_1;
        if (resetCount == 1) return RESET_COOLDOWN_2;
        if (resetCount == 2) return RESET_COOLDOWN_3;
        return RESET_COOLDOWN_4;
    }
    
    /**
     * @dev Get reset cost in HNY
     */
    function getResetCostHNY(uint256 resetNumber) public pure returns (uint256) {
        if (resetNumber == 2) return RESET_COST_HNY_2;
        if (resetNumber == 3) return RESET_COST_HNY_3;
        if (resetNumber >= 4) return RESET_COST_HNY_4;
        return 0;
    }
    
    /**
     * @dev Get reset cost in AVAX
     */
    function getResetCostAVAX(uint256 resetNumber) public pure returns (uint256) {
        if (resetNumber == 2) return RESET_COST_AVAX_2;
        if (resetNumber == 3) return RESET_COST_AVAX_3;
        if (resetNumber >= 4) return RESET_COST_AVAX_4;
        return 0;
    }
    
    /**
     * @dev Get colony details
     */
    function getColonyDetails(address player) external view returns (
        uint256 level,
        uint256 experience,
        uint256 territoryCount,
        uint256 totalPower,
        uint256 resetCount,
        uint256 nextLevelXP
    ) {
        Colony storage colony = colonies[player];
        require(colony.level > 0, "Colony not initialized");
        
        return (
            colony.level,
            colony.experience,
            colony.territoryCount,
            colony.totalPower,
            colony.resetCount,
            100 * (colony.level ** 2)
        );
    }
    
    /**
     * @dev Get reset benefits for player
     */
    function getResetBenefits(address player) external view returns (
        uint256 hnyReward,
        uint256 wisdomFragments,
        bool hasReset
    ) {
        ResetBenefits storage benefits = resetBenefits[player];
        return (
            benefits.hnyReward,
            benefits.wisdomFragments,
            benefits.hasReset
        );
    }
    
    // Territory management functions
    function addTerritory(address player, uint256 territoryId) external {
        require(msg.sender == _territoryStakingAddress || msg.sender == owner(), "Unauthorized");
        playerTerritories[player][territoryId] = true;
        colonies[player].territoryCount++;
        emit TerritoryAdded(player, territoryId);
    }
    
    function removeTerritory(address player, uint256 territoryId) external {
        require(msg.sender == _territoryStakingAddress || msg.sender == owner(), "Unauthorized");
        playerTerritories[player][territoryId] = false;
        colonies[player].territoryCount--;
        emit TerritoryRemoved(player, territoryId);
    }
    
    // Setter functions for contract references
    function setAntNFT(address antNFT_) external onlyOwner {
        _antNFTAddress = antNFT_;
    }
    
    function setHNYToken(address hnyToken_) external onlyOwner {
        _hnyTokenAddress = hnyToken_;
    }
    
    function setTerritoryStaking(address territoryStaking_) external onlyOwner {
        _territoryStakingAddress = territoryStaking_;
    }
    
    function setTournamentSystem(address tournamentSystem_) external onlyOwner {
        _tournamentSystemAddress = tournamentSystem_;
    }
    
    // Receive function to accept AVAX
    receive() external payable {}
}