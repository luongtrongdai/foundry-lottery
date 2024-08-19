// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {LinkToken} from "test/mocks/LinkToken.sol";
import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract HelperConfig is Script {
    address public FOUNDRY_DEFAULT_SENDER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address vrfConsumer;
        bytes32 gasLane;
        uint256 subscriptionId;
        bool enableNativePament;
        address link;
        address account;
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
            enableNativePament: false,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0x0aFF5c3ac89F0A91F713A9a789e343A78B838C3c
        });
    }

    function getAnvilEthConfig() public {
        if (activeNetworkConfig.vrfConsumer == address(0)) {
            vm.startBroadcast();

            VRFCoordinatorV2_5Mock vrfCoordinator = new VRFCoordinatorV2_5Mock(0.01 ether, 1e9, 4e15);
            LinkToken link = new LinkToken();

            vm.stopBroadcast();

            activeNetworkConfig = NetworkConfig({
                vrfConsumer: address(vrfCoordinator),
                gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subscriptionId: 0,
                enableNativePament: false,
                link: address(link),
                account: FOUNDRY_DEFAULT_SENDER
            });
        }
    }

    function getActiveNetworkConfig() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }

    function setSubId(uint256 subId) public {
        activeNetworkConfig.subscriptionId = subId;
    }
}
