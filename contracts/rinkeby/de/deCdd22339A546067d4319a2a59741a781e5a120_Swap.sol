/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


abstract contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address _owner) view public virtual returns (uint256 balance);
    function transfer(address _to, uint256 _value) public virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
    function allowance(address _owner, address _spender) view public virtual returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Swap is Ownable{
    using SafeMath for uint256;

    ERC20 public reward = ERC20(address(0xA3f503DF8D7D47718F615A4895AdD9232324056a));

    uint256 public minDeposit = 500000000000000000;
    
    uint256 public priceToken = 1000000;

    address payable public vault = 0xcBCE7BD165C6dFE71d02B95f45b36DD4805dc60F;
    
    function setTokenReward(address _tokenAddr) public onlyOwner{
        reward = ERC20(_tokenAddr);
    }
    
    function setVault(address payable _value) public onlyOwner{
        vault = _value;
    }
    
    function setMinDeposit(uint256 _value) public onlyOwner{
        minDeposit = _value;
    }
    
    function setPriceToken(uint256 _value) public onlyOwner{
        priceToken = _value;
    }

    function withdraw() public onlyOwner{
        vault.transfer(address(this).balance);
    }

    function withdrawToken() public onlyOwner{
        reward.transfer(msg.sender, reward.balanceOf(address(this)));
    }

    function swap() public payable{
        require(msg.value >= minDeposit);

        uint256 valueBNB = msg.value;

        vault.transfer(valueBNB);
        
        uint256 valueTOKEN = valueBNB.mul(priceToken);
        
        reward.transfer(msg.sender, valueTOKEN.div(1000000000));
    }
    
}