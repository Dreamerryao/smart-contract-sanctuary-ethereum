/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract folks {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    // 0x83748247
    //  -> 0x4893853 => 100000
    //      -> 0x23849573 => 10000
    uint public totalSupply = 100000000 * 10 ** 18;
    string public name = "folks";
    string symbol = "fks";
    uint public decimal = 18;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address owner) public view  returns(uint){
        return balances[owner];
    }

    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true; 
    }

    function tranferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

}