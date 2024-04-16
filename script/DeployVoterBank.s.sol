// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {VoterBank} from "../src/VoterBank.sol";

contract DeployVoterBank is Script {
    function run(address token) external returns (VoterBank) {
        vm.startBroadcast();
        VoterBank voterBank = new VoterBank(token, msg.sender, msg.sender);
        vm.stopBroadcast();
        return (voterBank);
    }
}
