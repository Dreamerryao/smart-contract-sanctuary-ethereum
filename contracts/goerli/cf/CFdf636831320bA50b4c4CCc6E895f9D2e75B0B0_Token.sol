/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.19; // solidity compiler version

contract Token {

    string public name; 
    string public symbol;
    uint256 public decimals;
    uint256 public total_supply;

    mapping(address => uint256) public balanceOf;  
    mapping(address => mapping(address => uint256)) public allowance; // to determine the transferred token from other address
    
    event Transfer(address indexed from, address indexed to, uint256 value); // logs event when transfer
    event Approval(address indexed owner, address indexed spender, uint256 value); // internal helper function
    
    constructor(string memory _name, string memory _symbol, uint _decimals, uint _total_supply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        total_supply = _total_supply;
        balanceOf[msg.sender] = total_supply; // give/assign the supply of token to the owner
    }
   
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);  // checks balance before transfer
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));                            // validate address before transfer 
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }
    
    // allows to spend or sell our token using internal helper within the blockchain and additional safety check
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }
        
    // to allow/approve spend/send token in an exchange 
    // or allow the buyer to approve to buy a token 
    function approve(address _spender, uint256 _value) external returns (bool) { //
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value; // value of token to be transferred/sent by the sender
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}