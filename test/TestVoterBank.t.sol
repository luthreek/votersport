// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "../src/VoterBank.sol";
import "../src/VoterSport.sol";

contract VoterBankTest is Test {
    VoterBank public voterBank;
    VoterSport public token;
    address public operator = address(0x100);
    address public owner = address(0x200);
    address public user = address(0x300);

    function setUp() public {
        vm.prank(owner);
        token = new VoterSport(owner);

        vm.prank(owner);
        token.mint(user, 10_000 * 1e18);

        voterBank = new VoterBank(address(token), operator, owner);

        uint256 transferAmount = 5_000 * 1e18;
        vm.prank(owner);
        token.transfer(address(voterBank), transferAmount);
    }

    function testSetBetPari() public {
        uint256 eventId = 1;
        uint256 betId = 1;
        uint256 betAmount = 1000 * 1e18;

        vm.startPrank(user);
        token.approve(address(voterBank), betAmount);
        vm.stopPrank();

        vm.prank(operator);
        voterBank.setBet(true, eventId, betId, user, betAmount);

        (uint256 eId, address player, uint256 amount) = voterBank.playerPariBet(betId);
        assertEq(eId, eventId, unicode"Неверный eventId");
        assertEq(player, user, unicode"Неверный адрес игрока");
        assertEq(amount, betAmount, unicode"Неверное количество ставки");
    }

    function testTakeBetPrizePari() public {
        uint256 eventId = 1;
        uint256 betId = 1;
        uint256 betAmount = 1000 * 1e18;
        uint256 reward = 500 * 1e18;

        vm.startPrank(user);
        token.approve(address(voterBank), betAmount);
        vm.stopPrank();

        vm.prank(operator);
        voterBank.setBet(true, eventId, betId, user, betAmount);

        vm.prank(operator);
        voterBank.stopPariBets(eventId);

        vm.prank(operator);
        voterBank.takeBetPrize(true, eventId, betId, reward);

        (uint256 eId,,) = voterBank.playerPariBet(betId);
        assertEq(eId, 0, unicode"Ставка не удалена после выплаты");
    }

    // function testTransferFees() public {
    //     uint256 eventId = 1;
    //     uint256 betId = 1;
    //     uint256 betAmount = 1000 * 1e18;

    //     vm.startPrank(user);
    //     token.approve(address(voterBank), betAmount);
    //     vm.stopPrank();

    //     vm.prank(operator);
    //     voterBank.setBet(true, eventId, betId, user, betAmount);

    //     vm.prank(operator);
    //     voterBank.stopPariPrize(eventId);

    //     uint256[] memory eventIds = new uint256[](1);
    //     eventIds[0] = eventId;

    //     vm.prank(owner);
    //     voterBank.transferFees(true, owner, eventIds);

    //     uint256 bankAfter = voterBank.pariBankAmount(eventId);
    //     assertEq(bankAfter, 0, unicode"Банк события должен обнулиться после передачи fee");
    // }
}
