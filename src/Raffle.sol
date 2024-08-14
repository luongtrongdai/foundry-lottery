// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";


contract Raffle is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {

    error Raffle__SendMoreToEnterRaffle();
    error Raffle__WaitMoreTime();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__RaffleNotCaculating();
     error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, RaffleState raffleState);

    /* Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee;
    // @dev the duration of the lottery in seconds
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint32 private immutable i_callbackGasLimit;
    bool private immutable i_enableNativePayment;

    address payable private s_owner;
    uint256 private s_lastTimeStamp;
    uint256 private s_subscriptionId;
    uint256 private s_latestRequestId;
    address payable private s_recentWinner;
    RaffleState private s_raffleState;
    address payable[] private s_players;

     /* Events */
    event RequestedRaffleWinner(uint256 indexed requestId);
    event RaffleEnter(address indexed player);
    event WinnerPicked(address indexed player);

    modifier onlyOpenRaffle() {
        require(s_raffleState == RaffleState.OPEN, Raffle__RaffleNotOpen());
        _;
    }

    constructor(uint256 entranceFee,
        uint256 interval,
        address vrfConsumer,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit,
        bool enableNativePament
    ) VRFConsumerBaseV2Plus(vrfConsumer) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_callbackGasLimit = callbackGasLimit;
        i_enableNativePayment = enableNativePament;

        s_owner = payable(msg.sender);
        s_lastTimeStamp = block.timestamp;
        s_subscriptionId = subscriptionId;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable onlyOpenRaffle {
        require(msg.value >= i_entranceFee, Raffle__SendMoreToEnterRaffle());

        s_players.push(payable(msg.sender));

        emit RaffleEnter(msg.sender);
    }

    function pickWinner() internal onlyOpenRaffle {
        require(block.timestamp - s_lastTimeStamp >= i_interval, Raffle__WaitMoreTime());

        s_raffleState = RaffleState.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory request = 
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: i_enableNativePayment
                    })
                )
            });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        s_latestRequestId = requestId;
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        require(s_raffleState == RaffleState.CALCULATING, Raffle__RaffleNotCaculating());
        require(requestId == s_latestRequestId, Raffle__RaffleNotCaculating());

        uint256 totalPlayers = s_players.length;
        uint256 indexOfWinner = randomWords[0] % totalPlayers;

        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        uint256 totalEntranceFee = i_entranceFee * totalPlayers;
        uint256 currentBalance = address(this).balance;

        resetRaffle();

        (bool success, ) = recentWinner.call{value: currentBalance - totalEntranceFee}("");
        require(success, Raffle__TransferFailed());

        (bool transferOwnerSuccess, ) = s_owner.call{value: totalEntranceFee}("");
        require(transferOwnerSuccess, Raffle__TransferFailed());
        
    }

    function checkUpkeep(
        bytes memory /* checkData */
    ) public view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = block.timestamp - s_lastTimeStamp >= i_interval;
        if (upkeepNeeded) {
            upkeepNeeded = s_raffleState == RaffleState.OPEN;
        }
        if (upkeepNeeded) {
            upkeepNeeded = s_players.length > 0;
        }
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        require(upkeepNeeded, Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, s_raffleState));

        pickWinner();
    }

    function resetRaffle() private {
        s_players = new address payable[](0);
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
    }

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }


    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }
}