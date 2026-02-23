// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title HoneyDewToken
 * @dev ERC20 token for Soldier Ant Colony in-game economy
 * Fixed supply of 50,000,000 tokens with gradual emission
 * Implements burn mechanisms and conversion limits
 */
contract HoneyDewToken is ERC20, ERC20Burnable, Ownable, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 50_000_000 * 10**18;
    uint256 public constant DAILY_CONVERSION_LIMIT = 5_000 * 10**18;
    uint256 public constant MONTHLY_CONVERSION_LIMIT = 50_000 * 10**18;
    uint256 public constant CONVERSION_FEE_BPS = 1000; // 10% (1000 basis points)
    
    // Conversion tracking
    mapping(address => uint256) public dailyConverted;
    mapping(address => uint256) public monthlyConverted;
    mapping(address => uint256) public lastDailyReset;
    mapping(address => uint256) public lastMonthlyReset;
    
    // Emission schedule
    uint256 public emissionStartTime;
    uint256 public constant YEAR_1_DAILY = 34_000 * 10**18;
    uint256 public constant YEAR_2_DAILY = 28_000 * 10**18;
    uint256 public constant YEAR_3_DAILY = 22_000 * 10**18;
    uint256 public constant YEAR_4_DAILY = 16_000 * 10**18;
    uint256 public constant YEAR_5_DAILY = 10_000 * 10**18;
    
    uint256 public lastEmissionTime;
    uint256 public emittedSupply;
    
    // Events
    event ConvertedToAVAX(address indexed user, uint256 hnyAmount, uint256 avaxAmount, uint256 fee);
    event TokensBurned(address indexed burner, uint256 amount);
    event EmissionUpdated(uint256 timestamp, uint256 amount);
    
    constructor() ERC20("HoneyDew Token", "SHNY") Ownable(msg.sender) {
        emissionStartTime = block.timestamp;
        lastEmissionTime = block.timestamp;
        _mint(address(this), MAX_SUPPLY); // Mint all tokens to contract for controlled emission
    }
    
    /**
     * @dev Modifier to reset daily limits
     */
    modifier resetDailyLimit(address user) {
        if (block.timestamp > lastDailyReset[user] + 1 days) {
            dailyConverted[user] = 0;
            lastDailyReset[user] = block.timestamp;
        }
        _;
    }
    
    /**
     * @dev Modifier to reset monthly limits
     */
    modifier resetMonthlyLimit(address user) {
        if (block.timestamp > lastMonthlyReset[user] + 30 days) {
            monthlyConverted[user] = 0;
            lastMonthlyReset[user] = block.timestamp;
        }
        _;
    }
    
    /**
     * @dev Emit tokens according to schedule
     * Can be called by anyone to trigger emission
     */
    function emitDailyTokens() external nonReentrant {
        require(block.timestamp >= lastEmissionTime + 1 days, "Emission too frequent");
        require(emittedSupply < MAX_SUPPLY, "Max supply reached");
        
        uint256 dailyAmount = getCurrentDailyEmission();
        uint256 actualEmission = dailyAmount;
        
        // Check if we would exceed max supply
        if (emittedSupply + dailyAmount > MAX_SUPPLY) {
            actualEmission = MAX_SUPPLY - emittedSupply;
        }
        
        emittedSupply += actualEmission;
        lastEmissionTime = block.timestamp;
        
        // Transfer from contract to reward pool (can be optimized with minter role)
        _transfer(address(this), owner(), actualEmission);
        
        emit EmissionUpdated(block.timestamp, actualEmission);
    }
    
    /**
     * @dev Get current daily emission based on year
     */
    function getCurrentDailyEmission() public view returns (uint256) {
        uint256 yearsPassed = (block.timestamp - emissionStartTime) / 365 days;
        
        if (yearsPassed == 0) return YEAR_1_DAILY;
        if (yearsPassed == 1) return YEAR_2_DAILY;
        if (yearsPassed == 2) return YEAR_3_DAILY;
        if (yearsPassed == 3) return YEAR_4_DAILY;
        return YEAR_5_DAILY;
    }
    
    /**
     * @dev Convert SHNY to AVAX with fee and limits
     * @param amount Amount of SHNY to convert
     */
    function convertToAVAX(uint256 amount) 
        external 
        nonReentrant 
        resetDailyLimit(msg.sender)
        resetMonthlyLimit(msg.sender)
    {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        
        // Check daily limit
        require(dailyConverted[msg.sender] + amount <= DAILY_CONVERSION_LIMIT, "Daily limit exceeded");
        
        // Check monthly limit
        require(monthlyConverted[msg.sender] + amount <= MONTHLY_CONVERSION_LIMIT, "Monthly limit exceeded");
        
        // Calculate fee and AVAX amount (1,000 SHNY = 0.01 AVAX fixed rate for simplicity)
        uint256 avaxAmount = (amount * 1e16) / 1e21; // (amount * 0.01) / 1000
        uint256 fee = (avaxAmount * CONVERSION_FEE_BPS) / 10000;
        uint256 userAvax = avaxAmount - fee;
        
        // Update limits
        dailyConverted[msg.sender] += amount;
        monthlyConverted[msg.sender] += amount;
        
        // Burn the SHNY tokens
        _burn(msg.sender, amount);
        
        // Send AVAX to user
        (bool success, ) = payable(msg.sender).call{value: userAvax}("");
        require(success, "AVAX transfer failed");
        
        emit ConvertedToAVAX(msg.sender, amount, userAvax, fee);
        emit TokensBurned(msg.sender, amount);
    }
    
    /**
     * @dev Mint tokens (only owner for rewards distribution)
     */
    function mintReward(address to, uint256 amount) external onlyOwner {
        require(emittedSupply + amount <= MAX_SUPPLY, "Exceeds max supply");
        _mint(to, amount);
    }
    
    // Receive function to accept AVAX
    receive() external payable {}
}