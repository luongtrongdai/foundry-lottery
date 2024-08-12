// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Raffle {
    uint256 private immutable i_entranceFee;

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public payable {

    }

    function pickWinner() public {

    }

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}