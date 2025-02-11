// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "../src/AirDrop.sol";
import "../src/VoterSport.sol";

contract AirDropTest is Test {
    AirDrop public airdrop;
    VoterSport public token;
    address public operator = address(0x100);
    address public owner = address(0x200);
    address public user = address(0x300);

    function setUp() public {
        vm.prank(owner);
        token = new VoterSport(owner);

        airdrop = new AirDrop(address(token), operator, owner);

        uint256 transferAmount = 500_000 * 1e18;
        vm.prank(owner);
        token.transfer(address(airdrop), transferAmount);
    }

    function testSingleDrop() public {
        uint256 dropAmount = 1000 * 1e18;
        uint256 balanceBefore = token.balanceOf(user);

        vm.prank(operator);
        airdrop.singleDrop(user, dropAmount);

        uint256 balanceAfter = token.balanceOf(user);
        assertEq(balanceAfter - balanceBefore, dropAmount, unicode"Неверное поступление токенов");

        uint256 recorded = airdrop.droplist(user);
        assertEq(recorded, dropAmount, unicode"Неверное значение в mapping droplist");
    }

    function testSingleDropRevertForNonOperator() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(AirDrop.NotOperator.selector));
        airdrop.singleDrop(user, 1000 * 1e18);
    }

    function testMassDrop() public {
        AirDrop.dropCalldata[] memory drops = new AirDrop.dropCalldata[](2);
        drops[0] = AirDrop.dropCalldata(user, 500 * 1e18);
        drops[1] = AirDrop.dropCalldata(address(0x400), 600 * 1e18);

        vm.prank(operator);
        airdrop.massDrop(drops);

        assertEq(airdrop.droplist(user), 500 * 1e18, unicode"Неверное значение droplist для user");
        assertEq(airdrop.droplist(address(0x400)), 600 * 1e18, unicode"Неверное значение droplist для 0x400");
    }

    function testPauseUnpause() public {
        vm.prank(owner);
        airdrop.pause();
        assertTrue(airdrop.paused(), unicode"Контракт должен быть на паузе");

        vm.prank(owner);
        airdrop.unpause();
        assertTrue(!airdrop.paused(), unicode"Контракт должен быть активен");
    }
}
