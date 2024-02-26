pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Script} from "forge-std/Script.sol";
import {VoterSport} from "../src/VoterSport.sol";

contract DeployVoterSport is Script {
    function run(address _owner) external returns (VoterSport) {
        vm.startBroadcast();
        VoterSport voterSport = new VoterSport(_owner);
        vm.stopBroadcast();
        return (voterSport);
    }
}
