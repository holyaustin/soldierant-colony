// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IAntNFT.sol";
import "../interfaces/IColonyManager.sol";
import "../tokens/HoneyDewToken.sol";

/**
 * @title TournamentSystem
 * @dev Manages daily and weekly tournaments with multiple tiers
 * Compatible with OpenZeppelin 5.0 (Counters.sol removed)
 */
contract TournamentSystem is Ownable, ReentrancyGuard {
    // Tournament types
    uint8 public constant TOURNAMENT_DAILY = 0;
    uint8 public constant TOURNAMENT_WEEKLY = 1;
    
    // Tournament tiers
    uint8 public constant TIER_ROOKIE = 0;
    uint8 public constant TIER_VETERAN = 1;
    uint8 public constant TIER_ELITE = 2;
    uint8 public constant TIER_BRONZE = 3;
    uint8 public constant TIER_SILVER = 4;
    uint8 public constant TIER_GOLD = 5;
    uint8 public constant TIER_CHAMPIONS = 6;
    
    // Tournament entry fees (AVAX)
    mapping(uint8 => uint256) public dailyEntryFees;
    mapping(uint8 => uint256) public weeklyEntryFees;
    
    // Tournament HNY rewards
    mapping(uint8 => uint256) public dailyHNYRewards;
    mapping(uint8 => uint256) public weeklyHNYRewards;
    
    // Tournament max players
    mapping(uint8 => uint256) public dailyMaxPlayers;
    mapping(uint8 => uint256) public weeklyMaxPlayers;
    
    // Tournament prize distribution percentages (basis points - 100 = 1%)
    uint256[] public prizeDistribution = [3500, 2000, 1000, 1000, 500, 500, 500, 250, 250, 250, 250]; // In basis points
    
    // Structs
    struct Tournament {
        uint256 id;
        uint8 tournamentType;
        uint8 tier;
        uint256 startTime;
        uint256 endTime;
        uint256 entryFee;
        uint256 hnyReward;
        uint256 maxPlayers;
        uint256 registeredCount;
        bool finalized;
    }
    
    struct Battle {
        uint256 id;
        uint256 tournamentId;
        address player1;
        address player2;
        uint256[] player1Ants;
        uint256[] player2Ants;
        address winner;
        bool resolved;
    }
    
    struct TournamentRegistration {
        address player;
        uint256[] antIds;
        uint256 registrationTime;
    }
    
    // State variables
    uint256 private _nextTournamentId = 1;
    uint256 private _nextBattleId = 1;
    
    // Tournament data
    mapping(uint256 => Tournament) public tournaments;
    mapping(uint256 => TournamentRegistration[]) public tournamentRegistrations;
    mapping(uint256 => mapping(address => bool)) public isRegistered;
    mapping(uint256 => mapping(address => uint256[])) public playerAnts;
    mapping(uint256 => Battle[]) public tournamentBattles;
    
    // Player tracking
    mapping(address => mapping(uint8 => uint256)) public lastTournamentEntry;
    mapping(address => uint256) public tournamentWins;
    mapping(address => uint256) public totalEarnings;
    
    // Contract references - Store as addresses
    address private _antNFTAddress;
    address private _hnyTokenAddress;
    address private _colonyManagerAddress;
    
    // Events
    event TournamentCreated(uint256 indexed tournamentId, uint8 tournamentType, uint8 tier, uint256 startTime);
    event TournamentRegistered(address indexed player, uint256 indexed tournamentId, uint256[] antIds);
    event TournamentBattle(uint256 indexed tournamentId, uint256 indexed battleId, address player1, address player2);
    event TournamentBattleResolved(uint256 indexed tournamentId, uint256 indexed battleId, address winner);
    event TournamentFinalized(uint256 indexed tournamentId, address[] winners, uint256[] prizes);
    event TournamentPrizeClaimed(address indexed player, uint256 indexed tournamentId, uint256 amount);
    
    constructor(address antNFT_, address hnyToken_, address colonyManager_) Ownable(msg.sender) {
        _antNFTAddress = antNFT_;
        _hnyTokenAddress = hnyToken_;
        _colonyManagerAddress = colonyManager_;
        
        // Initialize daily tournament fees
        dailyEntryFees[TIER_ROOKIE] = 0.1 ether;
        dailyEntryFees[TIER_VETERAN] = 0.2 ether;
        dailyEntryFees[TIER_ELITE] = 0.5 ether;
        
        // Initialize weekly tournament fees
        weeklyEntryFees[TIER_BRONZE] = 0.5 ether;
        weeklyEntryFees[TIER_SILVER] = 1 ether;
        weeklyEntryFees[TIER_GOLD] = 2 ether;
        weeklyEntryFees[TIER_CHAMPIONS] = 5 ether;
        
        // Initialize daily HNY rewards
        dailyHNYRewards[TIER_ROOKIE] = 100 * 10**18;
        dailyHNYRewards[TIER_VETERAN] = 200 * 10**18;
        dailyHNYRewards[TIER_ELITE] = 300 * 10**18;
        
        // Initialize weekly HNY rewards
        weeklyHNYRewards[TIER_BRONZE] = 400 * 10**18;
        weeklyHNYRewards[TIER_SILVER] = 500 * 10**18;
        weeklyHNYRewards[TIER_GOLD] = 600 * 10**18;
        weeklyHNYRewards[TIER_CHAMPIONS] = 700 * 10**18;
        
        // Initialize max players
        dailyMaxPlayers[TIER_ROOKIE] = 200;
        dailyMaxPlayers[TIER_VETERAN] = 100;
        dailyMaxPlayers[TIER_ELITE] = 50;
        
        weeklyMaxPlayers[TIER_BRONZE] = 500;
        weeklyMaxPlayers[TIER_SILVER] = 250;
        weeklyMaxPlayers[TIER_GOLD] = 100;
        weeklyMaxPlayers[TIER_CHAMPIONS] = 50;
    }
    
    /**
     * @dev Get AntNFT contract instance
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
     * @dev Get ColonyManager contract instance
     */
    function colonyManager() public view returns (IColonyManager) {
        return IColonyManager(_colonyManagerAddress);
    }
    
    /**
     * @dev Create a new tournament (admin or automated)
     */
    function createTournament(
        uint8 tournamentType,
        uint8 tier,
        uint256 startTime,
        uint256 duration
    ) external onlyOwner {
        require(tournamentType == TOURNAMENT_DAILY || tournamentType == TOURNAMENT_WEEKLY, "Invalid type");
        require(startTime > block.timestamp, "Start time must be in future");
        require(duration > 0, "Duration must be positive");
        
        uint256 tournamentId = _nextTournamentId;
        _nextTournamentId++;
        
        Tournament storage t = tournaments[tournamentId];
        t.id = tournamentId;
        t.tournamentType = tournamentType;
        t.tier = tier;
        t.startTime = startTime;
        t.endTime = startTime + duration;
        
        if (tournamentType == TOURNAMENT_DAILY) {
            t.entryFee = dailyEntryFees[tier];
            t.hnyReward = dailyHNYRewards[tier];
            t.maxPlayers = dailyMaxPlayers[tier];
        } else {
            t.entryFee = weeklyEntryFees[tier];
            t.hnyReward = weeklyHNYRewards[tier];
            t.maxPlayers = weeklyMaxPlayers[tier];
        }
        
        emit TournamentCreated(tournamentId, tournamentType, tier, startTime);
    }
    
    /**
     * @dev Register for tournament
     * @param tournamentId Tournament ID
     * @param antIds Array of ant token IDs to use in tournament
     */
    function registerForTournament(uint256 tournamentId, uint256[] calldata antIds) external payable nonReentrant {
        Tournament storage t = tournaments[tournamentId];
        require(t.id != 0, "Tournament does not exist");
        require(block.timestamp < t.startTime, "Registration closed");
        require(t.registeredCount < t.maxPlayers, "Tournament full");
        require(antIds.length == 5, "Must register exactly 5 ants");
        require(msg.value >= t.entryFee, "Insufficient entry fee");
        require(!isRegistered[tournamentId][msg.sender], "Already registered");
        
        // Check cooldown (12h between same tier)
        require(
            block.timestamp >= lastTournamentEntry[msg.sender][t.tier] + 12 hours,
            "Tournament cooldown"
        );
        
        // Verify ant ownership and availability
        for (uint256 i = 0; i < antIds.length; i++) {
            require(antNFT().ownerOf(antIds[i]) == msg.sender, "Not owner of ant");
            require(!antNFT().isStaked(antIds[i]), "Ant is staked");
            require(!isAntInTournament(antIds[i], tournamentId), "Ant already in tournament");
        }
        
        // Store registration
        isRegistered[tournamentId][msg.sender] = true;
        playerAnts[tournamentId][msg.sender] = antIds;
        t.registeredCount++;
        
        tournamentRegistrations[tournamentId].push(TournamentRegistration({
            player: msg.sender,
            antIds: antIds,
            registrationTime: block.timestamp
        }));
        
        lastTournamentEntry[msg.sender][t.tier] = block.timestamp;
        
        // Refund excess payment
        if (msg.value > t.entryFee) {
            (bool refundSuccess, ) = payable(msg.sender).call{value: msg.value - t.entryFee}("");
            require(refundSuccess, "Refund failed");
        }
        
        emit TournamentRegistered(msg.sender, tournamentId, antIds);
    }
    
    /**
     * @dev Check if ant is already in a tournament
     */
    function isAntInTournament(uint256 antId, uint256 tournamentId) internal view returns (bool) {
        TournamentRegistration[] storage registrations = tournamentRegistrations[tournamentId];
        for (uint256 i = 0; i < registrations.length; i++) {
            uint256[] storage antIds = registrations[i].antIds;
            for (uint256 j = 0; j < antIds.length; j++) {
                if (antIds[j] == antId) return true;
            }
        }
        return false;
    }
    
    /**
     * @dev Start tournament matches (called after registration closes)
     */
    function startTournament(uint256 tournamentId) external onlyOwner {
        Tournament storage t = tournaments[tournamentId];
        require(t.id != 0, "Tournament does not exist");
        require(block.timestamp >= t.startTime, "Tournament not started");
        require(t.registeredCount > 0, "No participants");
        require(tournamentBattles[tournamentId].length == 0, "Tournament already started");
        
        // Get all players
        address[] memory players = new address[](tournamentRegistrations[tournamentId].length);
        for (uint256 i = 0; i < tournamentRegistrations[tournamentId].length; i++) {
            players[i] = tournamentRegistrations[tournamentId][i].player;
        }
        
        // Simple shuffle (Fisher-Yates)
        for (uint256 i = players.length; i > 1; i--) {
            uint256 j = uint256(keccak256(abi.encodePacked(block.timestamp, i))) % i;
            (players[i-1], players[j]) = (players[j], players[i-1]);
        }
        
        // Create battles (single elimination)
        for (uint256 i = 0; i < players.length; i += 2) {
            if (i + 1 < players.length) {
                uint256 battleId = _nextBattleId;
                _nextBattleId++;
                
                Battle memory battle = Battle({
                    id: battleId,
                    tournamentId: tournamentId,
                    player1: players[i],
                    player2: players[i + 1],
                    player1Ants: playerAnts[tournamentId][players[i]],
                    player2Ants: playerAnts[tournamentId][players[i + 1]],
                    winner: address(0),
                    resolved: false
                });
                
                tournamentBattles[tournamentId].push(battle);
                
                emit TournamentBattle(tournamentId, battleId, players[i], players[i + 1]);
            }
            // If odd number, player gets bye (automatically advances)
        }
    }
    
    /**
     * @dev Resolve a tournament battle
     */
    function resolveBattle(uint256 tournamentId, uint256 battleIndex) external nonReentrant {
        require(battleIndex < tournamentBattles[tournamentId].length, "Battle does not exist");
        
        Battle storage battle = tournamentBattles[tournamentId][battleIndex];
        require(!battle.resolved, "Battle already resolved");
        require(battle.player1 != address(0) && battle.player2 != address(0), "Invalid battle");
        
        // Get ant powers
        uint256 player1Total = 0;
        uint256 player2Total = 0;
        
        for (uint256 i = 0; i < battle.player1Ants.length; i++) {
            player1Total += antNFT().getAntPower(battle.player1Ants[i]);
        }
        
        for (uint256 i = 0; i < battle.player2Ants.length; i++) {
            player2Total += antNFT().getAntPower(battle.player2Ants[i]);
        }
        
        // Determine winner (with small randomness factor)
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, battle.id))) % 100;
        uint256 player1Adjusted = player1Total * (100 + (random % 10)) / 100;
        uint256 player2Adjusted = player2Total * (100 + ((random + 50) % 10)) / 100;
        
        if (player1Adjusted > player2Adjusted) {
            battle.winner = battle.player1;
        } else if (player2Adjusted > player1Adjusted) {
            battle.winner = battle.player2;
        } else {
            // True tie - random winner
            battle.winner = (random % 2 == 0) ? battle.player1 : battle.player2;
        }
        
        battle.resolved = true;
        
        // Add experience to winner's ants
        uint256[] memory winnerAnts = (battle.winner == battle.player1) ? battle.player1Ants : battle.player2Ants;
        for (uint256 i = 0; i < winnerAnts.length; i++) {
            antNFT().addExperience(winnerAnts[i], 10);
        }
        
        tournamentWins[battle.winner]++;
        
        emit TournamentBattleResolved(tournamentId, battle.id, battle.winner);
    }
    
    /**
     * @dev Finalize tournament and distribute prizes
     */
    function finalizeTournament(uint256 tournamentId) external onlyOwner nonReentrant {
        Tournament storage t = tournaments[tournamentId];
        require(t.id != 0, "Tournament does not exist");
        require(block.timestamp >= t.endTime, "Tournament not ended");
        require(!t.finalized, "Already finalized");
        
        // Calculate prize pool
        uint256 totalEntryFees = t.entryFee * t.registeredCount;
        uint256 gameCut = (t.tournamentType == TOURNAMENT_DAILY) 
            ? totalEntryFees * 20 / 100 
            : totalEntryFees * 15 / 100;
        uint256 prizePool = totalEntryFees - gameCut;
        
        // Mint HNY rewards to this contract first - FIXED: Use payable conversion
        if (t.hnyReward > 0) {
            HoneyDewToken(payable(_hnyTokenAddress)).mintReward(address(this), t.hnyReward);
        }
        
        // Get winners (simplified - just get all participants for now)
        address[] memory winners = new address[](t.registeredCount);
        for (uint256 i = 0; i < tournamentRegistrations[tournamentId].length; i++) {
            winners[i] = tournamentRegistrations[tournamentId][i].player;
        }
        
        uint256[] memory prizes = new uint256[](winners.length);
        
        for (uint256 i = 0; i < winners.length && i < prizeDistribution.length; i++) {
            uint256 avaxPrize = (prizePool * prizeDistribution[i]) / 10000; // Convert basis points to percent
            uint256 hnyPrize = (t.hnyReward * prizeDistribution[i]) / 10000;
            
            prizes[i] = avaxPrize;
            
            // Send AVAX prize
            if (avaxPrize > 0) {
                (bool success, ) = payable(winners[i]).call{value: avaxPrize}("");
                require(success, "AVAX prize transfer failed");
            }
            
            // Send HNY prize - FIXED: Transfer HNY tokens using IERC20
            if (hnyPrize > 0) {
                require(IERC20(_hnyTokenAddress).transfer(winners[i], hnyPrize), "HNY transfer failed");
            }
            
            totalEarnings[winners[i]] += avaxPrize;
            
            emit TournamentPrizeClaimed(winners[i], tournamentId, avaxPrize);
        }
        
        t.finalized = true;
        
        emit TournamentFinalized(tournamentId, winners, prizes);
    }
    
    /**
     * @dev Get player tournament history
     */
    function getPlayerTournaments(address player) external view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](_nextTournamentId - 1);
        uint256 count = 0;
        
        for (uint256 i = 1; i < _nextTournamentId; i++) {
            if (isRegistered[i][player]) {
                result[count] = i;
                count++;
            }
        }
        
        // Resize array
        uint256[] memory trimmed = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            trimmed[i] = result[i];
        }
        
        return trimmed;
    }
    
    /**
     * @dev Get tournament details
     */
    function getTournamentDetails(uint256 tournamentId) external view returns (
        uint8 tournamentType,
        uint8 tier,
        uint256 startTime,
        uint256 endTime,
        uint256 entryFee,
        uint256 maxPlayers,
        uint256 registeredCount,
        bool finalized
    ) {
        Tournament storage t = tournaments[tournamentId];
        require(t.id != 0, "Tournament does not exist");
        
        return (
            t.tournamentType,
            t.tier,
            t.startTime,
            t.endTime,
            t.entryFee,
            t.maxPlayers,
            t.registeredCount,
            t.finalized
        );
    }
    
    // Admin functions to update fees
    function setDailyEntryFee(uint8 tier, uint256 fee) external onlyOwner {
        dailyEntryFees[tier] = fee;
    }
    
    function setWeeklyEntryFee(uint8 tier, uint256 fee) external onlyOwner {
        weeklyEntryFees[tier] = fee;
    }
    
    function setDailyHNYReward(uint8 tier, uint256 reward) external onlyOwner {
        dailyHNYRewards[tier] = reward;
    }
    
    function setWeeklyHNYReward(uint8 tier, uint256 reward) external onlyOwner {
        weeklyHNYRewards[tier] = reward;
    }
    
    function setMaxPlayers(uint8 tournamentType, uint8 tier, uint256 max) external onlyOwner {
        if (tournamentType == TOURNAMENT_DAILY) {
            dailyMaxPlayers[tier] = max;
        } else {
            weeklyMaxPlayers[tier] = max;
        }
    }
    
    // Receive function to accept AVAX
    receive() external payable {}
}