// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "../src/VoterStakePool.sol";
import "../src/VoterSport.sol";

contract VoterStakePoolTest is Test {
    VoterStakePool public stakePool;
    VoterSport public token;
    address public owner = address(0x100);
    address public staker = address(0x200);
    uint256 public stakingDuration = 1 days;
    uint256 public profitPercentage = 10; // 10%

    function setUp() public {
        vm.prank(owner);
        token = new VoterSport(owner);

        vm.prank(owner);
        token.mint(staker, 10_000 * 1e18);

        stakePool = new VoterStakePool(address(token), stakingDuration, profitPercentage, owner);
    }

    function testStake() public {
        uint256 stakeAmount = 1000 * 1e18;

        vm.startPrank(staker);
        token.approve(address(stakePool), stakeAmount);
        stakePool.stake(stakeAmount);
        vm.stopPrank();

        (uint256 amount,, uint256 profitPerc) = stakePool.getStake(staker);
        assertEq(amount, stakeAmount, unicode"Неверное количество застейканных токенов");
        assertEq(profitPerc, profitPercentage, unicode"Неверный процент прибыли");
    }

    function testUnstake() public {
        uint256 stakeAmount = 1000 * 1e18;

        vm.startPrank(staker);
        token.approve(address(stakePool), stakeAmount);
        stakePool.stake(stakeAmount);
        vm.stopPrank();

        vm.prank(owner);
        token.transfer(address(stakePool), stakeAmount * profitPercentage / 100);

        vm.warp(block.timestamp + stakingDuration + 1);

        uint256 balanceBefore = token.balanceOf(staker);
        vm.prank(staker);
        stakePool.unstake();
        uint256 balanceAfter = token.balanceOf(staker);

        uint256 expectedReturn = stakeAmount + (stakeAmount * profitPercentage / 100);
        assertEq(balanceAfter - balanceBefore, expectedReturn, unicode"Неверная сумма при анстейкинге");
    }
}
