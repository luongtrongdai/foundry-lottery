// SPDX-License-Identifier: MIT
// 1. Pragma
pragma solidity 0.8.26;

// 2. Imports
import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {RaffleScript} from "script/Raffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

// 3. Interfaces, Libraries, Contracts

contract RaffleTest is Test {
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    Raffle public raffle;
    HelperConfig.NetworkConfig public networkConfig;
    address USER = makeAddr("user");
    address PLAYER = makeAddr("player");


    modifier performUpkeep() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 0.02 ether}();

        vm.prank(USER);
        raffle.enterRaffle{value: 0.03 ether}();

        vm.warp(raffle.getLastTimeStamp() + raffle.getInterval());
        raffle.performUpkeep("");
        _;
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function setUp() external {
        RaffleScript raffleScript = new RaffleScript();
        (networkConfig) = raffleScript.run();

        raffle = raffleScript.raffle();
        vm.deal(USER, STARTING_BALANCE);
        vm.deal(PLAYER, STARTING_BALANCE);
    }

    function test_EnterRaffleWithSmallETH() public {
        vm.expectRevert();
        raffle.enterRaffle();

        vm.expectRevert();
        raffle.enterRaffle{value: 0.001 ether}();
    }

    function test_EnterRaffleSuccess() public {
        vm.expectEmit(address(raffle));
        emit Raffle.RaffleEnter(address(this));

        raffle.enterRaffle{value: 0.02 ether}();
        assertEq(raffle.getPlayer(0), address(this));
    }

    function test_CheckUpkeepTimeLessThanInterval() public view {
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        assertEq(upkeepNeeded, false);
    }

    function test_CheckUpkeepPass() public {
        raffle.enterRaffle{value: 0.02 ether}();

        vm.warp(raffle.getLastTimeStamp() + raffle.getInterval());
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        assertEq(upkeepNeeded, true);
    }

    function test_PerformUpKeepRevertWhenUpkeepFalse() public {
        vm.expectRevert();

        raffle.performUpkeep("");
    }

    function test_PerformUpKeepWhenUpkeeped() public performUpkeep {         
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
    }

    function test_fulfillRandomWordsRevertWhenPerformUpkeep() public performUpkeep skipFork {
        VRFCoordinatorV2_5Mock(networkConfig.vrfConsumer).fulfillRandomWords(
            raffle.getLatestRequestId(), address(raffle));

        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }
}
