// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {Script} from "forge-std/Script.sol";
uint256 constant ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

contract HelperConfig is Script {
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        bytes32 keyHash;
        uint256 subscriptionId;
        uint16 requestConfirmations;
        uint32 callbackGasLimit;
        address vrfCoordinator;
        address linkToken;
        uint256 deploykey;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 1) {
            activeNetworkConfig = getMainnetConfig();
        } else if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }
    }

    function updateSubrciptionId(uint256 newSubscriptionId) external {
        activeNetworkConfig.subscriptionId = newSubscriptionId;
    }

    function getMainnetConfig() internal view returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 1 minutes,
            keyHash: 0x8077df514608a09f83e4e8d300645594e5d7234665448ba83f51a50f842bd3d9,
            subscriptionId: 12345,
            requestConfirmations: 3,
            callbackGasLimit: 500000,
            vrfCoordinator: 0xD7f86b4b8Cae7D942340FF628F82735b7a20893a,
            linkToken: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
            deploykey: vm.envUint("MAINNET_PRIVATE_KEY")
        });
    }

    function getSepoliaConfig() internal view returns (NetworkConfig memory) {
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 1 minutes,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 62911309000624671492123550965857525185080086208402805655736826510206179285542,
            requestConfirmations: 3,
            callbackGasLimit: 2500000,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            linkToken: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            deploykey: vm.envUint("SEPOLIA_PRIVATE_KEY")
        });
    }

    function getAnvilConfig() internal returns (NetworkConfig memory) {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }
        VRFCoordinatorV2_5Mock vrfCoordinator = new VRFCoordinatorV2_5Mock(0.1 ether, 0.001 ether, 1e18);
        LinkToken linkToken = new LinkToken();
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 1 minutes,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0,
            requestConfirmations: 3,
            callbackGasLimit: 500000,
            vrfCoordinator: address(vrfCoordinator),
            linkToken: address(linkToken),
            deploykey: ANVIL_PRIVATE_KEY
        });
    }
}
