//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Raffle} from "../src/Raffle.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

//script/HelperConfig.s.sol

contract DeployRaffle is Script{
    
function run() external returns (Raffle, HelperConfig){
Raffle raffle;
HelperConfig helperConfig = new HelperConfig( );
( 
    uint256 s_entranceFee,
    uint256 s_interval,
    address s_vrfCoordinator,
    bytes32 s_gasLane,
    uint64 s_subscriptionId,
    uint32 s_callbackGasLimit,
    address link,
    uint256 deployerKey
)= helperConfig.activeNetworkConfig();

if(s_subscriptionId == 0){
    //we are going to need to create a subscription

    CreateSubscription createSubscription= new CreateSubscription();
    s_subscriptionId = createSubscription.createSubscription(s_vrfCoordinator, deployerKey);
    // Funding it
    FundSubscription fundSubscription= new FundSubscription();
    fundSubscription.fundSubscription(s_vrfCoordinator, s_subscriptionId, link, deployerKey);

}

vm.startBroadcast();

raffle= new Raffle(
s_entranceFee,
s_interval,
s_vrfCoordinator, 
s_gasLane,
s_subscriptionId,
s_callbackGasLimit
);

vm.stopBroadcast();

 AddConsumer addConsumer = new AddConsumer();
    addConsumer.addConsumer(address(raffle), s_vrfCoordinator, s_subscriptionId, deployerKey);

return (raffle, helperConfig);



}
}