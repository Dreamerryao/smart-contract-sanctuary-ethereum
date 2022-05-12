pragma solidity ^0.4.24;

// File: contracts/SafeMath.sol

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

// File: contracts/Owned.sol

contract Owned {
  event OwnerAddition(address indexed owner);

  event OwnerRemoval(address indexed owner);

  // owner address to enable admin functions
  mapping (address => bool) public isOwner;

  address[] public owners;

  modifier onlyOwner {

    require(isOwner[msg.sender]);
    _;
  }

  function removeOwner(address _owner) public onlyOwner {
    require(owners.length > 1);
    isOwner[_owner] = false;
    for (uint i = 0; i < owners.length - 1; i++) {
      if (owners[i] == _owner) {
        owners[i] = owners[SafeMath.sub(owners.length, 1)];
        break;
      }
    }
    owners.length = SafeMath.sub(owners.length, 1);
    OwnerRemoval(_owner);
  }

  function addOwner(address _owner) external onlyOwner {
    require(_owner != address(0));
    if(isOwner[_owner]) return;
    isOwner[_owner] = true;
    owners.push(_owner);
    OwnerAddition(_owner);
  }

  function setOwners(address[] _owners) internal {
    for (uint i = 0; i < _owners.length; i++) {
      require(_owners[i] != address(0));
      isOwner[_owners[i]] = true;
      OwnerAddition(_owners[i]);
    }
    owners = _owners;
  }

  function getOwners() public constant returns (address[])  {
    return owners;
  }

}

// File: contracts/Validating.sol

contract Validating {

  modifier validAddress(address _address) {
    require(_address != address(0x0));
    _;
  }

  modifier notZero(uint _number) {
    require(_number != 0);
    _;
  }

  modifier notEmpty(string _string) {
    require(bytes(_string).length != 0);
    _;
  }

}

// File: contracts/Token.sol

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20
pragma solidity ^0.4.24;

contract Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// File: contracts/IFee.sol

/**
  * @title FEE is an ERC20 token used to pay for trading on the exchange.
  * For deeper rational read https://leverj.io/whitepaper.pdf.
  * FEE tokens do not have limit. A new token can be generated by owner.
  */
contract IFee is Token {

    function setMinter(address _minter) external;

    function burnTokens(uint _value) public;

    function sendTokens(address _to, uint _value) public;
}

// File: contracts/GenericCall.sol

contract GenericCall {

  /************************************ abstract **********************************/
  modifier isAllowed {_;}
  /********************************************************************************/

  event Execution(address destination, uint value, bytes data);

  function execute(address destination, uint value, bytes data) external isAllowed {
    if (destination.call.value(value)(data)) {
      emit Execution(destination, value, data);
    }
  }
}

// File: contracts/Stake.sol

contract Stake is Owned, Validating, GenericCall {
    using SafeMath for uint;
    string public version;
    uint public weiPerFEE; // Wei for each Fee token
    Token public LEV;
    IFee public FEE;
    address public wallet;
    uint public intervalSize;

    // events
    event StakeEvent(address indexed user, uint levs, uint startBlock, uint endBlock, uint intervalId);
    event ReStakeEvent(address indexed user, uint levs, uint startBlock, uint endBlock, uint intervalId);
    event RedeemEvent(address indexed user, uint levs, uint feeEarned, uint startBlock, uint endBlock, uint intervalId);
    event FeeCalculated(uint feeCalculated, uint feeReceived, uint weiReceived, uint startBlock, uint endBlock, uint intervalId);
    event Block(uint start, uint end, uint intervalId);
    //account
    struct UserStake {uint intervalId; uint lev; uint levBlock;}

    mapping(address => UserStake) public stakes;
    // per staking interval data
    struct Interval {uint totalLevBlocks;uint FEEGenerated;uint start;uint end;bool FEECalculated;}

    mapping(uint => Interval) public intervals;

    // user specific
    uint public latest;

    modifier isAllowed{require(isOwner[msg.sender]);
        _;}

    function() public payable {}

    /// @notice Constructor to set all the default values for the owner, wallet,
    /// weiPerFee, tokenID and endBlock
    constructor(address[] _owners, address _wallet, uint _weiPerFee, address _levToken, address _feeToken, uint _intervalSize, string _version) public
    validAddress(_wallet) validAddress(_levToken) validAddress(_feeToken) notZero(_weiPerFee) notZero(_intervalSize){
        setOwners(_owners);
        wallet = _wallet;
        weiPerFEE = _weiPerFee;
        LEV = Token(_levToken);
        intervalSize = _intervalSize;
        FEE = IFee(_feeToken);
        latest = 1;
        intervals[latest].start = block.number;
        intervals[latest].end = intervals[latest].start + intervalSize;
        version = _version;
    }

    /// @notice To set the wallet address by the owner only
    /// @param _wallet The wallet address
    function setWallet(address _wallet) external validAddress(_wallet) onlyOwner {
        ensureInterval();
        wallet = _wallet;
    }

    function setIntervalSize(uint _intervalSize) external notZero(_intervalSize) onlyOwner {
        ensureInterval();
        intervalSize = _intervalSize;
    }

    //create interval if not there
    function ensureInterval() public {
        if (intervals[latest].end > block.number) return;
        _calculateFEE2Distribute();
        uint diff = (block.number - intervals[latest].end) % intervalSize;
        latest = latest + 1;
        intervals[latest].start = intervals[latest - 1].end;
        intervals[latest].end = block.number - diff + intervalSize;
        emit Block(intervals[latest].start, intervals[latest].end, latest);
    }

    //calculate fee for previous interval if not calculated
    function _calculateFEE2Distribute() private {
        Interval storage interval = intervals[latest];
        if (interval.FEECalculated || interval.end > block.number) return;
        (uint feeEarned, uint ethEarned) = calculateDistributedIntervalEarning(interval.start, interval.end);
        interval.FEEGenerated = feeEarned.add(ethEarned.div(weiPerFEE));
        interval.FEECalculated = true;
        emit FeeCalculated(interval.FEEGenerated, feeEarned, ethEarned, interval.start, interval.end, latest);
        if (feeEarned > 0) FEE.burnTokens(feeEarned);
        if (ethEarned > 0) wallet.transfer(ethEarned);
    }

    function restake(int _signedQuantity) private {
        UserStake storage userStake = stakes[msg.sender];
        if (userStake.intervalId == latest || userStake.intervalId == 0) return;
        uint lev = userStake.lev;
        uint withdrawLev = _signedQuantity >= 0 ? 0 : uint(_signedQuantity * - 1) >= userStake.lev ? userStake.lev : uint(_signedQuantity * - 1);
        _withdraw(withdrawLev);
        userStake.lev = lev.sub(withdrawLev);
        if (userStake.lev == 0) {
            delete stakes[msg.sender];
            return;
        }
        Interval storage interval = intervals[latest];
        userStake.intervalId = latest;
        userStake.levBlock = userStake.lev.mul(interval.end.sub(interval.start));
        interval.totalLevBlocks = interval.totalLevBlocks.add(userStake.levBlock);
        emit ReStakeEvent(msg.sender, userStake.lev, interval.start, interval.end, latest);
    }

    function stake(int _signedQuantity) external {
        ensureInterval();
        restake(_signedQuantity);
        if (_signedQuantity <= 0) return;
        stakeWithCurrentPeriod(uint(_signedQuantity));
    }

    function stakeWithCurrentPeriod(uint _quantity) private {
        require(LEV.allowance(msg.sender, this) >= _quantity, "Approve LEV tokens first");
        Interval storage interval = intervals[latest];
        stakes[msg.sender].intervalId = latest;
        stakes[msg.sender].levBlock = stakes[msg.sender].levBlock.add(_quantity.mul(intervals[latest].end.sub(block.number)));
        stakes[msg.sender].lev = stakes[msg.sender].lev.add(_quantity);
        interval.totalLevBlocks = interval.totalLevBlocks.add(_quantity.mul(interval.end.sub(block.number)));
        require(LEV.transferFrom(msg.sender, this, _quantity), "LEV token transfer was not successful");
        emit StakeEvent(msg.sender, _quantity, interval.start, interval.end, latest);
    }

    function withdraw() external {
        ensureInterval();
        if (stakes[msg.sender].intervalId == 0 || stakes[msg.sender].intervalId == latest) return;
        _withdraw(stakes[msg.sender].lev);
    }

    function _withdraw(uint lev) private {
        uint intervalId = stakes[msg.sender].intervalId;
        Interval storage interval = intervals[intervalId];
        uint feeEarned = stakes[msg.sender].levBlock.mul(interval.FEEGenerated).div(interval.totalLevBlocks);
        delete stakes[msg.sender];
        if (feeEarned > 0) FEE.sendTokens(msg.sender, feeEarned);
        if (lev > 0) require(LEV.transfer(msg.sender, lev));
        emit RedeemEvent(msg.sender, lev, feeEarned, interval.start, interval.end, intervalId);
    }

    function calculateDistributedIntervalEarning(uint _start, uint _end) public constant returns (uint _feeEarned, uint _ethEarned){
        _feeEarned = FEE.balanceOf(this);
        _ethEarned = address(this).balance;
        _feeEarned = _feeEarned.mul(_end.sub(_start)).div(block.number.sub(_start));
        _ethEarned = _ethEarned.mul(_end.sub(_start)).div(block.number.sub(_start));
    }
}