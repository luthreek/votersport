pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Script} from "forge-std/Script.sol";
import {VoterStakePool} from "../src/VoterStakePool.sol";

contract DeployVoterStakePool is Script {
    function run(address _token, address _owner) external returns (VoterStakePool) {
        vm.startBroadcast();
        VoterStakePool voterStakePool = new VoterStakePool(_token, 3600, 5, _owner);
        vm.stopBroadcast();
        return (voterStakePool);
    }
}
