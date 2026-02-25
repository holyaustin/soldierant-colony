// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Test.sol";
import "../../contracts/core/AntNFT.sol";
import "../../contracts/libraries/AntGenetics.sol";
import "../../contracts/libraries/AntUtils.sol";

contract AntNFTTest is Test {
    AntNFT public antNFT;
    address public owner;
    address public user1;
    address public user2;
    address public colonyManager;
    address public tournamentSystem;
    
    // Define error selectors for testing
    bytes4 constant ALREADY_CLAIMED_SELECTOR = 0x8cf6e862; // keccak256("AlreadyClaimed()")
    bytes4 constant UNAUTHORIZED_SELECTOR = 0x82b42900; // keccak256("Unauthorized()")
    bytes4 constant INVALID_ADDRESS_SELECTOR = 0xe6d424fb; // keccak256("InvalidAddress()")
    bytes4 constant ANT_NOT_FOUND_SELECTOR = 0x58b629b1; // keccak256("AntNotFound()")
    bytes4 constant NOT_OWNER_SELECTOR = 0x30cd7471; // keccak256("NotOwner()")
    bytes4 constant MAX_LEVEL_SELECTOR = 0xa88f8714; // keccak256("MaxLevel()")
    bytes4 constant INSUFFICIENT_XP_SELECTOR = 0x2fbcbd34; // keccak256("InsufficientXP()")
    
    // AntUtils error selectors
    bytes4 constant ANT_STAKED_SELECTOR = 0x218c4e6f; // keccak256("AntStaked()")
    bytes4 constant INSUFFICIENT_PAYMENT_SELECTOR = 0xcd1c8867; // keccak256("InsufficientPayment()")
    bytes4 constant BREEDING_COOLDOWN_ACTIVE_SELECTOR = 0xb3b20e8d; // keccak256("BreedingCooldownActive()")
    bytes4 constant TRANSFER_FAILED_SELECTOR = 0x90b8ec18; // keccak256("TransferFailed()")
    
    event AntMinted(address indexed owner, uint256 indexed tokenId, uint256 dna, bool isStarter);
    event AntBred(address indexed owner, uint256 indexed parent1, uint256 indexed parent2, uint256 newAntId);
    event AntLeveledUp(uint256 indexed tokenId, uint256 newLevel);
    event AntStaked(uint256 indexed tokenId, address indexed owner);
    event AntUnstaked(uint256 indexed tokenId, address indexed owner);
    
    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        colonyManager = makeAddr("colonyManager");
        tournamentSystem = makeAddr("tournamentSystem");
        
        antNFT = new AntNFT();
        
        // Set up authorized contracts
        antNFT.setColonyManager(colonyManager);
        antNFT.setTournamentSystem(tournamentSystem);
        
        // Deal ETH for breeding
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }
    
    // ========== Starter Ant Tests ==========
    
    function test_MintStarterAnts() public {
        vm.prank(user1);
        vm.expectEmit(true, true, true, true);
        emit AntMinted(user1, 1, 0, true); // DNA will be generated, we can't predict it exactly
        antNFT.mintStarterAnts();
        
        assertEq(antNFT.balanceOf(user1), 3);
        assertTrue(antNFT.hasClaimedStarterAnts(user1));
        
        // Check first ant details
        (uint256 dna, uint256 level, uint256 exp, uint256 breedCount, , , bool soulbound) = 
            antNFT.getAntDetails(1);
        assertEq(level, 1);
        assertEq(exp, 0);
        assertEq(breedCount, 0);
        assertTrue(soulbound);
    }
    
    function test_RevertMintStarterAnts_AlreadyClaimed() public {
        vm.prank(user1);
        antNFT.mintStarterAnts();
        
        vm.prank(user1);
        // FIXED: Use the error selector directly
        vm.expectRevert(ALREADY_CLAIMED_SELECTOR);
        antNFT.mintStarterAnts();
    }
    
    function test_StarterAntsSoulbound() public {
        vm.prank(user1);
        antNFT.mintStarterAnts();
        
        vm.prank(user1);
        vm.expectRevert("Soulbound");
        antNFT.transferFrom(user1, user2, 1);
    }
    
    function test_MintStarterAntsForPlayer() public {
        vm.prank(colonyManager);
        vm.expectEmit(true, true, true, true);
        emit AntMinted(user1, 1, 0, true);
        antNFT.mintStarterAntsForPlayer(user1);
        
        assertEq(antNFT.balanceOf(user1), 3);
    }
    
    function test_RevertMintStarterAntsForPlayer_Unauthorized() public {
        vm.prank(user1);
        // FIXED: Use error selector directly
        vm.expectRevert(UNAUTHORIZED_SELECTOR);
        antNFT.mintStarterAntsForPlayer(user2);
    }
    
    // ========== Breeding Tests ==========
    
    function test_BreedAnts() public {
        // Mint starter ants
        vm.prank(user1);
        antNFT.mintStarterAnts();
        
        uint256 breedingCost = antNFT.BREEDING_COST();
        
        vm.prank(user1);
        vm.expectEmit(true, true, true, true);
        emit AntBred(user1, 1, 2, 4);
        antNFT.breedAnts{value: breedingCost}(1, 2);
        
        assertEq(antNFT.balanceOf(user1), 4); // 3 starters + 1 new
    }
    
    function test_BreedingDistributesRemainder() public {
        vm.prank(user1);
        antNFT.mintStarterAnts();
        
        uint256 breedingCost = antNFT.BREEDING_COST();
        uint256 fee = (breedingCost * antNFT.BREEDING_FEE_BPS()) / 10000;
        uint256 remainder = breedingCost - fee;
        uint256 halfRemainder = remainder / 2;
        
        uint256 user1BalanceBefore = user1.balance;
        
        vm.prank(user1);
        antNFT.breedAnts{value: breedingCost}(1, 2);
        
        // User should get back the remainder (minus gas)
        assertApproxEqAbs(user1.balance, user1BalanceBefore - breedingCost + remainder, 0.01 ether);
    }
    
    function test_RevertBreedAnts_InsufficientAvax() public {
        vm.prank(user1);
        antNFT.mintStarterAnts();
        
        vm.prank(user1);
        // FIXED: Use AntUtils error selector
        vm.expectRevert(INSUFFICIENT_PAYMENT_SELECTOR);
        antNFT.breedAnts{value: 0}(1, 2);
    }
    
    function test_RevertBreedAnts_StakedAnt() public {
        vm.prank(user1);
        antNFT.mintStarterAnts();
        
        // Stake ant 1
        vm.prank(colonyManager);
        antNFT.setStaked(1, true);
        
        vm.prank(user1);
        // FIXED: Use AntUtils error selector
        vm.expectRevert(ANT_STAKED_SELECTOR);
        antNFT.breedAnts{value: antNFT.BREEDING_COST()}(1, 2);
    }
    
    function test_BreedingCooldown() public {
        vm.prank(user1);
        antNFT.mintStarterAnts();
        
        uint256 breedingCost = antNFT.BREEDING_COST();
        
        vm.prank(user1);
        antNFT.breedAnts{value: breedingCost}(1, 2);
        
        // Try to breed same parents immediately
        vm.prank(user1);
        // FIXED: Use AntUtils error selector
        vm.expectRevert(BREEDING_COOLDOWN_ACTIVE_SELECTOR);
        antNFT.breedAnts{value: breedingCost}(1, 2);
        
        // Fast forward 7 days
        vm.warp(block.timestamp + 8 days);
        
        // Should work now
        vm.prank(user1);
        antNFT.breedAnts{value: breedingCost}(1, 2);
    }
    
    // ========== Leveling Tests ==========
    
    function test_LevelUp() public {
        vm.prank(user1);
        antNFT.mintStarterAnts();
        
        // Add experience (as colony manager)
        vm.prank(colonyManager);
        antNFT.addExperience(1, 100);
        
        vm.prank(user1);
        vm.expectEmit(true, true, true, true);
        emit AntLeveledUp(1, 2);
        antNFT.levelUp(1);
        
        ( , uint256 level, , , , , ) = antNFT.getAntDetails(1);
        assertEq(level, 2);
    }
    
    function test_RevertLevelUp_InsufficientXP() public {
        vm.prank(user1);
        antNFT.mintStarterAnts();
        
        vm.prank(user1);
        // FIXED: Use error selector
        vm.expectRevert(INSUFFICIENT_XP_SELECTOR);
        antNFT.levelUp(1);
    }
    
    function test_RevertLevelUp_StakedAnt() public {
        vm.prank(user1);
        antNFT.mintStarterAnts();
        
        vm.prank(colonyManager);
        antNFT.setStaked(1, true);
        
        vm.prank(colonyManager);
        antNFT.addExperience(1, 100);
        
        vm.prank(user1);
        // FIXED: Use AntUtils error selector
        vm.expectRevert(ANT_STAKED_SELECTOR);
        antNFT.levelUp(1);
    }
    
    function test_MaxLevel() public {
        vm.prank(user1);
        antNFT.mintStarterAnts();
        
        // Level up to max
        uint256 maxLevel = antNFT.MAX_LEVEL();
        for (uint256 i = 1; i < maxLevel; i++) {
            vm.prank(colonyManager);
            antNFT.addExperience(1, 100 * (i ** 2));
            
            vm.prank(user1);
            antNFT.levelUp(1);
        }
        
        // Try to level up beyond max
        vm.prank(colonyManager);
        antNFT.addExperience(1, 1000);
        
        vm.prank(user1);
        // FIXED: Use error selector
        vm.expectRevert(MAX_LEVEL_SELECTOR);
        antNFT.levelUp(1);
    }
    
    // ========== Staking Tests ==========
    
    function test_SetStaked() public {
        vm.prank(user1);
        antNFT.mintStarterAnts();
        
        vm.prank(colonyManager);
        vm.expectEmit(true, true, true, true);
        emit AntStaked(1, user1);
        antNFT.setStaked(1, true);
        
        assertTrue(antNFT.isStaked(1));
        
        vm.prank(colonyManager);
        vm.expectEmit(true, true, true, true);
        emit AntUnstaked(1, user1);
        antNFT.setStaked(1, false);
        
        assertFalse(antNFT.isStaked(1));
    }
    
    function test_RevertSetStaked_Unauthorized() public {
        vm.prank(user1);
        antNFT.mintStarterAnts();
        
        vm.prank(user1);
        // FIXED: Use error selector
        vm.expectRevert(UNAUTHORIZED_SELECTOR);
        antNFT.setStaked(1, true);
    }
    
    // ========== Burning Tests ==========
    
    function test_Burn() public {
        vm.prank(user1);
        antNFT.mintStarterAnts();
        
        vm.prank(colonyManager);
        antNFT.burn(1);
        
        assertEq(antNFT.balanceOf(user1), 2);
        
        vm.expectRevert(ANT_NOT_FOUND_SELECTOR);
        antNFT.getAntDetails(1);
    }
    
    function test_RevertBurn_Unauthorized() public {
        vm.prank(user1);
        antNFT.mintStarterAnts();
        
        vm.prank(user1);
        // FIXED: Use error selector
        vm.expectRevert(UNAUTHORIZED_SELECTOR);
        antNFT.burn(1);
    }
    
    // ========== View Function Tests ==========
    
    function test_GetOwnerAnts() public {
        vm.prank(user1);
        antNFT.mintStarterAnts();
        
        uint256[] memory ownerAnts = antNFT.getOwnerAnts(user1);
        assertEq(ownerAnts.length, 3);
        assertEq(ownerAnts[0], 1);
        assertEq(ownerAnts[1], 2);
        assertEq(ownerAnts[2], 3);
    }
    
    function test_GetAntPower() public {
        vm.prank(user1);
        antNFT.mintStarterAnts();
        
        uint256 power = antNFT.getAntPower(1);
        assertTrue(power > 0);
    }
    
    // ========== Fuzz Tests ==========
    
    function testFuzz_MintMultipleStarterAnts(uint8 count) public {
        vm.assume(count > 0 && count <= 10);
        
        // Since mintStarterAnts always mints 3, we can't fuzz the count
        // This tests that multiple users can mint
        for (uint8 i = 0; i < count; i++) {
            address newUser = makeAddr(string(abi.encodePacked("user", i)));
            vm.prank(newUser);
            antNFT.mintStarterAnts();
            assertEq(antNFT.balanceOf(newUser), 3);
        }
    }
}