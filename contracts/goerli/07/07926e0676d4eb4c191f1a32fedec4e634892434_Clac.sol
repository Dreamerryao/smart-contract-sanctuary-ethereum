/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Clac{
    int private result;
    
    function add(int a,int b) public returns(int c){
        c=a+b;
    }

    function min(int a,int b) public returns(int){
        result=a-b;
        return result;
    }

    function getResult() public view returns(int){
        return result;
    }

    //由于太懒惰，所以不写接下来的了。。。
}