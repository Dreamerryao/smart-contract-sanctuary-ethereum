/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ILove {

    string _message;

    constructor(string memory message){
        _message = message;
    }

    function ShowMessage() public view returns(string memory) {
        return _message;
    }

}