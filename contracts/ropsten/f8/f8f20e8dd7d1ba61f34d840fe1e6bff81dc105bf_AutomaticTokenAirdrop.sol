pragma solidity ^0.4.23;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC223 is ERC20 {
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  function transferFrom(address from, address to, uint value, bytes data) public returns (bool ok);
  
  event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

/**
 * @title Automatic Token Airdrop
 * 
 * @dev Before use transferTokens function, approve the AutomaticTokenAirdrop 
 * contract address for spend the amount of ERC223 tokens 
 */
contract AutomaticTokenAirdrop {
    
    /**
     * @dev transfer tokens to adresses
     */
    function transferTokens (uint _value, address[] _addresses, address _token) public returns (bool) {
        ERC223 token = ERC223(_token);
        uint countAddresses = _addresses.length;
        for (uint i=0; i<countAddresses; i++) {
            if(!isContract(_addresses[i])) token.transferFrom(msg.sender, _addresses[i], _value, '0x');
        }
        return true;
    }
    
    /**
     * @dev Check that address is a contract
     */
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly { length := extcodesize(_addr) }
        return length > 0;
    }
}