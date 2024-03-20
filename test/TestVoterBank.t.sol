// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {VoterBank} from "../src/VoterBank.sol";
import {DeployVoterBank} from "../script/DeployVoterBank.s.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DeployVoterSport} from "../script/DeployVoterSport.s.sol";
import {VoterSport} from "../src/VoterSport.sol";

contract TestVoterBank is Test {
    VoterBank voterBank;
    VoterSport voterSport;
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
        DeployVoterSport deployVoterSport = new DeployVoterSport();
        voterSport = deployVoterSport.run(USER1);
        DeployVoterBank deployVoterBank = new DeployVoterBank();
        voterBank = deployVoterBank.run(address(voterSport));
        vm.prank(USER1);
        voterSport.mint(USER1, STARTING_BALANCE);
        vm.stopPrank();
        vm.deal(USER1, STARTING_BALANCE);
        vm.deal(USER2, STARTING_BALANCE);
        vm.deal(USER3, STARTING_BALANCE);
    }

    function testSetPari() public asPrankedUser(USER1) {
        console.log(IERC20(address(voterSport)).balanceOf(address(USER1)));
        IERC20(voterSport).approve(address(voterBank), SEND_VALUE1);
        voterBank.setBet(12313, 1, USER1, 10000);
    }

    function testBetPari() public {
        testSetPari();
        voterBank.takeBetPrize(12313, 1, 1000);
    }

    function testTransferFees() public {
        testBetPari();
        voterBank.stopPariPrize(12313);
        uint256[] memory _eventIds = new uint256[](1);
        _eventIds[0] = 12313;
        voterBank.transferFees(USER1, _eventIds);
        assertEq(IERC20(address(voterSport)).balanceOf(address(USER1)), STARTING_BALANCE);
    }

    function testStopPariPrizeNotOperator() public asPrankedUser(USER2) {
        vm.expectRevert();
        voterBank.stopPariPrize(1);
    }

    function testTransferFeesNotOwner() public asPrankedUser(USER2) {
        uint256[] memory _eventIds = new uint256[](1);
        _eventIds[0] = 12313;
        vm.expectRevert();
        voterBank.transferFees(USER1, _eventIds);
    }
}
