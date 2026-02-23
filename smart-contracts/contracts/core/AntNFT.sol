// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IAntNFT.sol";
import "../libraries/AntGenetics.sol";

/**
 * @title AntNFT
 * @dev NFT contract for Soldier Ant Colony ants
 * SIMPLIFIED: Pure ERC721 without Enumerable to avoid inheritance conflicts
 */
contract AntNFT is ERC721, Ownable, ReentrancyGuard, IAntNFT {
    using Strings for uint256;
    
    uint256 private _nextTokenId = 1;
    
    // Constants
    uint256 public constant BREEDING_COST = 0.1 ether;
    uint256 public constant BREEDING_FEE_BPS = 500; // 5%
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
    mapping(address => uint256[]) private _ownerAnts; // We'll track this ourselves
    
    address private _colonyManagerAddress;
    address private _tournamentSystemAddress;
    
    constructor() ERC721("Soldier Ant", "SANT") Ownable(msg.sender) {}
    
    modifier antExists(uint256 tokenId) {
        require(_ownerOf(tokenId) != address(0), "Ant does not exist");
        _;
    }
    
    modifier notStaked(uint256 tokenId) {
        require(!_ants[tokenId].staked, "Ant is staked");
        _;
    }
    
    // ========== Core Game Functions ==========
    
    function getColonyManager() public view returns (address) {
        return _colonyManagerAddress;
    }
    
    function getTournamentSystem() public view returns (address) {
        return _tournamentSystemAddress;
    }
    
    function setColonyManager(address _colonyManager) external onlyOwner {
        require(_colonyManager != address(0), "Invalid address");
        _colonyManagerAddress = _colonyManager;
    }
    
    function setTournamentSystem(address _tournamentSystem) external onlyOwner {
        require(_tournamentSystem != address(0), "Invalid address");
        _tournamentSystemAddress = _tournamentSystem;
    }
    
    function mintStarterAnts() external nonReentrant {
        require(!hasClaimedStarter[msg.sender], "Already claimed starter ants");
        
        for (uint256 i = 0; i < STARTER_ANT_COUNT; i++) {
            uint256 tokenId = _nextTokenId;
            _nextTokenId++;
            
            uint256 dna = AntGenetics.generateRandomDNA(tokenId, block.timestamp, i);
            
            _ants[tokenId] = AntData({
                dna: dna,
                level: 1,
                experience: 0,
                breedCount: 0,
                birthTime: block.timestamp,
                lastBreedTime: 0,
                staked: false,
                soulbound: true
            });
            
            _safeMint(msg.sender, tokenId);
            _ownerAnts[msg.sender].push(tokenId);
            
            emit IAntNFT.AntMinted(msg.sender, tokenId, dna, true);
        }
        
        hasClaimedStarter[msg.sender] = true;
    }
    
    function mintStarterAntsForPlayer(address player) external nonReentrant {
        require(msg.sender == _colonyManagerAddress || msg.sender == owner(), "Unauthorized");
        
        for (uint256 i = 0; i < STARTER_ANT_COUNT; i++) {
            uint256 tokenId = _nextTokenId;
            _nextTokenId++;
            
            uint256 dna = AntGenetics.generateRandomDNA(tokenId, block.timestamp, i);
            
            _ants[tokenId] = AntData({
                dna: dna,
                level: 1,
                experience: 0,
                breedCount: 0,
                birthTime: block.timestamp,
                lastBreedTime: 0,
                staked: false,
                soulbound: true
            });
            
            _safeMint(player, tokenId);
            _ownerAnts[player].push(tokenId);
            
            emit IAntNFT.AntMinted(player, tokenId, dna, true);
        }
    }
    
    function breedAnts(uint256 parent1Id, uint256 parent2Id) 
        external 
        payable 
        nonReentrant 
        antExists(parent1Id)
        antExists(parent2Id)
        notStaked(parent1Id)
        notStaked(parent2Id)
    {
        require(msg.value >= BREEDING_COST, "Insufficient AVAX");
        require(ownerOf(parent1Id) == msg.sender, "Not owner of parent1");
        require(ownerOf(parent2Id) == msg.sender, "Not owner of parent2");
        require(parent1Id != parent2Id, "Cannot breed same ant");
        require(_ants[parent1Id].breedCount < MAX_BREEDING_ATTEMPTS, "Parent1 max breeds reached");
        require(_ants[parent2Id].breedCount < MAX_BREEDING_ATTEMPTS, "Parent2 max breeds reached");
        require(block.timestamp >= _ants[parent1Id].lastBreedTime + 7 days, "Parent1 breeding cooldown");
        require(block.timestamp >= _ants[parent2Id].lastBreedTime + 7 days, "Parent2 breeding cooldown");
        require(!_ants[parent1Id].soulbound || _ants[parent1Id].breedCount < 1, "Soulbound can breed once");
        require(!_ants[parent2Id].soulbound || _ants[parent2Id].breedCount < 1, "Soulbound can breed once");
        
        uint256 fee = (msg.value * BREEDING_FEE_BPS) / 10000;
        uint256 remainder = msg.value - fee;
        
        uint256 newDNA = AntGenetics.mixDNA(
            _ants[parent1Id].dna,
            _ants[parent2Id].dna,
            block.timestamp,
            _nextTokenId
        );
        
        _ants[parent1Id].breedCount++;
        _ants[parent2Id].breedCount++;
        _ants[parent1Id].lastBreedTime = block.timestamp;
        _ants[parent2Id].lastBreedTime = block.timestamp;
        
        uint256 newTokenId = _nextTokenId;
        _nextTokenId++;
        
        _ants[newTokenId] = AntData({
            dna: newDNA,
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
        
        if (remainder > 0) {
            address parent1Owner = ownerOf(parent1Id);
            address parent2Owner = ownerOf(parent2Id);
            
            if (parent1Owner != address(0)) {
                (bool success1, ) = payable(parent1Owner).call{value: remainder / 2}("");
                require(success1, "Transfer to parent1 owner failed");
            }
            
            if (parent2Owner != address(0)) {
                (bool success2, ) = payable(parent2Owner).call{value: remainder / 2}("");
                require(success2, "Transfer to parent2 owner failed");
            }
        }
        
        emit IAntNFT.AntBred(msg.sender, parent1Id, parent2Id, newTokenId);
    }
    
    function levelUp(uint256 tokenId) 
        external 
        nonReentrant 
        antExists(tokenId)
        notStaked(tokenId)
    {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        
        AntData storage ant = _ants[tokenId];
        require(ant.level < MAX_LEVEL, "Already max level");
        
        uint256 requiredXP = 100 * (ant.level ** 2);
        require(ant.experience >= requiredXP, "Insufficient experience");
        
        ant.experience -= requiredXP;
        ant.level++;
        
        emit IAntNFT.AntLeveledUp(tokenId, ant.level);
    }
    
    function addExperience(uint256 tokenId, uint256 amount) external {
        require(
            msg.sender == _colonyManagerAddress || 
            msg.sender == _tournamentSystemAddress || 
            msg.sender == owner(),
            "Unauthorized"
        );
        require(_ownerOf(tokenId) != address(0), "Ant does not exist");
        
        _ants[tokenId].experience += amount;
    }
    
    function setStaked(uint256 tokenId, bool staked) external {
        require(
            msg.sender == _colonyManagerAddress || 
            msg.sender == address(this) ||
            owner() == msg.sender,
            "Unauthorized"
        );
        require(_ownerOf(tokenId) != address(0), "Ant does not exist");
        
        _ants[tokenId].staked = staked;
        
        if (staked) {
            emit IAntNFT.AntStaked(tokenId, ownerOf(tokenId));
        } else {
            emit IAntNFT.AntUnstaked(tokenId, ownerOf(tokenId));
        }
    }
    
    function burn(uint256 tokenId) external {
        require(
            msg.sender == _colonyManagerAddress || 
            msg.sender == _tournamentSystemAddress || 
            msg.sender == owner(),
            "Unauthorized"
        );
        require(_ownerOf(tokenId) != address(0), "Ant does not exist");
        
        address owner = ownerOf(tokenId);
        
        // Remove from ownerAnts array
        uint256[] storage ownerAntsList = _ownerAnts[owner];
        for (uint256 i = 0; i < ownerAntsList.length; i++) {
            if (ownerAntsList[i] == tokenId) {
                ownerAntsList[i] = ownerAntsList[ownerAntsList.length - 1];
                ownerAntsList.pop();
                break;
            }
        }
        
        delete _ants[tokenId];
        _burn(tokenId);
    }
    
    function getAntPower(uint256 tokenId) external view returns (uint256) {
        require(_ownerOf(tokenId) != address(0), "Ant does not exist");
        AntData storage ant = _ants[tokenId];
        return AntGenetics.calculatePower(ant.dna, ant.level);
    }
    
    function getAntDetails(uint256 tokenId) 
        external 
        view 
        returns (
            uint256 dna,
            uint256 level,
            uint256 experience,
            uint256 breedCount,
            uint256 birthTime,
            bool stakedStatus,
            bool soulboundStatus
        ) 
    {
        require(_ownerOf(tokenId) != address(0), "Ant does not exist");
        AntData storage ant = _ants[tokenId];
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
        require(_ownerOf(tokenId) != address(0), "Ant does not exist");
        return _ants[tokenId].staked;
    }
    
    function updateBreedingCost(uint256 newCost) external onlyOwner {
        require(newCost > 0, "Cost must be > 0");
        // Note: BREEDING_COST is constant, so this function doesn't actually update it
        // In production, make BREEDING_COST a state variable instead of constant
        emit IAntNFT.BreedingCostUpdated(newCost);
    }
    
    function tokenURI(uint256 tokenId) 
        public 
        view 
        override 
        returns (string memory) 
    {
        require(_ownerOf(tokenId) != address(0), "Ant does not exist");
        
        AntData storage ant = _ants[tokenId];
        
        string memory json = string(abi.encodePacked(
            '{"name": "Soldier Ant #', tokenId.toString(), '",',
            '"description": "A unique soldier ant from the colony",',
            '"attributes": [',
            AntGenetics.getTraitMetadata(ant.dna),
            ',{"trait_type":"Level","value":', ant.level.toString(), '}',
            ',{"trait_type":"Experience","value":', ant.experience.toString(), '}',
            ',{"trait_type":"Breed Count","value":', ant.breedCount.toString(), '}',
            ',{"trait_type":"Soulbound","value":', ant.soulbound ? "true" : "false", '}',
            ']}'
        ));
        
        return string(abi.encodePacked("data:application/json;utf8,", json));
    }
    
    // ========== Transfer Hooks for Tracking ==========
    
    function _update(address to, uint256 tokenId, address auth)
        internal
        virtual
        override
        returns (address)
    {
        address from = _ownerOf(tokenId);
        
        // Custom soulbound logic
        if (_ants[tokenId].soulbound && to != address(0) && from != address(0)) {
            revert("Soulbound tokens cannot be transferred");
        }
        
        // Update ownerAnts mapping on transfer
        if (from != address(0) && from != to) {
            uint256[] storage oldOwnerAnts = _ownerAnts[from];
            for (uint256 i = 0; i < oldOwnerAnts.length; i++) {
                if (oldOwnerAnts[i] == tokenId) {
                    oldOwnerAnts[i] = oldOwnerAnts[oldOwnerAnts.length - 1];
                    oldOwnerAnts.pop();
                    break;
                }
            }
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

    // ========== REQUIRED OVERRIDES FOR MULTIPLE INHERITANCE ==========
// These functions exist in both ERC721 (implementation) and IAntNFT (interface)
// Solidity requires explicit overrides to resolve the ambiguity

/**
 * @dev Override balanceOf to resolve inheritance conflict between ERC721 and IAntNFT
 */
function balanceOf(address owner) 
    public 
    view 
    virtual 
    override(ERC721, IAntNFT) 
    returns (uint256) 
{
    return super.balanceOf(owner);
}

/**
 * @dev Override ownerOf to resolve inheritance conflict between ERC721 and IAntNFT
 */
function ownerOf(uint256 tokenId) 
    public 
    view 
    virtual 
    override(ERC721, IAntNFT) 
    returns (address) 
{
    return super.ownerOf(tokenId);
}

/**
 * @dev Override transferFrom to resolve inheritance conflict between ERC721 and IAntNFT
 */
function transferFrom(address from, address to, uint256 tokenId) 
    public 
    virtual 
    override(ERC721, IAntNFT) 
{
    super.transferFrom(from, to, tokenId);
}
}