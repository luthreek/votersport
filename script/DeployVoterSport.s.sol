// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Script} from "forge-std/Script.sol";
import {VoterSport} from "../src/VoterSport.sol";

contract DeployVoterSport is Script {
    function run() external returns (VoterSport) {
        vm.startBroadcast();
        VoterSport voterSport = new VoterSport(0x9153F941557DE923bDf7dbC5149709ec8bE591dE);
        vm.stopBroadcast();
        return (voterSport);
    }
}
