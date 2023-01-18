/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

// SPDX-License-Identifier: MIT  
pragma solidity ^0.8.0;         
contract MyContract{

//private
string _name ;
uint _balance ;

constructor(string memory name,uint balance){
    require(balance>=500, "balance should greater than zero");
    _name = name;
    _balance = balance;
}
function getBalance() public view returns(uint balance){
    return _balance;
}

function deposite(uint amount) public{
    _balance+=amount;
}
}