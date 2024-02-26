pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Test, console} from "forge-std/Test.sol";
import {VoterStakePool} from "../src/VoterStakePool.sol";
import {DeployVoterStakePool} from "../script/DeployVoterStakePool.s.sol";
import {DeployVoterSport} from "../script/DeployVoterSport.s.sol";
import {VoterSport} from "../src/VoterSport.sol";

contract TestStakePool is Test {
    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 profitPercentage; // Percentage of profit for the stake
    }

    VoterStakePool voterStakePool;
    VoterSport voterSport;
    address token;

    address USER1 = makeAddr("user1");
    address USER2 = makeAddr("user2");
    address USER3 = makeAddr("user3");

    uint256 constant SEND_VALUE1 = 5 ether;
    uint256 constant SEND_VALUE2 = 7 ether;
    uint256 constant SEND_VALUE3 = 9 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    modifier asPrankedUser(address user) {
        vm.startPrank(user);
        _;
        vm.stopPrank();
    }

    function setUp() external {
        vm.deal(USER1, STARTING_BALANCE);
        vm.deal(USER2, STARTING_BALANCE);
        vm.deal(USER3, STARTING_BALANCE);
        DeployVoterSport deployVoterSport = new DeployVoterSport();
        voterSport = deployVoterSport.run(USER1);
        DeployVoterStakePool deployVoterStakePool = new DeployVoterStakePool();
        voterStakePool = deployVoterStakePool.run(address(voterSport), USER1);
        vm.prank(USER1);
        voterSport.mint(USER1, STARTING_BALANCE);
        vm.stopPrank();
    }

    function testStake() public asPrankedUser(USER1) {
        console.log(IERC20(address(voterSport)).balanceOf(address(USER1)));
        IERC20(voterSport).approve(address(voterStakePool), SEND_VALUE1);
        voterStakePool.stake(SEND_VALUE1);
        (uint256 amount, uint256 startTime, uint256 profitPercentage) = voterStakePool.getStake(USER1);
        assertEq(SEND_VALUE1, IERC20(address(voterSport)).balanceOf(address(voterStakePool)));
        assertEq(amount, SEND_VALUE1);
    }

    /*     function testUnstake() public asPrankedUser(USER1) {
        IERC20(voterSport).approve(USER1, STARTING_BALANCE);
        voterStakePool.stake(SEND_VALUE1);
        vm.warp(block.timestamp + voterStakePool.stakingDuration());
        voterStakePool.unstake();
        (uint256 amount, uint256 startTime, uint256 profitPercentage) = voterStakePool.getStake(USER1);
        assertEq(IERC20(address(voterSport)).balanceOf(USER1), STARTING_BALANCE + SEND_VALUE1 * profitPercentage / 100);
        assertEq(amount, 0);
    } */
}
