// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IAntNFT
 * @dev Interface for Ant NFT contract
 */
interface IAntNFT {
    // Structs
    struct Ant {
        uint256 dna;
        uint256 level;
        uint256 experience;
        uint256 breedCount;
        uint256 birthTime;
        uint256 lastBreedTime;
        bool isStaked;
        bool isSoulbound;
    }
    
    // Events
    event AntMinted(address indexed owner, uint256 indexed tokenId, uint256 dna, bool isStarter);
    event AntBred(address indexed owner, uint256 indexed parent1, uint256 indexed parent2, uint256 newAntId);
    event AntLeveledUp(uint256 indexed tokenId, uint256 newLevel);
    event AntStaked(uint256 indexed tokenId, address indexed owner);
    event AntUnstaked(uint256 indexed tokenId, address indexed owner);
    event BreedingCostUpdated(uint256 newCost);
    
    // Core Functions
    function mintStarterAnts() external;
    function breedAnts(uint256 parent1Id, uint256 parent2Id) external payable;
    function levelUp(uint256 tokenId) external;
    function addExperience(uint256 tokenId, uint256 amount) external;
    function setStaked(uint256 tokenId, bool staked) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external; // Add burn function
    
    // View Functions
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function getAntPower(uint256 tokenId) external view returns (uint256);
    function getAntDetails(uint256 tokenId) external view returns (
        uint256 dna,
        uint256 level,
        uint256 experience,
        uint256 breedCount,
        uint256 birthTime,
        bool isStaked,
        bool isSoulbound
    );
    function getOwnerAnts(address owner) external view returns (uint256[] memory);
    function hasClaimedStarterAnts(address user) external view returns (bool);
    function isStaked(uint256 tokenId) external view returns (bool);
    
    // Admin Functions
    function setColonyManager(address _colonyManager) external;
    function setTournamentSystem(address _tournamentSystem) external;
    function updateBreedingCost(uint256 newCost) external;
}