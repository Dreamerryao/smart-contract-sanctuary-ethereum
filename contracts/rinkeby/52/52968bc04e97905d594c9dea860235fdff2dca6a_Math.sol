/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Math{
    function multiplyBy20(uint v) public pure returns (uint){ //view -außerhalb, pure - innerhalb
        return v*20;
    }

    function addition(uint a, uint b) public pure returns (uint){
        return a+b;
    }

    function subtraktion(uint a, uint b) public pure returns (uint){
        return a-b;
    }

    function division(uint a, uint b) public pure returns (uint){
        return a/b;
    }

    function multiplikation(uint a, uint b) public pure returns (uint){
        return a*b;
    }
}