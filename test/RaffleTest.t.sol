//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DeployRaffle} from "../script/DeployRaffle.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test{



    Raffle raffle;
    HelperConfig helperConfig;

    uint256 s_entranceFee;
    uint256 s_interval;
    address s_vrfCoordinator;
    bytes32 s_gasLane;
    uint64 s_subscriptionId;
    uint32 s_callbackGasLimit;
    address s_link;
   
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE= 10 ether;

/* events */
event EnteredRaffle(address indexed player);

function setUp() external{
    DeployRaffle deployer = new DeployRaffle();
    (raffle, helperConfig )= deployer.run();
    ( 
    s_entranceFee,
    s_interval,
    s_vrfCoordinator,
    s_gasLane,
    s_subscriptionId,
    s_callbackGasLimit,
    s_link,
 
    ) = helperConfig.activeNetworkConfig();

    vm.deal(PLAYER, STARTING_USER_BALANCE);
}

function testRaffleInitializesInOpenState() public view{
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
}

/////////////////////
////enterRaffle   //
///////////////////

function testRaffleRevertsWhenYouDontPayEnough() public {
    //Arrange
    vm.prank(PLAYER);

    //Act/Assert
    vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
    raffle.enterRaffle();
}

function testRaffleRevertsWhenYouDontPayEnoughB() public {
    // Arrange
    vm.prank(PLAYER);

    // Act/Assert
    // Assuming Raffle.Raffle__NotEnoughEthSent() is correctly defined as an error
    // and you have the correct selector for it
    bytes4 errorSelector = bytes4(keccak256("Raffle__NotEnoughEthSent()"));
    vm.expectRevert(abi.encodeWithSelector(errorSelector));
    raffle.enterRaffle();
}


function testRaffleRecordsPlayerWhenTheyEnter() public{
    vm.prank(PLAYER);
    raffle.enterRaffle{value: s_entranceFee}();
    address playerRecorded = raffle.getPlayer(0);
    assert(playerRecorded == PLAYER);
}

function testEmitsEventOnEntrance() public {
    vm.prank(PLAYER);
    vm.expectEmit(true, false, false, false, address(raffle));
    emit EnteredRaffle(PLAYER);
    raffle.enterRaffle{value: s_entranceFee}();

}

/*
if (s_raffleState!=RaffleState.OPEN){
    revert Raffle_RaffleNotOpen();
}*/

function testCantEnterWhenRaffleIsCalculating() public{
    //arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value: s_entranceFee}();
    vm.warp(block.timestamp+s_interval+1);
    vm.roll(block.number+1);
    raffle.performUpkeep("");

    //act+assert
    vm.expectRevert(Raffle.Raffle_RaffleNotOpen.selector);
    vm.prank(PLAYER);
    raffle.enterRaffle{value: s_entranceFee}();
}

//////////////////
///  checkUpkeep//
//////////////////

/*
function  checkUpkeep(bytes ) public view
//returns (bool upkeepNeeded, bytes memory ) {
bool timeHasPassed = block.timestamp-s_lastTimeStamp>i_interval;
bool raffleIsOpen = s_raffleState==RaffleState.OPEN;
bool hasFunds=  address(this).balance>0;
bool hasPlayers = s_players.length >0;
upkeepNeeded= timeHasPassed && raffleIsOpen && hasFunds && hasPlayers;

return (upkeepNeeded, "0x0");
}

*/

function testCheckUpkeepReturnsFalseIfIthasNoBalance() public{
 /*  vm.prank(PLAYER);
    raffle.enterRaffle{value: s_entranceFee}();
    vm.warp(block.timestamp+s_interval+1);
    vm.roll(block.number+1);    
    vm.deal(address(raffle), 0);


bool timeHasPassed = block.timestamp-raffle.getLastTimeStamp() > raffle.i_interval; 
bool raffleIsOpen =  raffle.s_raffleState == Raffle.RaffleState.OPEN; 
bool hasFunds = address(raffle).balance>0; 
bool hasPlayers = raffle.s_players.length >0;

assert(timeHasPassed, true);
assert(raffleIsOpen, true);
assert(hasFunds, false);
assert(hasPlayers, true);

raffle.checkUpkeep("");
*/

//Arrange
vm.warp(block.timestamp + s_interval + 1);
vm.roll(block.number+1);

//Act
(bool upkeepNeeded, ) = raffle.checkUpkeep("");

//Assert
assert(!upkeepNeeded);

}

function testCheckUpkeepReturnsFalseIfRaffleNotOpen() public{
    //Arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value: s_entranceFee}();
    vm.warp(block.timestamp+s_interval+1);
    vm.roll(block.number+1);    
    raffle.performUpkeep("");
    
    //Act
    (bool upkeepNeeded, ) = raffle.checkUpkeep("");
    assert(upkeepNeeded == false);

}

// testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed

function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public{
    //Arrange
    //Player hass to enter raffle, Raffle has to be open, and needs to have funds
    //Raffle is by default open, as is asserted by testRaffleInitializesInOpenState
    //Player enters raffle, and modifies starting funds at the beginning
    vm.prank(PLAYER);
    raffle.enterRaffle{value: s_entranceFee}();
    vm.warp(raffle.getLastTimeStamp());
    vm.roll(block.number+1);
    //time will be the same as creation by the acting part

    //Act
    //We have to perform a checkUpkeep
  
bool upkeepneeded;

 (upkeepneeded,) = raffle.checkUpkeep("");

  //assert
    //we need to expect a false boolean returned by checkUpkeep,
    //testCheckUpkeepReturnsTrueWhenParametersAreGood works well being the same, with only time different here
    assert(upkeepneeded==false);

}


//testCheckUpkeepReturnsTrueWhenParametersAreGood
function testCheckUpkeepReturnsTrueWhenParametersAreGood() public{
//Arrange: has funds, has players, enough time passed, and is open
vm.prank(PLAYER);
raffle.enterRaffle{value: s_entranceFee}();
vm.warp(block.timestamp+s_interval+1);
vm.roll(block.number+1);

//Act:storing the value of the checkUpkeep in a boolean

(bool upkeepIsNeeded,)=raffle.checkUpkeep("");

//assert: assert the value returned is true
assert(upkeepIsNeeded==true);
}


function testPerformUpkeepRevertsWhenCheckUpkeepIsFalse() public{
    //Arrange and act, call performupkeep without met conditions


    vm.prank(PLAYER);
    uint256 currentBalance = 0;
    uint256 numPlayers = 0;
    uint256 raffleState = 0;
    vm.expectRevert(
        abi.encodeWithSelector(
            Raffle.Raffle_UpkeepNotNeeded.selector,
            currentBalance,
            numPlayers,
            raffleState
        )

    );
    raffle.performUpkeep("");

    //Assert: expect revert
}


modifier raffleEnteredAndTimePassed()  {
vm.prank(PLAYER);
raffle.enterRaffle{value: s_entranceFee}();
vm.warp(block.timestamp+s_interval+1);
vm.roll(block.number+1);
_;
}

modifier skipFork(){
    if(block.chainid!=31337){
        return;
    }
    _;
}

function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId()
 public
 raffleEnteredAndTimePassed 
{
   
   //Act
   vm.recordLogs();
    raffle.performUpkeep("");
    Vm.Log[] memory entries = vm.getRecordedLogs(); 
    bytes32 requestId = entries[1].topics[1];

    Raffle.RaffleState rState = raffle.getRaffleState();

    assert(uint256(requestId) > 0);
    assert (uint256(rState) == 1);
}


function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId)
 public 
raffleEnteredAndTimePassed skipFork{

//Arrange
vm.expectRevert("nonexistent request");
VRFCoordinatorV2Mock(s_vrfCoordinator).fulfillRandomWords(randomRequestId,address(raffle));
}



function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() 
public raffleEnteredAndTimePassed skipFork{

//arrange
uint256 additionalEntrants = 5;
uint256 startingIndex = 1;
for(uint256 i = startingIndex; i<startingIndex + additionalEntrants; i++){
    address player = address(uint160(i));
    hoax(player, STARTING_USER_BALANCE);
    raffle.enterRaffle{value: s_entranceFee}();
}

uint256 prize = s_entranceFee * (additionalEntrants+1);

    vm.recordLogs();
    raffle.performUpkeep("");
    Vm.Log[] memory entries = vm.getRecordedLogs(); 
    bytes32 requestId = entries[1].topics[1];

    uint256 previousTimeStamp = raffle.getLastTimeStamp();

    //pretend to be chainlink vrf to get random number & pick winner
   // vm.recordLogs();
    VRFCoordinatorV2Mock(s_vrfCoordinator).fulfillRandomWords(uint256(requestId) , address(raffle));
   //entries = vm.getRecordedLogs(); 
    // bytes32 winner= entries[0].topics[1];

    console.log(raffle.getRecentWinner().balance);
    console.log(STARTING_USER_BALANCE - raffle.getEntranceFee() + prize );

    //assert
    assert(uint256(raffle.getRaffleState()) == 0);
    assert(raffle.getRecentWinner() != address(0));
    assert(raffle.getLengthOfPlayers() == 0);
    assert(previousTimeStamp < raffle.getLastTimeStamp());
    //assert(address(winner) != address(0));
    assert(raffle.getRecentWinner().balance == STARTING_USER_BALANCE - raffle.getEntranceFee() + prize);

}

}