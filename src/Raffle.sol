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



//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title A sample Raffle contract
 * @author Jeremias
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2
 */

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
contract Raffle is VRFConsumerBaseV2{

/* errors */
    error Raffle__NotEnoughEthSent();
    error Raffle__TransferFailed();
    error Raffle_RaffleNotOpen();
    error Raffle_UpkeepNotNeeded(uint256 currentBalance, uint256 playersNum, RaffleState raffleState);

//bool lotteryState = open, closed, calculating
/* Type Declarations*/
enum RaffleState {
    OPEN,       //0
    CALCULATING //1

}

/* state variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3 ;
    uint32 private constant NUM_WORDS=1;

uint256 private immutable i_entranceFee;
// @dev Duration of the lottery in seconds
uint256 private immutable i_interval;
VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
bytes32 private immutable i_gasLane;
uint32 private immutable i_callbackGasLimit;
uint64 private immutable i_subscriptionId;

address payable[] private s_players;
uint256 private s_lastTimeStamp;
address private s_recentWinner;
RaffleState private s_raffleState;

/**events */
event EnteredRaffle(address indexed player);
event PickedWinner(address indexed winner);
event RequestedRaffleWinner(uint256 indexed requestId);

constructor(
    uint256 entranceFee, uint256 interval,
     address vrfCoordinator, bytes32 gasLane, 
     uint64 subscriptionId, uint32 callbackGasLimit
            ) 
     VRFConsumerBaseV2(vrfCoordinator) {
   i_vrfCoordinator=VRFCoordinatorV2Interface(vrfCoordinator);
    i_entranceFee=entranceFee;
    i_interval=interval;
    s_lastTimeStamp=block.timestamp;
    i_gasLane=gasLane;
    i_subscriptionId=subscriptionId;
    i_callbackGasLimit=callbackGasLimit;
    s_raffleState=RaffleState.OPEN;
} 

function enterRaffle() external payable{
if(msg.value<i_entranceFee){
    revert Raffle__NotEnoughEthSent();
    }
if (s_raffleState!=RaffleState.OPEN){
    revert Raffle_RaffleNotOpen();
}

//1 makes migration easier
//2 makesfront end "indexing" easier
s_players.push(payable(msg.sender));
emit EnteredRaffle(msg.sender);

}

/**
 * @dev this kicks the function that the ChainLink automation nodes calls
 * to see if its time to perform an upkeep
 * the following should be true for this to return true:
 * 1. the time interval has passed betweeen raffle runs
 * 2. the raffle is in the open state
 * 3. the contract has eth (aka, players)
 * 4. (Implicit) The subscription is funded with LINK
 */
function  checkUpkeep(bytes memory /*checkData*/)
 public view
returns (bool upkeepNeeded, bytes memory /*performData*/) {
bool timeHasPassed = block.timestamp-s_lastTimeStamp>i_interval;
bool raffleIsOpen = s_raffleState==RaffleState.OPEN;
bool hasFunds=  address(this).balance>0;
bool hasPlayers = s_players.length >0;
upkeepNeeded= timeHasPassed && raffleIsOpen && hasFunds && hasPlayers;

return (upkeepNeeded, "0x0");
}



//1. Get a random number
//2. Use the random number to pick a player
///3. Be automatically called

function performUpkeep(bytes calldata /*performData*/) external{
    (bool upkeepNeeded, ) = checkUpkeep("");
    if(!upkeepNeeded){
        revert Raffle_UpkeepNotNeeded(
            address(this).balance,
            s_players.length,
            RaffleState(s_raffleState)
        );
    }
//check to see if enough time has passed

if (block.timestamp - s_lastTimeStamp < i_interval){
 revert();
} 
s_raffleState=RaffleState.CALCULATING;

uint256 requestId= i_vrfCoordinator.requestRandomWords(
            i_gasLane,   //gas lane
            i_subscriptionId, //ID funded with LINK
            REQUEST_CONFIRMATIONS, //Number of confirmations for the value to be consdiered good
            i_callbackGasLimit,      //gas limit, no overspend
            NUM_WORDS                //number of random numbers
        );
emit RequestedRaffleWinner(requestId);

}

function fulfillRandomWords(
    uint256 /*requestId*/,
    uint256[] memory randomWords
) internal override {
//s_players = 10
// 12 % 10 = 2 <-

//Checks
//effects (within one's contract)
//LAST interactions (other contracts)
//events are preferred before
uint256 indexOfWinner = randomWords [0] % s_players.length;
address payable winner = s_players[indexOfWinner];
s_recentWinner=winner;


s_players = new address payable[](0);
s_lastTimeStamp = block.timestamp;
emit PickedWinner(winner);

(bool success, ) = winner.call{value: address(this).balance}("");
if(!success){
    revert Raffle__TransferFailed();
}
s_raffleState=RaffleState.OPEN;
}

//**Getter Function */

function getEntranceFee() external view returns(uint256){
    return i_entranceFee;
}

function getRaffleState() external view returns(RaffleState){
    return s_raffleState;
}

function getPlayer(uint256 index) external view returns (address){
   return s_players[index];
}

function getLastTimeStamp() external view returns(uint256){
    return s_lastTimeStamp;
}


function getRecentWinner() external view returns(address){
    return s_recentWinner;
}

function getLengthOfPlayers() external view returns(uint256){
return s_players.length;

}


}