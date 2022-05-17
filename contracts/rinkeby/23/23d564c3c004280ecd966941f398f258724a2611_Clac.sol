/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Clac{
    int private result;

    function add(int a, int b) public returns (int c) {
        result = a + b;
        c = result;
    }

    function min(int a, int b) public returns (int) {
        result = a - b;
        return result;
    }

    function mul(int a, int b) public returns (int) {
        result = a * b;
        return result;
    }

    function div(int a, int b) public returns (int) {
        result = a / b;
        return result;
    }

    function getresult() public view returns (int) {
        return result;
    }
}