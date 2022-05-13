pragma solidity ^0.4.25;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: ..\node_modules\openzeppelin-solidity\contracts\math\SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: ..\node_modules\openzeppelin-solidity\contracts\token\ERC20\ERC20.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
  * @dev Transfer token for a specified addresses
  * @param from The address to transfer from.
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param value The amount that will be created.
   */
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender's allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

// File: contracts\TeamWallet.sol

contract TeamWallet {  
	using SafeMath for uint256;

	struct Member {		
    uint256 tokenAmount;
		uint256 tokenRemain;
		uint withdrawStage;		
		address lastRejecter;
    bool isRejected;
	}

  ERC20 public tokenContract;
	uint256 public totalToken;
	address public creator;
	bool public allocateTokenDone = false;

	mapping(address => Member) public members;

  uint public firstUnlockDate;
  uint public secondUnlockDate;
  uint public thirdUnlockDate;

  address public approver1;
  address public approver2;

  event WithdrewTokens(address _tokenContract, address _to, uint256 _amount);  
  event RejectedWithdrawal(address _rejecter, address _member, uint _withdrawStage);

	modifier onlyCreator() {
		require(msg.sender == creator);
		_;
	}

  modifier onlyApprover() {
    require(msg.sender == approver1 || msg.sender == approver2);
    _;
  }

  constructor(
    address _tokenAddress,
    address _approver1, 
    address _approver2
  ) public {
    require(_tokenAddress != address(0));
    require(_approver1 != address(0));
    require(_approver2 != address(0));

    creator = _tokenAddress;		
    tokenContract = ERC20(_tokenAddress);
    
    firstUnlockDate = now + (12 * 30 days); // Allow withdraw 20% after 12 month    
    secondUnlockDate = now + (24 * 30 days); // Allow withdraw 30% after 24 month
    thirdUnlockDate = now + (36 * 30 days); // Allow withdraw all after 36 month    

    approver1 = _approver1;
    approver2 = _approver2;
  }
  
  function() payable public { 
    revert();
  }

	function setAllocateTokenDone() external onlyCreator {
		require(!allocateTokenDone);
		allocateTokenDone = true;
	}

	function addMember(address _memberAddress, uint256 _tokenAmount) external onlyCreator {		
		require(!allocateTokenDone);
		members[_memberAddress] = Member(_tokenAmount, _tokenAmount, 0, address(0), false);
    totalToken = totalToken.add(_tokenAmount);
	}
	
  // callable by team member only, after specified time
  function withdrawTokens() external {		
    require(now > firstUnlockDate);
		Member storage member = members[msg.sender];
		require(member.tokenRemain > 0 && member.isRejected == false);

    uint256 amount = 0;
    if(now > thirdUnlockDate) {
      // withdrew all remain token in third stage
      amount = member.tokenRemain;      
    } else if(now > secondUnlockDate && member.withdrawStage == 1) {
      // withdrew 30% in second stage
      amount = member.tokenAmount * 30 / 100;
    } else if(now > firstUnlockDate && member.withdrawStage == 0){
      // withdrew 20% in first stage
      amount = member.tokenAmount * 20 / 100;
    }

    if(amount > 0) {
			member.tokenRemain = member.tokenRemain.sub(amount);      
			member.withdrawStage = member.withdrawStage + 1;      
      tokenContract.transfer(msg.sender, amount);
      emit WithdrewTokens(tokenContract, msg.sender, amount);
      return;
    }

    revert();
  }  

  function rejectWithdrawal(address _memberAddress) external onlyApprover {
		Member storage member = members[_memberAddress];
    require(member.lastRejecter != msg.sender);
		require(member.tokenRemain > 0 && member.isRejected == false);

    //have a admin reject member before
    if(member.lastRejecter != address(0)) {      
			member.isRejected = true;
		}

    member.lastRejecter = msg.sender;
    emit RejectedWithdrawal(msg.sender, _memberAddress, member.withdrawStage);
  }

	function canBurn(address _memberAddress) external view returns(bool) {
		Member memory member = members[_memberAddress];
		if(member.tokenRemain > 0) return member.isRejected;
		return false;
	}

	function getMemberTokenRemain(address _memberAddress) external view returns(uint256) {
		Member memory member = members[_memberAddress];
		if(member.tokenRemain > 0) return member.tokenRemain;
		return 0;
	}	

	function burnMemberToken(address _memberAddress) external onlyCreator() {
		Member storage member = members[_memberAddress];
		require(member.tokenRemain > 0 && member.isRejected);
		member.tokenRemain = 0;
	}	
}