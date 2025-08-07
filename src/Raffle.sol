// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

/**
 * @title A sample Raffle contract
 * @author Kevin
 * @notice This contract is a simple example of a raffle system
 * @dev Implements Chainlink VRF for randomness
 */
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Raffle is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    error Raffle__NotEnoughETH();
    error Raffle__NotEnoughTimePassed();
    error Raffle__UnOwned();
    error Raffle__TransferFailed();
    error Raffle__UnOpened();
    error Raffle__UnUpkeep(
        uint256 balance, uint256 playersLength, uint256 timePassed, uint256 interval, RaffleState raffleState
    );

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    uint256 private immutable i_entranceFee;
    address public immutable i_owner;

    // @dev Duration between raffle draws in seconds
    uint256 private i_interval;
    address private s_recentWinner;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    // @dev Some parameters for VRF
    bytes32 private s_keyHash;
    uint256 private s_subscriptionId;
    uint16 private s_requestConfirmations;
    uint32 private s_callbackGasLimit;
    RaffleState private s_raffleState;
    uint32 private constant NUM_WORDS = 1;
    bool private constant NAIVE_TOKEN_PAYMENT = false;

    /**
     * Events
     */
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);
    event RequestWinner(uint256 indexed requestId);

    modifier onlyOnwer() {
        if (msg.sender != i_owner) {
            revert Raffle__UnOwned();
        }
        _;
    }

    constructor(
        uint256 entranceFee,
        uint256 interval,
        bytes32 keyHash,
        uint256 subscriptionId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        address vrfCoordinator
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_owner = msg.sender;
        i_interval = interval;
        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
        s_requestConfirmations = requestConfirmations;
        s_callbackGasLimit = callbackGasLimit;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETH();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__UnOpened();
        }

        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    // @dev These two function is called by Chainlink Automation
    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool isOpen = (s_raffleState == RaffleState.OPEN);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = (address(this).balance > 0);

        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */ ) external override {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UnUpkeep(
                address(this).balance, s_players.length, block.timestamp - s_lastTimeStamp, i_interval, s_raffleState
            );
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: s_requestConfirmations,
                callbackGasLimit: s_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: NAIVE_TOKEN_PAYMENT}))
            })
        );

        emit RequestWinner(requestId);
    }

    // CEI: Check, Effects, Interaction (Avoid re-entrancy attacks)
    function fulfillRandomWords(uint256, /*_requestId*/ uint256[] calldata _randomWords) internal override {
        // Check

        // Effects
        uint256 winnerIndex = _randomWords[0] % s_players.length;
        address payable winner = s_players[winnerIndex];
        s_recentWinner = winner;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
        emit PickedWinner(winner);

        // Interaction
        (bool success,) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    function changeParameterOfVRF(
        bytes32 keyHash,
        uint256 subscriptionId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit
    ) external onlyOnwer {
        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
        s_requestConfirmations = requestConfirmations;
        s_callbackGasLimit = callbackGasLimit;
    }

    /* Getters */
    function getEnteranFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getInterval() external view returns (uint256) {
        return i_interval;
    }

    function getKeyHash() external view returns (bytes32) {
        return s_keyHash;
    }

    function getSubscriptionId() external view returns (uint256) {
        return s_subscriptionId;
    }

    function getRequestConfirmations() external view returns (uint16) {
        return s_requestConfirmations;
    }

    function getCallbackGasLimit() external view returns (uint32) {
        return s_callbackGasLimit;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayers() external view returns (address payable[] memory) {
        return s_players;
    }

    function getVRFCoordinator() external view returns (address) {
        return address(s_vrfCoordinator);
    }

    function getRecentWiner() external view returns (address) {
        return s_recentWinner;
    }

    function getLengthOfPlayers() external view returns (uint256) {
        return s_players.length;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }
}
