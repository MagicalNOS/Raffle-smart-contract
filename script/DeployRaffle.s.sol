// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Script} from "forge-std/Script.sol";
import {CreateSubscription, FundScription, AddConsumer} from "script/Interaction.s.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract DeployRaffle is Script {
    HelperConfig private helperConfig;
    Raffle private raffle;

    function run() external returns (Raffle, HelperConfig) {
        helperConfig = new HelperConfig();
        (
            uint256 entranceFee,
            uint256 interval,
            bytes32 keyHash,
            uint256 subscriptionId,
            uint16 requestConfirmations,
            uint32 callbackGasLimit,
            address vrfCoordinator,
            address linkToken,
            uint256 deployKey
        ) = helperConfig.activeNetworkConfig();

        // Create subscription if it does not exist
        if (subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(vrfCoordinator, deployKey);
            helperConfig.updateSubrciptionId(subscriptionId);
        }

        // Fund it
        FundScription fundScription = new FundScription();
        fundScription.fundSubscription(vrfCoordinator, subscriptionId, linkToken);

        vm.startBroadcast();
        raffle = new Raffle(
            entranceFee, interval, keyHash, subscriptionId, requestConfirmations, callbackGasLimit, vrfCoordinator
        );
        vm.stopBroadcast();

        // Add consumer
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), vrfCoordinator, subscriptionId, deployKey);

        return (raffle, helperConfig);
    }
}
