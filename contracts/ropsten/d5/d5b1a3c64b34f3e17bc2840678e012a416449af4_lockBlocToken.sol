pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

contract token {

  function balanceOf(address _owner) public constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);

}

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public{
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

contract lockBlocToken is Ownable {
	using SafeMath for uint256;

  token token_reward;
  address public beneficiary;
  bool public isLocked = false;
  bool public isReleased = false;
  uint256 public start_time;
  uint256 public end_time;
  uint256 public lock_up_duration = 600;//锁仓时间;

  event TokenReleased(address beneficiary, uint256 token_amount);

  constructor(address lock_contract,address beneficiary_address) public{
    //token_reward = token(0x87d714e78fF2e6CC71bE742aCfC8839cCfb608d1);// gtm合约地址
    //beneficiary = 0xE49594fe45a6140E0945e52C44e321c377f90C96;
    token_reward = token(lock_contract);// gtm合约地址
    beneficiary = beneficiary_address;

  }

  function tokenBalance() constant public returns (uint256){
    return token_reward.balanceOf(this);
  }

  function lock() public onlyOwner returns (bool){
  	require(!isLocked);
  	require(tokenBalance() > 0);
  	start_time = now;
  	end_time = start_time.add(lock_up_duration);
  	isLocked = true;
  }

  function lockOver() constant public returns (bool){
  	uint256 current_time = now;
	return current_time > end_time;
  }

	function release() onlyOwner public{
    require(isLocked);
    require(!isReleased);
    require(lockOver());
    uint256 token_amount = tokenBalance();
    token_reward.transfer( beneficiary, token_amount);
    emit TokenReleased(beneficiary, token_amount);
    isReleased = true;
  }
}