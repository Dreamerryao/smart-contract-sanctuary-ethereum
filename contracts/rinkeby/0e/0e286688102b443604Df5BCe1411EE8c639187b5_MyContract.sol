/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract{

    //Private
    string _name;
    uint _balance;

    constructor(string memory name, uint balance) {
        // require(balance >= 50000, "Balance must be greater 50000 KIP");
        _name = name;
        _balance = balance;
    }

    function getBalance() public view returns (uint balance){
        return _balance; 
    }

    // function deposite(uint amount) public {
    //     _balance += amount;
    // }


}