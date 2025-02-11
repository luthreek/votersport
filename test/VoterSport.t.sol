// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/VoterSport.sol";

contract VoterSportTest is Test {
    VoterSport public voterSport;
    address public owner = address(0x100);
    address public user = address(0x200);
    address public voteContract = address(0x300);

    function setUp() public {
        vm.prank(owner);
        voterSport = new VoterSport(owner);

        vm.prank(owner);
        voterSport.transfer(user, 1000 * 1e18);
    }

    function testTransferRestriction() public {
        vm.prank(owner);
        voterSport.setVoteContract(voteContract);

        vm.prank(user);
        vm.expectRevert(bytes("Transfer to vote contract forbidden"));
        voterSport.transfer(voteContract, 100 * 1e18);
    }

    function testMintAndBurn() public {
        uint256 supplyBefore = voterSport.totalSupply();

        vm.prank(owner);
        voterSport.mint(owner, 500 * 1e18);
        uint256 supplyAfterMint = voterSport.totalSupply();
        assertEq(supplyAfterMint, supplyBefore + 500 * 1e18, unicode"Неверное количество после mint");

        vm.prank(owner);
        voterSport.burn(500 * 1e18);
        uint256 supplyAfterBurn = voterSport.totalSupply();
        assertEq(supplyAfterBurn, supplyBefore, unicode"Неверное количество после burn");
    }
}
