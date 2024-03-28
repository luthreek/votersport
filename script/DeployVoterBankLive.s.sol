// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {VoterBankLive} from "../src/VoterBankLive.sol";

contract DeployVoterBankLive is Script {
    function run(address _token) external returns (VoterBankLive) {
        vm.startBroadcast();
        VoterBankLive voterBank = new VoterBankLive(_token, msg.sender, msg.sender);
        vm.stopBroadcast();
        return (voterBank);
    }
}
