// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {Raffle} from "src/Raffle.sol";
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

contract CreateSubscription is Script {
    function createSubscriptionsUsingConfig() public returns (uint256) {
        HelperConfig config = new HelperConfig();
        (,,,,,, address vrfCoordinator,,uint256 deployKey) = config.activeNetworkConfig();
        return createSubscription(vrfCoordinator, deployKey);
    }

    function createSubscription(address vrfCoordinator,uint256 deployKey) public returns (uint256 subscriptionId) {
        console.log("Create Subscription on ChainID: ", block.chainid);
        vm.startBroadcast(deployKey);
        subscriptionId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Subscription ID: ", subscriptionId);
        return subscriptionId;
    }

    function run() external returns (uint256) {
        return createSubscriptionsUsingConfig();
    }
}

contract FundScription is Script {
    uint256 constant FUND_AMOUNT = 3e18; // 3 LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig config = new HelperConfig();
        (,,, uint256 subId,,, address vrfCoordinator, address linkToken,) = config.activeNetworkConfig();
        fundSubscription(vrfCoordinator, subId, linkToken);
    }

    function fundSubscription(address vrfCoordinator, uint256 subId, address linkToken) public {
        console.log("Funding Subscription on ChainID: ", block.chainid);
        console.log("Subscription ID: ", subId);
        console.log("VRF Coordinator Address: ", vrfCoordinator);
        if (block.chainid == 31337) {
            LinkToken link = LinkToken(linkToken);
            link.mint(msg.sender, 100 ether);
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subId, 100 ether);
            link.approve(vrfCoordinator, 100 ether);

        } else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subId));
            vm.stopBroadcast();
        }
    }

    function run() external {
        return fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    address raffle;

    function run() external {
        raffle = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig();
    }

    function addConsumer(address _raffle, address vrfCoordinator, uint256 subId, uint256 deployKey) public {
        console.log("Adding Consumer to Raffle Contract: ", _raffle);
        console.log("VRF Coordinator Address: ", vrfCoordinator);
        console.log("Subscription ID: ", subId);

        vm.startBroadcast(deployKey);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, _raffle);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig() public {
        HelperConfig config = new HelperConfig();
        (,,, uint256 subId,,, address vrfCoordinator,,uint256 deployKey) = config.activeNetworkConfig();
        addConsumer(address(raffle), vrfCoordinator, subId, deployKey);
    }
}
