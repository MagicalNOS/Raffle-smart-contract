// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Raffle} from "src/Raffle.sol";
import {Test, console2, console} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Vm} from "forge-std/Vm.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

contract TestRaffle is Test {
    Raffle private raffle;
    DeployRaffle private deployRaffle;
    HelperConfig private helperConfig;

    address PLAYER = makeAddr("player");

    uint256 entranceFee;
    uint256 interval;
    bytes32 keyHash;
    uint256 subscriptionId;
    uint16 requestConfirmations;
    uint32 callbackGasLimit;
    address vrfCoordinator;
    address linkToken;

    modifier raffleEnteredAndTimePassed() {
        vm.startPrank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        vm.stopPrank();
        _;
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function setUp() external {
        (raffle, helperConfig) = new DeployRaffle().run();
        (entranceFee, interval, keyHash, subscriptionId, requestConfirmations, callbackGasLimit, vrfCoordinator,,) =
            helperConfig.activeNetworkConfig();
        (,,,,,,, linkToken,) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, 10 ether);
    }

    function testRaffleOpenState() public view {
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assertEq(uint256(raffleState) == uint256(Raffle.RaffleState.OPEN), true);
    }

    function testNotEnoughETH() external {
        vm.expectRevert(Raffle.Raffle__NotEnoughETH.selector);
        raffle.enterRaffle{value: 100 wei}();
    }

    function testUnOwned() external {
        vm.expectRevert(Raffle.Raffle__UnOwned.selector);
        raffle.changeParameterOfVRF(keyHash, subscriptionId, requestConfirmations, callbackGasLimit);
    }

    function testChanParemeterOfVRF() external {
        bytes32 testKeyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
        uint256 testSubscriptionId = 12345;
        uint16 testRequestConfirmations = 3;
        uint32 testCallbackGasLimit = 100000;

        vm.startPrank(raffle.i_owner());

        raffle.changeParameterOfVRF(testKeyHash, testSubscriptionId, testRequestConfirmations, testCallbackGasLimit);
        assertEq(raffle.getKeyHash(), testKeyHash);
        assertEq(raffle.getSubscriptionId(), testSubscriptionId);
        assertEq(raffle.getRequestConfirmations(), testRequestConfirmations);
        assertEq(raffle.getCallbackGasLimit(), testCallbackGasLimit);
    }

    function testEmitEventOnEnter() external {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit Raffle.EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCanEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        raffle.performUpkeep("");

        vm.expectRevert(Raffle.Raffle__UnOpened.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCheckUpkeepReturnsFalseIfNotEnoughBalance() external {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assertEq(upkeepNeeded, false);
    }

    function testCheckUpkeepReturnsFalseIfNotEnoughTimePassed() external {
        vm.warp(block.timestamp + interval - 1);
        vm.roll(block.number + 1);

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assertEq(upkeepNeeded, false);
    }

    function testCheckUpkeepReturnsFalseIfNotEnoughPlayers() external {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assertEq(upkeepNeeded, false);
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsNotOpen() external {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        raffle.performUpkeep("");

        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assertEq(upkeepNeeded, false);
    }

    function testCheckUpkeepRetuensTrueIfConditionsMet() external {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assertEq(upkeepNeeded, true);
    }

    function testPerformUpkeepRevertsIfUpkeepNotNeeded() external {
        vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle__UnUpkeep.selector, address(raffle).balance, 0, 0, 60, 0));
        raffle.performUpkeep("");
    }

    function testPerformCanOnlyRunIfCheckUpkeepReturnsTrue() external {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdateRaffleStateAndEmitsEvent() external {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        vm.recordLogs();
        raffle.performUpkeep(""); // emit
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[0].topics[1];
        Raffle.RaffleState raffleState = raffle.getRaffleState();

        assert(uint256(requestId) > 0);
        assert(raffleState == Raffle.RaffleState.CALCULATING);
    }

    // FUZZ test
    function testFulfillRandomWordsCanOnlyBeCallAfterPerformUpkee(uint256 randomRequestId)
        external
        raffleEnteredAndTimePassed
        skipFork
    {
        // ACT
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
    }

    function testFulfillRandomWordsPickAWinnerResetAndSendsMoney() external raffleEnteredAndTimePassed skipFork {
        // Arrange
        uint256 additionalEnterants = 5;
        uint256 startingIndex = 1;
        for (uint256 i = startingIndex; i < additionalEnterants + startingIndex; i++) {
            address player = address(uint160(i));
            hoax(player, 10 ether);
            raffle.enterRaffle{value: entranceFee}();
        }

        console.log("Raffle balance: ", address(raffle).balance);

        uint256 prize = entranceFee * (additionalEnterants + 1);

        vm.recordLogs();
        raffle.performUpkeep(""); // emit
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1]; // get the requestId from the logs

        uint256 previousTimestamp = raffle.getLastTimeStamp();

        // prentend to be the VRF Coordinator and choose a winner
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        vm.roll(block.number + 1);
        assert(uint256(raffle.getRaffleState()) == 0);
        assert(raffle.getRecentWiner() != address(0));
        assert(raffle.getLengthOfPlayers() == 0);
        assert(raffle.getLastTimeStamp() > previousTimestamp);
        assert(address(raffle.getRecentWiner()).balance == prize + 10 ether - entranceFee);
    }

    function testGetters() external view {
        assertEq(raffle.getEnteranFee(), entranceFee);
        assertEq(raffle.getInterval(), interval);
        assertEq(raffle.getKeyHash(), keyHash);
        assertEq(raffle.getRequestConfirmations(), requestConfirmations);
        assertEq(raffle.getCallbackGasLimit(), callbackGasLimit);
        assertEq(raffle.getVRFCoordinator(), vrfCoordinator);
    }
}
