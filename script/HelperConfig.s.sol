//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/Mocks/LinkToken.t.sol";

contract HelperConfig is Script{

struct NetworkConfig{
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;
    uint256 deployerKey;
}

uint256 public constant DEFAULT_ANVIL_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

function getSepoliaEthConfig() public view returns(NetworkConfig memory) {
    return NetworkConfig({
        entranceFee: 0.01 ether,
        interval: 30,
        vrfCoordinator: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909,
        gasLane: /* 200wei*/0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef, //keyhash in documentation
        subscriptionId: 11022,  //Update this with our subId
        callbackGasLimit: 500000,
        link: 0x779877A7B0D9E8603169DdbD7836e478b4624789, //500,000 gas
        deployerKey: vm.envUint("PRIVATE_KEY")
    });
}

NetworkConfig public activeNetworkConfig;

constructor(){
    if (block.chainid==11155111){
        activeNetworkConfig=getSepoliaEthConfig();
    }
    else{
        activeNetworkConfig=getOrCreateAnvilEthConfig();
    }
}

function getOrCreateAnvilEthConfig() public
  returns(NetworkConfig memory){

if (activeNetworkConfig.vrfCoordinator!=address(0)){
    return activeNetworkConfig;
}

uint96 baseFee = 0.25 ether; //0.25 LINK
uint96 gasPriceLink = 1e9; //1 gwei LINK

    VRFCoordinatorV2Mock vrfCoordinatorV2Mock;
    vm.startBroadcast();
vrfCoordinatorV2Mock= new VRFCoordinatorV2Mock(baseFee, gasPriceLink);
    LinkToken link= new LinkToken();
    vm.stopBroadcast();

return NetworkConfig({
      entranceFee: 0.01 ether,
        interval: 30,
        vrfCoordinator: address(vrfCoordinatorV2Mock), 
        gasLane: 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef,
        subscriptionId: 0,  //anvil
        callbackGasLimit: 500000, //500,000 gas
        link: address(link), //address of our deployed token
        deployerKey: DEFAULT_ANVIL_KEY
});

}

}