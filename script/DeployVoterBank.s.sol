// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {VoterBank} from "../src/VoterBank.sol";

contract DeployVoterBank is Script {
    function run() external returns (VoterBank) {
        vm.startBroadcast();
        VoterBank voterBank = new VoterBank(0x884a3823cCa0C70E155Afc42bbD262586Ca89E9c, 0x884a3823cCa0C70E155Afc42bbD262586Ca89E9c, 0x884a3823cCa0C70E155Afc42bbD262586Ca89E9c);
        vm.stopBroadcast();
        return (voterBank);
    }
}
