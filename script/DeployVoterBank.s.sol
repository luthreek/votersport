// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {VoterBank} from "../src/VoterBank.sol";

contract DeployVoterBank is Script {
    function run() external returns (VoterBank) {
        vm.startBroadcast();
        VoterBank voterBank = new VoterBank(0x1dda30B3109361196CABCbeACbccFC344a9b06a7, 0xffC5C238c09faE86246e1AFCED5c8472Fcbfc479, 0xe8ba149A60A7F400F3457F5F4A946F1C1013F13a);
        vm.stopBroadcast();
        return (voterBank);
    }
}


