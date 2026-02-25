// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Test.sol";
import "../../contracts/libraries/AntUtils.sol";

contract AntUtilsTest is Test {
    using AntUtils for *;
    
    function test_CalculateFees() public {
        uint256 value = 1 ether;
        uint256 feeBps = 500; // 5%
        
        (uint256 fee, uint256 remainder) = AntUtils.calculateFees(value, feeBps);
        
        assertEq(fee, 0.05 ether);
        assertEq(remainder, 0.95 ether);
    }
    
    function test_CalculateFees_ZeroFee() public {
        uint256 value = 1 ether;
        uint256 feeBps = 0;
        
        (uint256 fee, uint256 remainder) = AntUtils.calculateFees(value, feeBps);
        
        assertEq(fee, 0);
        assertEq(remainder, 1 ether);
    }
    
    function testFuzz_CalculateFees(uint256 value, uint256 feeBps) public {
        vm.assume(feeBps <= 10000); // Max 100%
        
        (uint256 fee, uint256 remainder) = AntUtils.calculateFees(value, feeBps);
        
        assertEq(fee + remainder, value);
        assertEq(fee, (value * feeBps) / 10000);
    }
}