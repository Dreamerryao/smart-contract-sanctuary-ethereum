/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract WriteToTheBlockchain {
    string texto;

    function Write(string calldata _texto) public{
        texto = _texto;
    }

    function Read() public view returns(string memory){
        return texto;
    }
}