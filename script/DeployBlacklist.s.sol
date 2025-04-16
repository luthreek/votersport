pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Script} from "forge-std/Script.sol";
import {Blacklist} from "../src/Blacklist.sol";

contract DeployVoterSport is Script {
    function run() external returns (Blacklist) {
        vm.startBroadcast();
        Blacklist voterSport = new Blacklist();
        vm.stopBroadcast();
        return (voterSport);
    }
}
