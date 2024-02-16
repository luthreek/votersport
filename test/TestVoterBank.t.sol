// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {VoterBank} from '../src/VoterBank.sol';
import {DeployVoterBank} from '../script/DeployVoterBank.s.sol';

contract TestVoterBank is Test {
    VoterBank voterBank;

    address USER1 = makeAddr("user1");
    address USER2 = makeAddr("user2");
    address USER3 = makeAddr("user3");

    uint256 constant SEND_VALUE1 = 5 ether;
    uint256 constant SEND_VALUE2 = 7 ether;
    uint256 constant SEND_VALUE3 = 9 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployVoterBank deployVoterBank = new DeployVoterBank();
        voterBank = deployVoterBank.run();
        vm.deal(USER1, STARTING_BALANCE);
        vm.deal(USER2, STARTING_BALANCE);
        vm.deal(USER3, STARTING_BALANCE);
    }

    function testSetPari() public {
        voterBank.setPari(12313, 1, USER1, true, SEND_VALUE1);
        voterBank.setPari(12313, 2, USER2, false, SEND_VALUE2);
        voterBank.setPari(12313, 3, USER3, true, SEND_VALUE3);
        voterBank.setPari(12314, 1, USER1, true, SEND_VALUE1);
        voterBank.getPlayerPari(1);
        voterBank.getTarget1BankAmount(12313);
        voterBank.getBankAmount(12313);
        voterBank.getTarget1BankAmount(12314);
        voterBank.getBankAmount(12314);
    }

        function testtakePariPrize() public {
        voterBank.setPari(12313, 1, USER1, true, SEND_VALUE1);
        voterBank.setPari(12313, 2, USER2, false, SEND_VALUE2);
        voterBank.setPari(12313, 3, USER3, true, SEND_VALUE3);
        voterBank.getPlayerPari(1);
        voterBank.takePariPrize(12313, 1);
    }

}