// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {AddConsumer, CreateSubscription, FundSubscription} from "./Interaction.s.sol";

contract RaffleScript is Script {
    Raffle public raffle;


    function setUp() public {}

    function run() public returns(HelperConfig.NetworkConfig memory config) {
        HelperConfig helperConfig = new HelperConfig();
        AddConsumer addConsumer = new AddConsumer();
        config = helperConfig.getActiveNetworkConfig();


        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfConsumer) =
                createSubscription.createSubscription(config.vrfConsumer, config.account);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                config.vrfConsumer, config.subscriptionId, config.link, config.account
            );

            helperConfig.setSubId(config.subscriptionId);
        }
        vm.startBroadcast();

        raffle = new Raffle(0.002 ether, 10, config.vrfConsumer, config.gasLane, 
            config.subscriptionId, 500000, config.enableNativePament);

        vm.stopBroadcast();

        addConsumer.addConsumer(address(raffle), config.vrfConsumer, config.subscriptionId, config.account);
    }
}
