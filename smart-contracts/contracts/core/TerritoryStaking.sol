// SPDX-License-Identifier: MIT 
pragma solidity 0.8.30;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IAntNFT.sol";
import "../interfaces/IColonyManager.sol";
import "../libraries/BattleCalculator.sol"; // Make sure to import this

/**
 * @title TerritoryStaking
 * @dev Manages territory staking, claiming, and battles
 * Compatible with OpenZeppelin 5.0 (Counters.sol removed)
 */
contract TerritoryStaking is Ownable, ReentrancyGuard {
    // Territory tiers
    uint256 public constant TIER_1_SLOTS = 1;
    uint256 public constant TIER_2_SLOTS = 3;
    uint256 public constant TIER_3_SLOTS = 5;
    uint256 public constant TIER_4_SLOTS = 10;
    uint256 public constant TIER_5_SLOTS = 20;
    
    uint256 public constant TIER_1_BASE_REWARD = 0.005 ether;
    uint256 public constant TIER_2_BASE_REWARD = 0.015 ether;
    uint256 public constant TIER_3_BASE_REWARD = 0.03 ether;
    uint256 public constant TIER_4_BASE_REWARD = 0.07 ether;
    uint256 public constant TIER_5_BASE_REWARD = 0.15 ether;
    
    uint256 public constant MAX_TERRITORIES_PER_PLAYER = 5;
    uint256 public constant CLAIM_COOLDOWN = 1 days;
    uint256 public constant BATTLE_COOLDOWN = 12 hours;
    uint256 public constant BATTLE_TIMEOUT = 15 minutes;
    
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
    
    // State variables - REPLACED Counters.Counter with uint256
    uint256 private _nextTerritoryId = 1; // Start from 1 (0 is invalid)
    
    mapping(uint256 => Territory) public territories;
    mapping(address => uint256[]) public playerTerritories;
    mapping(uint256 => BattleRequest) public battleRequests;
    mapping(address => uint256) public lastBattleTime;
    
    // Contract references
    IAntNFT public antNFT;
    IColonyManager public colonyManager;
    
    // Events
    event TerritoryCreated(uint256 indexed territoryId, uint256 tier);
    event TerritoryStaked(uint256 indexed territoryId, address indexed owner, uint256[] antIds);
    event TerritoryUnstaked(uint256 indexed territoryId, address indexed owner);
    event ResourcesClaimed(address indexed owner, uint256 territoryId, uint256 amount);
    event BattleInitiated(uint256 indexed battleId, address attacker, uint256 territoryId);
    event BattleResolved(uint256 indexed battleId, address winner, uint256 loot);
    
    constructor(address _antNFT, address _colonyManager) Ownable(msg.sender) {
        antNFT = IAntNFT(_antNFT);
        colonyManager = IColonyManager(_colonyManager);
        
        // Create initial territories
        for (uint256 i = 0; i < 10; i++) {
            _createTerritory(1); // Tier 1 territories
        }
        for (uint256 i = 0; i < 5; i++) {
            _createTerritory(2); // Tier 2 territories
        }
        for (uint256 i = 0; i < 3; i++) {
            _createTerritory(3); // Tier 3 territories
        }
        _createTerritory(4); // Tier 4 territory
        _createTerritory(5); // Tier 5 territory
    }
    
    /**
     * @dev Create a new territory (admin only)
     */
    function _createTerritory(uint256 tier) internal {
        uint256 territoryId = _nextTerritoryId;
        _nextTerritoryId++;
        
        territories[territoryId] = Territory({
            id: territoryId,
            tier: tier,
            owner: address(0),
            stakedAnts: new uint256[](0),
            lastClaimTime: 0,
            totalPower: 0,
            isActive: true
        });
        
        emit TerritoryCreated(territoryId, tier);
    }
    
    /**
     * @dev Stake ants in a territory
     * @param territoryId Territory to stake
     * @param antIds Array of ant token IDs to stake
     */
    function stakeAnts(uint256 territoryId, uint256[] calldata antIds) external nonReentrant {
        Territory storage territory = territories[territoryId];
        require(territory.isActive, "Territory not active");
        require(territory.owner == address(0) || territory.owner == msg.sender, "Not owner");
        require(antIds.length > 0, "No ants provided");
        
        // Check tier slots
        uint256 maxSlots = getTierSlots(territory.tier);
        require(antIds.length <= maxSlots, "Exceeds max slots");
        require(territory.stakedAnts.length + antIds.length <= maxSlots, "Would exceed max slots");
        
        // Check player territory limit
        if (territory.owner == address(0)) {
            require(playerTerritories[msg.sender].length < MAX_TERRITORIES_PER_PLAYER, "Max territories reached");
        }
        
        // Verify ownership and stake ants
        uint256 totalPower = territory.totalPower;
        for (uint256 i = 0; i < antIds.length; i++) {
            require(antNFT.ownerOf(antIds[i]) == msg.sender, "Not owner of ant");
            require(!antNFT.isStaked(antIds[i]), "Ant already staked");
            
            // Stake ant
            antNFT.setStaked(antIds[i], true);
            territory.stakedAnts.push(antIds[i]);
            
            // Add power
            totalPower += antNFT.getAntPower(antIds[i]);
        }
        
        // Update territory
        if (territory.owner == address(0)) {
            territory.owner = msg.sender;
            playerTerritories[msg.sender].push(territoryId);
            territory.lastClaimTime = block.timestamp;
        }
        
        territory.totalPower = totalPower;
        
        // Add experience to colony
        colonyManager.addExperience(msg.sender, 10 * antIds.length);
        
        emit TerritoryStaked(territoryId, msg.sender, antIds);
    }
    
    /**
     * @dev Unstake ants from territory
     * @param territoryId Territory to unstake from
     * @param antIds Array of ant token IDs to unstake
     */
    function unstakeAnts(uint256 territoryId, uint256[] calldata antIds) external nonReentrant {
        Territory storage territory = territories[territoryId];
        require(territory.owner == msg.sender, "Not owner");
        require(antIds.length > 0, "No ants provided");
        
        // Create mapping for quick lookup - FIXED: Use a simpler approach
        bool[] memory toUnstake = new bool[](territory.stakedAnts.length);
        
        // Mark ants to unstake
        for (uint256 i = 0; i < antIds.length; i++) {
            for (uint256 j = 0; j < territory.stakedAnts.length; j++) {
                if (territory.stakedAnts[j] == antIds[i]) {
                    toUnstake[j] = true;
                    break;
                }
            }
        }
        
        // Remove ants and update power
        uint256 totalPower = territory.totalPower;
        uint256 newLength = 0;
        
        // Create new array without unstaked ants
        uint256[] memory remainingAnts = new uint256[](territory.stakedAnts.length);
        for (uint256 i = 0; i < territory.stakedAnts.length; i++) {
            if (!toUnstake[i]) {
                remainingAnts[newLength] = territory.stakedAnts[i];
                newLength++;
            } else {
                // Unstake ant and subtract power
                antNFT.setStaked(territory.stakedAnts[i], false);
                totalPower -= antNFT.getAntPower(territory.stakedAnts[i]);
            }
        }
        
        // Update storage array
        delete territory.stakedAnts;
        for (uint256 i = 0; i < newLength; i++) {
            territory.stakedAnts.push(remainingAnts[i]);
        }
        
        territory.totalPower = totalPower;
        
        // If no ants left, territory becomes unowned
        if (territory.stakedAnts.length == 0) {
            // Remove from player territories
            uint256[] storage playerTerr = playerTerritories[msg.sender];
            for (uint256 i = 0; i < playerTerr.length; i++) {
                if (playerTerr[i] == territoryId) {
                    playerTerr[i] = playerTerr[playerTerr.length - 1];
                    playerTerr.pop();
                    break;
                }
            }
            
            territory.owner = address(0);
            territory.lastClaimTime = 0;
        }
        
        emit TerritoryUnstaked(territoryId, msg.sender);
    }
    
    /**
     * @dev Claim resources from territory
     * @param territoryId Territory to claim from
     */
    function claimResources(uint256 territoryId) external nonReentrant {
        Territory storage territory = territories[territoryId];
        require(territory.owner == msg.sender, "Not owner");
        require(block.timestamp >= territory.lastClaimTime + CLAIM_COOLDOWN, "Claim cooldown active");
        
        uint256 unclaimed = getUnclaimedRewards(territoryId);
        require(unclaimed > 0, "No rewards to claim");
        
        territory.lastClaimTime = block.timestamp;
        
        // Send AVAX to owner
        (bool success, ) = payable(msg.sender).call{value: unclaimed}("");
        require(success, "Transfer failed");
        
        emit ResourcesClaimed(msg.sender, territoryId, unclaimed);
    }
    
    /**
     * @dev Get unclaimed rewards for territory
     */
    function getUnclaimedRewards(uint256 territoryId) public view returns (uint256) {
        Territory storage territory = territories[territoryId];
        if (territory.owner == address(0) || territory.lastClaimTime == 0) {
            return 0;
        }
        
        uint256 timePassed = block.timestamp - territory.lastClaimTime;
        uint256 daysPassed = timePassed / CLAIM_COOLDOWN;
        
        if (daysPassed == 0) return 0;
        
        uint256 baseReward = getTierBaseReward(territory.tier);
        
        // Calculate average power multiplier (avoid division by zero)
        uint256 powerMultiplier = 100; // Default 100%
        if (territory.stakedAnts.length > 0) {
            powerMultiplier = (territory.totalPower * 100) / (territory.stakedAnts.length * 100);
        }
        
        return baseReward * daysPassed * powerMultiplier / 100;
    }
    
    /**
     * @dev Initiate battle for territory
     * @param territoryId Territory to attack
     * @param attackerAnts Array of ant token IDs for attack
     */
    function initiateBattle(uint256 territoryId, uint256[] calldata attackerAnts) external nonReentrant {
        Territory storage territory = territories[territoryId];
        require(territory.isActive, "Territory not active");
        require(territory.owner != msg.sender, "Cannot attack own territory");
        require(attackerAnts.length > 0, "No ants provided");
        require(block.timestamp >= lastBattleTime[msg.sender] + BATTLE_COOLDOWN, "Battle cooldown");
        
        // Verify attacker owns all ants and they're not staked
        for (uint256 i = 0; i < attackerAnts.length; i++) {
            require(antNFT.ownerOf(attackerAnts[i]) == msg.sender, "Not owner of ant");
            require(!antNFT.isStaked(attackerAnts[i]), "Ant is staked");
        }
        
        uint256 battleId = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, territoryId)));
        
        battleRequests[battleId] = BattleRequest({
            attacker: msg.sender,
            territoryId: territoryId,
            attackerAnts: attackerAnts,
            requestTime: block.timestamp,
            resolved: false
        });
        
        lastBattleTime[msg.sender] = block.timestamp;
        
        emit BattleInitiated(battleId, msg.sender, territoryId);
    }
    
    /**
     * @dev Resolve battle (called by keeper or after timeout)
     */
    function resolveBattle(uint256 battleId) external nonReentrant {
        BattleRequest storage request = battleRequests[battleId];
        require(!request.resolved, "Already resolved");
        require(block.timestamp >= request.requestTime + BATTLE_TIMEOUT, "Battle not ready");
        
        Territory storage territory = territories[request.territoryId];
        
        // Get powers
        uint256[] memory attackerPowers = new uint256[](request.attackerAnts.length);
        for (uint256 i = 0; i < request.attackerAnts.length; i++) {
            attackerPowers[i] = antNFT.getAntPower(request.attackerAnts[i]);
        }
        
        uint256[] memory defenderPowers = new uint256[](territory.stakedAnts.length);
        for (uint256 i = 0; i < territory.stakedAnts.length; i++) {
            defenderPowers[i] = antNFT.getAntPower(territory.stakedAnts[i]);
        }
        
        // Calculate outcome - FIXED: Need to import BattleCalculator
        // This assumes BattleCalculator is imported and used
        // For now, simplified logic:
        uint256 attackerTotal = 0;
        uint256 defenderTotal = 0;
        
        for (uint256 i = 0; i < attackerPowers.length; i++) {
            attackerTotal += attackerPowers[i];
        }
        for (uint256 i = 0; i < defenderPowers.length; i++) {
            defenderTotal += defenderPowers[i];
        }
        
        address winner;
        uint256 loot = 0;
        
        // Simple battle resolution
        if (attackerTotal > defenderTotal) {
            // Attacker wins
            winner = request.attacker;
            loot = defenderTotal * 20 / 100; // 20% loot
            
            // Transfer territory ownership
            if (territory.owner != address(0)) {
                // Remove from old owner
                uint256[] storage oldOwnerTerr = playerTerritories[territory.owner];
                for (uint256 i = 0; i < oldOwnerTerr.length; i++) {
                    if (oldOwnerTerr[i] == request.territoryId) {
                        oldOwnerTerr[i] = oldOwnerTerr[oldOwnerTerr.length - 1];
                        oldOwnerTerr.pop();
                        break;
                    }
                }
            }
            
            // Transfer to attacker
            territory.owner = request.attacker;
            playerTerritories[request.attacker].push(request.territoryId);
            territory.lastClaimTime = block.timestamp;
            
            // Send loot
            if (loot > 0) {
                (bool success, ) = payable(request.attacker).call{value: loot}("");
                require(success, "Loot transfer failed");
            }
            
        } else {
            // Defender wins
            winner = territory.owner;
        }
        
        request.resolved = true;
        
        emit BattleResolved(battleId, winner, loot);
    }
    
    /**
     * @dev Get tier slots
     */
    function getTierSlots(uint256 tier) public pure returns (uint256) {
        if (tier == 1) return TIER_1_SLOTS;
        if (tier == 2) return TIER_2_SLOTS;
        if (tier == 3) return TIER_3_SLOTS;
        if (tier == 4) return TIER_4_SLOTS;
        if (tier == 5) return TIER_5_SLOTS;
        return 0;
    }
    
    /**
     * @dev Get tier base reward
     */
    function getTierBaseReward(uint256 tier) public pure returns (uint256) {
        if (tier == 1) return TIER_1_BASE_REWARD;
        if (tier == 2) return TIER_2_BASE_REWARD;
        if (tier == 3) return TIER_3_BASE_REWARD;
        if (tier == 4) return TIER_4_BASE_REWARD;
        if (tier == 5) return TIER_5_BASE_REWARD;
        return 0;
    }
    
    /**
     * @dev Get player territories
     */
    function getPlayerTerritories(address player) external view returns (uint256[] memory) {
        return playerTerritories[player];
    }
    
    /**
     * @dev Get territory details
     */
    function getTerritoryDetails(uint256 territoryId) external view returns (
        uint256 tier,
        address owner,
        uint256[] memory stakedAnts,
        uint256 totalPower,
        uint256 unclaimedRewards,
        bool isActive
    ) {
        Territory storage territory = territories[territoryId];
        return (
            territory.tier,
            territory.owner,
            territory.stakedAnts,
            territory.totalPower,
            getUnclaimedRewards(territoryId),
            territory.isActive
        );
    }
    
    // Admin function to create additional territories
    function createTerritory(uint256 tier) external onlyOwner {
        _createTerritory(tier);
    }
    
    // Receive function to accept AVAX
    receive() external payable {}
}