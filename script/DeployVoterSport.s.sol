pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Script} from "forge-std/Script.sol";
import {VoterSport} from "../src/VoterSport.sol";

contract DeployVoterSport is Script {
    function run() external returns (VoterSport) {
        vm.startBroadcast();
        VoterSport voterSport = new VoterSport(0x3B66e7a2C8147EA2f5FCf39613492774F361A0DF);
        vm.stopBroadcast();
        return (voterSport);
    }
}
