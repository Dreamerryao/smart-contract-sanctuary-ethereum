pragma solidity 0.4.24;

contract Owned {
    address public owner;
    address public newOwner;
    address public previousOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        previousOwner = owner;
        owner = newOwner;
        newOwner = address(0);
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract BRIDGE is Owned {
    using SafeMath for uint256;

    string public constant name = "BRIDGE Token";
    string public constant symbol = "BRIDGE";
    uint8 public constant decimals = 2;
    uint256 public totalSupply = 0;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Burn(address indexed _from, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
    * @dev Gets the balance of the specified address
    * @param _owner The address to query the the balance of
    * @return An uint256 representing the amount owned by the passed address
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    /**
    * @dev Transfer token for a specified address
    * @param _to The address to transfer to
    * @param _value The amount to be transferred
    * @return Whether the transfer was successful or not
    */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @return Whether the transfer was successful or not
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address authorized to spend
     * @param _value The amount of tokens to be spent
     * @return Whether the approval was successful or not
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender
     * @param _owner address The address which owns the funds
     * @param _spender address The address which will spend the funds
     * @return A uint256 specifying the amount of tokens still available for the spender
     */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Emit new tokens
     * @param _target The address to which new tokens are transferred
     * @param _mintedAmount The amount of tokens to emit
     */
    function emitTokens(address _target, uint256 _mintedAmount) public onlyOwner returns (bool success) {
        balances[_target] = balances[_target].add(_mintedAmount);
        totalSupply = totalSupply.add(_mintedAmount);

        emit Transfer(address(0), owner, _mintedAmount);
        emit Transfer(owner, _target, _mintedAmount);
        return true;
    }

    /**
     * @dev Destroy tokens
     * @param _from The address from which tokens are burned
     * @param _value The amount of tokens to burn
     */
    function burnTokens(address _from, uint256 _value) public onlyOwner returns (bool success) {
        balances[_from] = balances[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_from, _value);
        return true;
    }

	/**
	 * @dev Destroy contract and send all tokens to owner
	 */
    function destruct() public onlyOwner {
        selfdestruct(owner);
    }
}