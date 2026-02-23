// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title ITournamentSystem
 * @dev Interface for Tournament System contract
 */
interface ITournamentSystem {
    // Enums/Constants
    function TOURNAMENT_DAILY() external view returns (uint8);
    function TOURNAMENT_WEEKLY() external view returns (uint8);
    
    function TIER_ROOKIE() external view returns (uint8);
    function TIER_VETERAN() external view returns (uint8);
    function TIER_ELITE() external view returns (uint8);
    function TIER_BRONZE() external view returns (uint8);
    function TIER_SILVER() external view returns (uint8);
    function TIER_GOLD() external view returns (uint8);
    function TIER_CHAMPIONS() external view returns (uint8);
    
    // Events
    event TournamentCreated(uint256 indexed tournamentId, uint8 tournamentType, uint8 tier, uint256 startTime);
    event TournamentRegistered(address indexed player, uint256 indexed tournamentId, uint256[] antIds);
    event TournamentBattle(uint256 indexed tournamentId, uint256 indexed battleId, address player1, address player2);
    event TournamentBattleResolved(uint256 indexed tournamentId, uint256 indexed battleId, address winner);
    event TournamentFinalized(uint256 indexed tournamentId, address[] winners, uint256[] prizes);
    event TournamentPrizeClaimed(address indexed player, uint256 indexed tournamentId, uint256 amount);
    
    // Core Functions
    function createTournament(uint8 tournamentType, uint8 tier, uint256 startTime, uint256 duration) external;
    function registerForTournament(uint256 tournamentId, uint256[] calldata antIds) external payable;
    function startTournament(uint256 tournamentId) external;
    function resolveBattle(uint256 tournamentId, uint256 battleIndex) external;
    function finalizeTournament(uint256 tournamentId) external;
    
    // View Functions
    function getTournamentDetails(uint256 tournamentId) external view returns (
        uint8 tournamentType,
        uint8 tier,
        uint256 startTime,
        uint256 endTime,
        uint256 entryFee,
        uint256 maxPlayers,
        uint256 registeredCount,
        bool finalized
    );
    function getPlayerTournaments(address player) external view returns (uint256[] memory);
    function tournamentWins(address player) external view returns (uint256);
    function totalEarnings(address player) external view returns (uint256);
    
    // Admin Functions
    function setDailyEntryFee(uint8 tier, uint256 fee) external;
    function setWeeklyEntryFee(uint8 tier, uint256 fee) external;
    function setDailyHNYReward(uint8 tier, uint256 reward) external;
    function setWeeklyHNYReward(uint8 tier, uint256 reward) external;
    function setMaxPlayers(uint8 tournamentType, uint8 tier, uint256 max) external;
}