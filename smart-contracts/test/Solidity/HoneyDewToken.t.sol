// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Test.sol";
import "../../contracts/tokens/HoneyDewToken.sol";

contract HoneyDewTokenTest is Test {
    HoneyDewToken public token;
    address public owner;
    address public user1;
    address public user2;
    
    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        token = new HoneyDewToken();
        
        // Deal some ETH to users for testing
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }
    
    function test_Deployment() public {
        assertEq(token.name(), "HoneyDew Token");
        assertEq(token.symbol(), "SHNY");
        assertEq(token.totalSupply(), 50_000_000 * 10**18);
        assertEq(token.balanceOf(address(token)), 50_000_000 * 10**18);
    }
    
    function test_Emission() public {
        // Fast forward 1 day
        vm.warp(block.timestamp + 1 days);
        
        token.emitDailyTokens();
        
        assertEq(token.emittedSupply(), 34_000 * 10**18);
        assertEq(token.balanceOf(owner), 34_000 * 10**18);
    }
    
    function test_CannotEmitBefore24Hours() public {
        vm.expectRevert("Emission too frequent");
        token.emitDailyTokens();
    }
    
    function test_MintReward() public {
        uint256 amount = 1000 * 10**18;
        token.mintReward(user1, amount);
        
        assertEq(token.balanceOf(user1), amount);
    }
    
    function test_RevertMintReward_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        token.mintReward(user1, 1000 * 10**18);
    }
    
    function test_ConvertToAVAX() public {
        // First mint tokens to user
        uint256 mintAmount = 10000 * 10**18;
        token.mintReward(user1, mintAmount);
        
        uint256 convertAmount = 1000 * 10**18;
        uint256 expectedAvax = (convertAmount * 1e16) / 1e21; // 0.01 AVAX per 1000 SHNY
        uint256 expectedFee = expectedAvax * 10 / 100;
        uint256 expectedUserAvax = expectedAvax - expectedFee;
        
        uint256 balanceBefore = user1.balance;
        
        vm.prank(user1);
        token.convertToAVAX(convertAmount);
        
        uint256 balanceAfter = user1.balance;
        uint256 avaxReceived = balanceAfter - balanceBefore;
        
        assertEq(avaxReceived, expectedUserAvax);
        assertEq(token.balanceOf(user1), mintAmount - convertAmount);
    }
    
    function test_RevertConvertToAVAX_DailyLimit() public {
        token.mintReward(user1, 10000 * 10**18);
        
        vm.prank(user1);
        token.convertToAVAX(4000 * 10**18);
        
        vm.prank(user1);
        vm.expectRevert("Daily limit exceeded");
        token.convertToAVAX(2000 * 10**18);
    }
    
    function test_DailyLimitResetAfter24Hours() public {
        token.mintReward(user1, 10000 * 10**18);
        
        vm.prank(user1);
        token.convertToAVAX(4000 * 10**18);
        
        // Fast forward 1 day
        vm.warp(block.timestamp + 1 days);
        
        vm.prank(user1);
        token.convertToAVAX(4000 * 10**18); // Should work
    }
    
    function testFuzz_ConvertToAVAX(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 5000 * 10**18);
        
        token.mintReward(user1, 10000 * 10**18);
        
        uint256 balanceBefore = user1.balance;
        
        vm.prank(user1);
        token.convertToAVAX(amount);
        
        uint256 balanceAfter = user1.balance;
        assertGt(balanceAfter, balanceBefore);
    }
}