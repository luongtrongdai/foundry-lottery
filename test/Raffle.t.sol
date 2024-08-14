// SPDX-License-Identifier: MIT
// 1. Pragma
pragma solidity 0.8.26;

// 2. Imports
import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {RaffleScript} from "script/Raffle.s.sol";

// 3. Interfaces, Libraries, Contracts


contract RaffleTest is Test {
    Raffle public raffle;
    address USER = makeAddr("user");
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        RaffleScript raffleScript = new RaffleScript();
        raffleScript.run();
        
        raffle = raffleScript.raffle();
        vm.deal(USER, STARTING_BALANCE);
    }

    function test_EnterRaffleWithSmallETH() public {
        vm.expectRevert();
        raffle.enterRaffle();

        vm.expectRevert();
        raffle.enterRaffle{value: 0.01 ether }();
    }

    function test_EnterRaffleSuccess() public {
        vm.expectEmit(address(raffle));
        emit Raffle.RaffleEnter(address(this));

        raffle.enterRaffle{value: 0.02 ether }();
        assertEq(raffle.getPlayer(0), address(this));
    }

    function test_CheckUpkeepTimeLessThanInterval() public view {
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assertEq(upkeepNeeded, false);
    }

    function test_CheckUpkeepPass() public {
        raffle.enterRaffle{value: 0.02 ether}();

        vm.warp(20);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        assertEq(upkeepNeeded, true);
    }

    function test_PerformUpKeepRevertWhenUnUpkeep() public {
        vm.expectRevert();

        raffle.performUpkeep("");
    }

    function test_PerformUpKeepWhenUpkeeped() public {
        raffle.enterRaffle{value: 0.02 ether}();

        vm.prank(USER);
        raffle.enterRaffle{value: 0.03 ether}();

        vm.warp(20);
        raffle.performUpkeep("");

        console.log(raffle.getPlayer(1));
    }
}
