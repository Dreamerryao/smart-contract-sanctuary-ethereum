pragma solidity ^0.4.25;

contract ChallengeABC {
 
 event Won() ;
 event Try(bytes32 candidate);
 //bytes32 challenge=hex"fc4b2e93d9ec97f3942d6c2532d5953555b2748c679b25c26956a91622fdb3d0";
 bytes32 challenge='';
 string badAnswer="Wrong answer!";
 
 constructor(bytes32 c) public {
    challenge=c;
 }
 
 function claimReward (bytes32 s) public  {
     emit Try(s);
     require ( keccak256(keccak256(s)) == keccak256(challenge) , badAnswer);
     emit Won();
     selfdestruct(msg.sender);
 }
 

 
 function () public payable {
 }
 
}