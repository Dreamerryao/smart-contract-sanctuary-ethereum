pragma solidity ^ 0.4.25;

/*

  Copyright 2017 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */

constructor() public {owner = msg.sender;}


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
 }
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
/*@title SafeMath
 * @dev Math operations with safety checks that revert on error*/

 library SafeMath {

  /*@dev Multiplies two numbers, reverts on overflow.*/

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.

    if (a == 0) {return 0;}

    uint256 c = a * b;
    require(c / a == b);
    return c;}

  /*@dev Integer division of two numbers truncating the quotient, reverts on division by zero.*/

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
	// Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b);
	// There is no case in which this doesn't hold
    return c;}

  /*@dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).*/

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;}

  /*@dev Adds two numbers, reverts on overflow.*/
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;}

  /*@dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.*/

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;}
}
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value)public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value)public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20 {

    function transfer(address _to, uint _value) public returns (bool) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        if (balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

  function balanceOf(address _owner) public constant returns (uint) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    uint public totalSupply;
}

contract UnlimitedAllowanceToken is StandardToken {

    uint constant MAX_UINT = 2**256 - 1;
    
    /// @dev ERC20 transferFrom, modified such that an allowance of MAX_UINT represents an unlimited allowance.
    /// @param _from Address to transfer from.
    /// @param _to Address to transfer to.
    /// @param _value Amount to transfer.
    /// @return Success of transfer.
    function transferFrom(address _from, address _to, uint _value)
        public
        returns (bool)
    {
        uint allowance = allowed[_from][msg.sender];
        if (balances[_from] >= _value
            && allowance >= _value
            && balances[_to] + _value >= balances[_to]
        ) {
            balances[_to] += _value;
            balances[_from] -= _value;
            if (allowance < MAX_UINT) {
                allowed[_from][msg.sender] -= _value;
            }
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
}

contract IDMCOSAS is Ownable, UnlimitedAllowanceToken {

    string public constant name = "IDMCOSAS";
   
  string public constant symbol = "MCS";
    
  uint32 public constant decimals = 18;
  
  uint256 public totalSupply = (10 ** 8) * (10 ** 18); // hundred million, 18 decimal places;  

    function MCS() public onlyOwner {
        balances[msg.sender] = totalSupply;
    }
}

contract PRESALE_IDMCOSAS is Ownable, IDMCOSAS{   
 
  using SafeMath for uint;

  address multisig;

  uint restrictedPercent;

  address restricted;

  IDMCOSAS public token;

  uint start;

  uint period;

  uint rate;

      uint public hardcap;

    uint public softcap;
	



  function CrowdsaleMCS () public onlyOwner {
	 token = IDMCOSAS(0x005dd5f95E135Cd739945d50113fbe492C43Bf2b4B);
     multisig = 0xd0C7eFd2acc5223c5cb0A55e2F1D5f1bB904035d;
     restricted = 0xd0C7eFd2acc5223c5cb0A55e2F1D5f1bB904035d;
     restrictedPercent = 15;
     rate = 189000000000000000000;
     start = 1538352000;
     period = 15;
     hardcap = 2000000000000000000000000;
     softcap = 498393000000000000000000;
	  
    
  }

  modifier saleIsOn() {
    require(now > start && now < start + period * 1 days);
    _;
  }


  function createTokens() public saleIsOn payable {
    multisig.transfer(msg.value);
    uint tokens = rate.mul(msg.value).div(1 ether);
    uint bonusTokens = 0;
    if(now < start + (period * 1 days).div(4)) {
      bonusTokens = tokens.div(4);
    } else if(now >= start + (period * 1 days).div(4) && now < start + (period * 1 days).div(4).mul(2)) {
      bonusTokens = tokens.div(10);
    } else if(now >= start + (period * 1 days).div(4).mul(2) && now < start + (period * 1 days).div(4).mul(3)) {
      bonusTokens = tokens.div(20);
    }
    uint tokensWithBonus = tokens.add(bonusTokens);
    token.transfer(msg.sender, tokensWithBonus);
    uint restrictedTokens = tokens.mul(restrictedPercent).div(100 - restrictedPercent);
    token.transfer(restricted, restrictedTokens);
  }

  function() external payable {
    createTokens();
  }

}