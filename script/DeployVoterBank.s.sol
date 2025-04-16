// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {VoterBank} from "../src/VoterBank.sol";

contract DeployVoterBank is Script {
    function run() external returns (VoterBank) {
        vm.startBroadcast();
        VoterBank voterBank = new VoterBank(0x0323128F72dC006EB66a39463cbE8e7eABD342a7, 0x4fD2A3B2c8FEc7B9cac5BcfF68b9e200125f4728, 0x4fD2A3B2c8FEc7B9cac5BcfF68b9e200125f4728);
        vm.stopBroadcast();
        return (voterBank);
    }
}
