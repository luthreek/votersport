pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Script} from "forge-std/Script.sol";
import {VoterSport} from "../src/VoterSport.sol";

contract DeployVoterSport is Script {
    function run(address token) external returns (VoterSport) {
        vm.startBroadcast();
        VoterSport voterSport = new VoterSport(token);
        vm.stopBroadcast();
        return (voterSport);
    }
}
