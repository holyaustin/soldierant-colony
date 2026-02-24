// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../libraries/AntGenetics.sol";
import "../libraries/AntUtils.sol";

/**
 * @title AntNFT
 * @dev NFT contract for Soldier Ant Colony ants
 * SIMPLIFIED: No interface inheritance - just pure ERC721
 */
contract AntNFT is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using AntGenetics for uint256;
    
    uint256 private _nextTokenId = 1;
    
    // Constants
    uint256 public constant BREEDING_COST = 0.1 ether;
    uint256 public constant BREEDING_FEE_BPS = 500;
    uint256 public constant MAX_BREEDING_ATTEMPTS = 10;
    uint256 public constant MAX_LEVEL = 10;
    uint256 public constant STARTER_ANT_COUNT = 3;
    
    struct AntData {
        uint256 dna;
        uint256 level;
        uint256 experience;
        uint256 breedCount;
        uint256 birthTime;
        uint256 lastBreedTime;
        bool staked;
        bool soulbound;
    }
    
    mapping(uint256 => AntData) private _ants;
    mapping(address => bool) public hasClaimedStarter;
    mapping(address => uint256[]) private _ownerAnts;
    
    address private _colonyManager;
    address private _tournamentSystem;
    
    // Events
    event AntMinted(address indexed owner, uint256 indexed tokenId, uint256 dna, bool isStarter);
    event AntBred(address indexed owner, uint256 indexed parent1, uint256 indexed parent2, uint256 newAntId);
    event AntLeveledUp(uint256 indexed tokenId, uint256 newLevel);
    event AntStaked(uint256 indexed tokenId, address indexed owner);
    event AntUnstaked(uint256 indexed tokenId, address indexed owner);
    event BreedingCostUpdated(uint256 newCost);
    
    // Custom errors
    error AlreadyClaimed();
    error Unauthorized();
    error InvalidAddress();
    error AntNotFound();
    error NotOwner();
    error MaxLevel();
    error InsufficientXP();
    
    constructor() ERC721("Soldier Ant", "SANT") Ownable(msg.sender) {}
    
    modifier onlyColonyOrOwner() {
        if (msg.sender != _colonyManager && msg.sender != owner()) revert Unauthorized();
        _;
    }
    
    modifier onlyGameContracts() {
        if (msg.sender != _colonyManager && msg.sender != _tournamentSystem && msg.sender != owner()) {
            revert Unauthorized();
        }
        _;
    }
    
    // ========== View Functions ==========
    
    function getColonyManager() external view returns (address) {
        return _colonyManager;
    }
    
    function getTournamentSystem() external view returns (address) {
        return _tournamentSystem;
    }
    
    function getAntPower(uint256 tokenId) external view returns (uint256) {
        AntData storage ant = _ants[tokenId];
        if (ant.birthTime == 0) revert AntNotFound();
        return ant.dna.calculatePower(ant.level);
    }
    
    function getAntDetails(uint256 tokenId) external view returns (
        uint256 dna,
        uint256 level,
        uint256 experience,
        uint256 breedCount,
        uint256 birthTime,
        bool staked,
        bool soulbound
    ) {
        AntData storage ant = _ants[tokenId];
        if (ant.birthTime == 0) revert AntNotFound();
        return (
            ant.dna,
            ant.level,
            ant.experience,
            ant.breedCount,
            ant.birthTime,
            ant.staked,
            ant.soulbound
        );
    }
    
    function getOwnerAnts(address owner) external view returns (uint256[] memory) {
        return _ownerAnts[owner];
    }
    
    function hasClaimedStarterAnts(address user) external view returns (bool) {
        return hasClaimedStarter[user];
    }
    
    function isStaked(uint256 tokenId) external view returns (bool) {
        if (_ants[tokenId].birthTime == 0) revert AntNotFound();
        return _ants[tokenId].staked;
    }
    
    // ========== Admin Functions ==========
    
    function setColonyManager(address manager) external onlyOwner {
        if (manager == address(0)) revert InvalidAddress();
        _colonyManager = manager;
    }
    
    function setTournamentSystem(address system) external onlyOwner {
        if (system == address(0)) revert InvalidAddress();
        _tournamentSystem = system;
    }
    
    // ========== Minting Functions ==========
    
    function _mintAnt(address to, bool soulbound) private returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        uint256 dna = AntGenetics.generateRandomDNA(tokenId, block.timestamp, tokenId);
        
        _ants[tokenId] = AntData({
            dna: dna,
            level: 1,
            experience: 0,
            breedCount: 0,
            birthTime: block.timestamp,
            lastBreedTime: 0,
            staked: false,
            soulbound: soulbound
        });
        
        _safeMint(to, tokenId);
        _ownerAnts[to].push(tokenId);
        
        emit AntMinted(to, tokenId, dna, soulbound);
        return tokenId;
    }
    
    function mintStarterAnts() external nonReentrant {
        if (hasClaimedStarter[msg.sender]) revert AlreadyClaimed();
        
        for (uint256 i = 0; i < STARTER_ANT_COUNT; i++) {
            _mintAnt(msg.sender, true);
        }
        
        hasClaimedStarter[msg.sender] = true;
    }
    
    function mintStarterAntsForPlayer(address player) external onlyColonyOrOwner nonReentrant {
        for (uint256 i = 0; i < STARTER_ANT_COUNT; i++) {
            _mintAnt(player, true);
        }
    }
    
    // ========== Breeding ==========
    
    function breedAnts(uint256 parent1, uint256 parent2) external payable nonReentrant {
        AntData storage ant1 = _ants[parent1];
        AntData storage ant2 = _ants[parent2];
        
        if (ant1.birthTime == 0 || ant2.birthTime == 0) revert AntNotFound();
        if (ant1.staked || ant2.staked) revert AntUtils.AntStaked();
        if (ownerOf(parent1) != msg.sender || ownerOf(parent2) != msg.sender) revert NotOwner();
        
        // Validate breeding using library
        AntUtils.validateBreeding(
            parent1, parent2,
            msg.sender, msg.sender, msg.sender,
            ant1.breedCount, ant2.breedCount,
            ant1.lastBreedTime, ant2.lastBreedTime,
            ant1.soulbound, ant2.soulbound,
            MAX_BREEDING_ATTEMPTS, 7 days,
            msg.value, BREEDING_COST
        );
        
        // Calculate fees - FIXED: Use comma for fee variable
        (, uint256 remainder) = AntUtils.calculateFees(msg.value, BREEDING_FEE_BPS);
        
        // Update parent states
        ant1.breedCount++;
        ant2.breedCount++;
        ant1.lastBreedTime = block.timestamp;
        ant2.lastBreedTime = block.timestamp;
        
        // Create new ant
        uint256 newDna = AntGenetics.mixDNA(ant1.dna, ant2.dna, block.timestamp, _nextTokenId);
        uint256 newTokenId = _nextTokenId++;
        
        _ants[newTokenId] = AntData({
            dna: newDna,
            level: 1,
            experience: 0,
            breedCount: 0,
            birthTime: block.timestamp,
            lastBreedTime: 0,
            staked: false,
            soulbound: false
        });
        
        _safeMint(msg.sender, newTokenId);
        _ownerAnts[msg.sender].push(newTokenId);
        
        // Distribute remainder
        if (remainder > 0) {
            address parent1Owner = ownerOf(parent1);
            address parent2Owner = ownerOf(parent2);
            
            if (parent1Owner != address(0)) {
                (bool success,) = payable(parent1Owner).call{value: remainder / 2}("");
                if (!success) revert AntUtils.TransferFailed();
            }
            if (parent2Owner != address(0)) {
                (bool success,) = payable(parent2Owner).call{value: remainder / 2}("");
                if (!success) revert AntUtils.TransferFailed();
            }
        }
        
        emit AntBred(msg.sender, parent1, parent2, newTokenId);
    }
    
    // ========== Leveling ==========
    
    function levelUp(uint256 tokenId) external nonReentrant {
        AntData storage ant = _ants[tokenId];
        if (ant.birthTime == 0) revert AntNotFound();
        if (ant.staked) revert AntUtils.AntStaked();
        if (ownerOf(tokenId) != msg.sender) revert NotOwner();
        if (ant.level >= MAX_LEVEL) revert MaxLevel();
        
        uint256 requiredXP = 100 * (ant.level ** 2);
        if (ant.experience < requiredXP) revert InsufficientXP();
        
        ant.experience -= requiredXP;
        ant.level++;
        
        emit AntLeveledUp(tokenId, ant.level);
    }
    
    function addExperience(uint256 tokenId, uint256 amount) external onlyGameContracts {
        if (_ants[tokenId].birthTime == 0) revert AntNotFound();
        _ants[tokenId].experience += amount;
    }
    
    // ========== Staking ==========
    
    function setStaked(uint256 tokenId, bool staked) external onlyColonyOrOwner {
        if (_ants[tokenId].birthTime == 0) revert AntNotFound();
        
        _ants[tokenId].staked = staked;
        
        if (staked) {
            emit AntStaked(tokenId, ownerOf(tokenId));
        } else {
            emit AntUnstaked(tokenId, ownerOf(tokenId));
        }
    }
    
    // ========== Burning ==========
    
    function burn(uint256 tokenId) external onlyGameContracts {
        if (_ants[tokenId].birthTime == 0) revert AntNotFound();
        
        address owner = ownerOf(tokenId);
        AntUtils.removeFromArray(_ownerAnts[owner], tokenId);
        
        delete _ants[tokenId];
        _burn(tokenId);
    }
    
    // ========== Metadata ==========
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (_ants[tokenId].birthTime == 0) revert AntNotFound();
        
        AntData storage ant = _ants[tokenId];
        string memory json = string(abi.encodePacked(
            '{"name": "Soldier Ant #', tokenId.toString(), '",',
            '"description": "A unique soldier ant from the colony",',
            '"attributes": [',
            ant.dna.getTraitMetadata(),
            ',{"trait_type":"Level","value":', ant.level.toString(), '}',
            ',{"trait_type":"Experience","value":', ant.experience.toString(), '}',
            ',{"trait_type":"Breed Count","value":', ant.breedCount.toString(), '}',
            ',{"trait_type":"Soulbound","value":', ant.soulbound ? "true" : "false", '}',
            ']}'
        ));
        
        return string(abi.encodePacked("data:application/json;utf8,", json));
    }
    
    // ========== Transfer Hook ==========
    
    function _update(address to, uint256 tokenId, address auth) 
        internal 
        virtual 
        override 
        returns (address) 
    {
        address from = _ownerOf(tokenId);
        
        // Custom soulbound logic
        if (_ants[tokenId].soulbound && to != address(0) && from != address(0)) {
            revert("Soulbound");
        }
        
        // Update ownerAnts mapping on transfer
        if (from != address(0) && from != to) {
            AntUtils.removeFromArray(_ownerAnts[from], tokenId);
        }
        
        if (to != address(0) && to != from) {
            _ownerAnts[to].push(tokenId);
        }
        
        return super._update(to, tokenId, auth);
    }
    
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
}