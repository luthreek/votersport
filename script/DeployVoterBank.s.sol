// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {VoterBank} from '../src/VoterBank.sol';

contract DeployVoterBank is Script {
    
    function run() external returns(VoterBank) {
        vm.startBroadcast();
        VoterBank voterBank = new VoterBank(0xcF5c7360ce5bc1ab7ae72F022a4d5105934B1673, msg.sender);
        vm.stopBroadcast();
        return(voterBank);
    }
}