/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
contract HelloWorld {
  string public message;
   string public number;

  constructor(string memory initialiseMessage, string memory initNumber) {
    message = initialiseMessage;
    number=initNumber;
  }

  function update(string memory newMessage) public {
    message = newMessage;
  }
  
   function store(string memory num) public {
        number = num;
    }
}