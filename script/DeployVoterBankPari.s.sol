// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {VoterBankPari} from "../src/VoterBankPari.sol";

contract DeployVoterBankPari is Script {
    function run(address _token) external returns (VoterBankPari) {
        vm.startBroadcast();
        VoterBankPari voterBank = new VoterBankPari(_token, msg.sender, msg.sender);
        vm.stopBroadcast();
        return (voterBank);
    }
}
