// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract RaffleScript is Script {
    Raffle public raffle;

    function setUp() public {}

    function run() public {
        HelperConfig helperConfig = new HelperConfig();
        (address vrfConsumer, bytes32 gasLane, uint256 subscriptionId, bool enableNativePament) = 
            helperConfig.activeNetworkConfig();

        vm.startBroadcast();

        raffle = new Raffle(0.02 ether, 10, vrfConsumer,
            gasLane, subscriptionId, 400000, enableNativePament);

        vm.stopBroadcast();
    }
}
