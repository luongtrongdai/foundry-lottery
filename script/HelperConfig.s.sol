// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address vrfConsumer;
        bytes32 gasLane;
        uint256 subscriptionId;
        bool enableNativePament;
    }

    constructor() {
        if (block.chainid == 11155111) {
            getSepoliaEthConfig();
        } else {
            getAnvilEthConfig();
        }
    }
    function getSepoliaEthConfig() public {
        activeNetworkConfig = NetworkConfig({
            vrfConsumer: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 1891803289019707765347684558205062602228512876010731446449204100914846132809,
            enableNativePament: false
        });
    }

    function getAnvilEthConfig() public {
        if (activeNetworkConfig.vrfConsumer == address(0)) {
            vm.startBroadcast();

            VRFCoordinatorV2_5Mock vrfCoordinator = new VRFCoordinatorV2_5Mock(0.01 ether, 1e9, 4e15);

            vm.stopBroadcast();

            activeNetworkConfig = NetworkConfig({
                vrfConsumer: address(vrfCoordinator),
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subscriptionId: 1891803289019707765347684558205062602228512876010731446449204100914846132809,
                enableNativePament: false
            });
        }
    }
}