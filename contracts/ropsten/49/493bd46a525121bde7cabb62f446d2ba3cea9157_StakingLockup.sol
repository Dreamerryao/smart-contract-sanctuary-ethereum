pragma solidity 0.4.24;

pragma solidity ^0.4.19;

/*
  BASIC ERC20
  @author Hunter Long
*/

contract BasicToken {
    uint256 public totalSupply;
    bool public allowTransfer;

    function balanceOf(address _owner) constant public returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is BasicToken {

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(allowTransfer);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowTransfer);
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(allowTransfer);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}


contract Token is StandardToken {

    string public name = "BASIC";
    uint8 public decimals = 8;
    string public symbol = "BASIC";
    string public version = &#39;BASIC 0.1&#39;;

    function Token() public {
        totalSupply = 1000000000000000; // 10 million
        name = name;
        decimals = decimals;
        symbol = symbol;
        allowTransfer = true;
        balances[msg.sender] = totalSupply;
        Transfer(0x0, msg.sender, totalSupply);
    }


    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        require(_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ERC900 Simple Staking Interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-900.md
 */
contract ERC900 {
  event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
  event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);

  function stake(uint256 amount, bytes data) public;
  function stakeFor(address user, uint256 amount, bytes data) public;
  function unstake(uint256 amount, bytes data) public;
  function totalStakedFor(address addr) public view returns (uint256);
  function totalStaked() public view returns (uint256);
  function token() public view returns (address);
  function supportsHistory() public pure returns (bool);

  // NOTE: Not implementing the optional functions
  // function lastStakedFor(address addr) public view returns (uint256);
  // function totalStakedForAt(address addr, uint256 blockNumber) public view returns (uint256);
  // function totalStakedAt(uint256 blockNumber) public view returns (uint256);
}

contract AirdropComponent {

  using SafeMath for uint256;

  // Token used for airdropping and staking
  Token elementToken;

  // The duration of lock-in (in seconds)
  // Used for locking both staked and airdropped tokens
  uint256 public lockInDuration;

  // mapping for the approved airdrop users
  mapping (address => AirdropContainer) public approvedUsers;

  // tracks total number of tokens that have been airdropped
  uint256 public totalAirdropped;

  // event for withdrawing unstaked airdropped tokens
  event Withdrawn(address indexed user, uint256 amount, bytes data);

  // event for airdropping tokens
  event Airdropped(address indexed user, uint256 amount, bytes data);

  // Struct for personal airdropped token data (i.e., tokens airdropped to this address)
  // airdropTimestamp - when the token was initially airdropped to this address
  // unlockTimestamp - when the token unlocks (in seconds since Unix epoch)
  // amount - the amount of unstaked tokens airdropped to this address
  struct Airdrop {
    uint256 airdropTimestamp;
    uint256 unlockTimestamp;
    uint256 amount;
  }

  // Struct for all airdrop metadata for a particular address
  // airdrop - struct containing personal airdrop token data
  // unstaked - whether this address has unstaked airdropped tokens
  // airdropped - whether this address has been airdropped (only one airdrop per address allowed)
  struct AirdropContainer {
    Airdrop airdrop;
    bool unstaked;
    bool airdropped;
  }

  /**
   * @dev Modifier that checks if airdrop token sender can transfer tokens
   * from their balance in the elementToken contract to the stakingLockup
   * contract on behalf of a particular address.
   * @dev This modifier also transfers the tokens.
   * @param _address address to transfer tokens from
   * @param _amount uint256 the number of tokens
   */
  modifier canAirdrop(address _address, uint256 _amount) {
    require(
      elementToken.transferFrom(_address, this, _amount),
      "Insufficient token balance of sender");
    _;
  }

  /**
   * @dev Modifier that checks if approved airdrop user has already been airdropped.
   * @param _address address to check in approvedUsers mapping
   */
  modifier checkAirdrop(address _address) {
      require(!approvedUsers[_address].airdropped, "User already airdropped");
      _;
  }

  /**
   * @dev Helper function that returns the timestamp for when a user&#39;s airdropped tokens will unlock
   * @param _address address of airdropped user
   * @return uint256 timestamp
   */
  function _getPersonalAirdropUnlockTimestamp(address _address) internal view returns (uint256) {
    (uint256 timestamp,) = _getPersonalAirdrop(_address);

    return timestamp;
  }

  /**
   * @dev Helper function that returns the amount of airdropped tokens for an address
   * @param _address address of airdropped user
   * @return uint256 amount
   */
  function _getPersonalAirdropAmount(address _address) internal view returns (uint256) {
    (,uint256 amount) = _getPersonalAirdrop(_address);

    return amount;
  }

  /**
   * @notice Helper function that airdrops a certain amount of tokens to each user in a list
   * of approved user addresses. This MUST transfer the given amount from the caller to each user.
   * @notice MUST trigger Airdropped event
   * @param _users address[] the addresses of approved users to be airdropped
   * @param _amount uint256 the amount of tokens to airdrop to each user
   * @param _data bytes optional data to include in the Airdropped event
   */
  function _transferAirdrop(address[] _users, uint256 _amount, bytes _data) internal {

    uint256 listSize = _users.length;

    for (uint256 i = 0; i < listSize; i++) {
        airdropWithLockup(_users[i], _amount, _data);
    }
  }

  /**
   * @notice Helper function that withdraws a certain amount of tokens, this SHOULD return the given
   * amount of tokens to the user, if withdrawing is currently not possible the function MUST revert.
   * @notice MUST trigger Withdrawn event
   * @dev Withdrawing tokens is an atomic operation—either all of the tokens, or none of the tokens.
   * @param _amount uint256 the amount of tokens to withdraw
   * @param _data bytes optional data to include in the Withdrawn event
   */
  function _withdrawAirdrop(uint256 _amount, bytes _data) internal {
    Airdrop storage airdrop = approvedUsers[msg.sender].airdrop;

    // Check that the airdropped tokens are unlocked & matches the given withdraw amount
    require(
      airdrop.unlockTimestamp <= now,
      "The airdrop hasn&#39;t unlocked yet");

    require(
      airdrop.amount == _amount,
      "The withdrawal amount does not match the current airdrop amount");

    // Transfer the unstaked airdopped tokens from this contract back to the sender
    // Notice that we are using transfer instead of transferFrom here, so
    //  no approval is needed beforehand.
    require(
      elementToken.transfer(msg.sender, _amount),
      "Unable to withdraw airdrop");

    // Reset personal airdrop amount to 0
    airdrop.amount = 0;

    // sender no longer has unstaked airdropped tokens
    approvedUsers[msg.sender].unstaked = false;

    emit Withdrawn(
      msg.sender,
      _amount,
      _data);
  }

  /**
   * @dev Helper function to return specific personal airdrop token data for an address
   * @param _address address to query
   * @return (uint256 unlockTimestamp, uint256 amount)
   */
  function _getPersonalAirdrop(
    address _address
  )
    view
    internal
    returns(uint256, uint256)
  {
    Airdrop storage airdrop = approvedUsers[_address].airdrop;

    return (
      airdrop.unlockTimestamp,
      airdrop.amount
    );
  }

    /**
   * @dev Helper function to airdrop and lockup tokens for a given address
   * @param _address The address being airdropped
   * @param _amount uint256 The number of tokens being airdropped
   * @param _data bytes The optional data emitted in the Airdropped event
   */
  function airdropWithLockup(
      address _address,
      uint256 _amount,
      bytes _data
    )
      internal
      checkAirdrop(_address)
      canAirdrop(msg.sender, _amount)
    {

    // sets the personal airdrop token data for the address recipient
    approvedUsers[_address].airdrop = Airdrop(now, now.add(lockInDuration), _amount);

    // the address recipient has now been airdropped and has unstaked airdropped tokens
    approvedUsers[_address].airdropped = true;
    approvedUsers[_address].unstaked = true;
    totalAirdropped = totalAirdropped.add(_amount);

    emit Airdropped(
      _address,
      _amount,
      _data);
  }
}

/**
 * @title ERC900 Staking Interface w/ Added Functionality
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-900.md
 * Includes stakeForWithLockup for handling lockup of staking.
 * Inherits AirdropComponent for handling token airdrops to approvedUsers
 * and converting unstaked airdropped tokens into stakable and withdrawable tokens.
 */
contract StakingLockup is ERC900, AirdropComponent {

  // tracks total number of tokens that have been staked
  uint256 totalstaked;

  // To save on gas, rather than create a separate mapping for totalStakedFor & personalStakes,
  //  both data structures are stored in a single mapping for a given addresses.
  //
  // It&#39;s possible to have a non-existing personalStakes, but have tokens in totalStakedFor
  //  if other users are staking on behalf of a given address.
  mapping (address => StakeContainer) public stakeHolders;

  // Struct for personal stakes (i.e., stakes made by this address)
  // lockedTimestamp - when the stake was initially locked
  // unlockedTimestamp - when the stake unlocks (in seconds since Unix epoch)
  // amount - the amount of tokens in the stake
  // stakedFor - the address the stake was staked for
  struct Stake {
    uint256 lockedTimestamp;
    uint256 unlockedTimestamp;
    uint256 amount;
    address stakedFor;
  }

  // Struct for all stake metadata at a particular address
  // totalStakedFor - the number of tokens staked for this address
  // personalStakeIndex - the index in the personalStakes array.
  // personalStakes - append only array of stakes made by this address
  // exists - whether or not there are stakes that involve this address
  struct StakeContainer {
    uint256 totalStakedFor;
    uint256 personalStakeIndex;
    Stake[] personalStakes;
    bool exists;
  }

  /**
   * @dev Modifier that checks that this contract can transfer tokens from the
   *  balance in the elementToken contract for the given address.
   * @dev This modifier also transfers the tokens.
   * @param _address address to transfer tokens from
   * @param _amount uint256 the number of tokens
   */
  modifier canStake(address _address, uint256 _amount) {
    require(
      elementToken.transferFrom(_address, this, _amount),
      "Stake required");

    _;
  }

  /**
   * @dev Modifier that checks if the staking user has enough unstaked airdropped tokens
   * available to stake for the amount given.
   * @param _address address to transfer unstaked airdropped tokens from
   * @param _amount uint256 the number of tokens to stake
   */
  modifier canStakeAirdrop(address _address, uint256 _amount) {
    require(approvedUsers[_address].airdrop.amount >= _amount,
      "Insufficient airdrop token balance");

    _;
  }

  /**
   * @dev Modifier that checks if a staking user has already staked.
   * Used for ensuring a user can only stake once for themselves.
   */
  modifier checkStake() {
      require(!stakeHolders[msg.sender].exists, "User already staked");
      _;
  }

  /**
   * @dev Modifier that sets a stake into existence.
   * Used for setting a stake when a user stakes for themselves
   */
  modifier setStake() {
      require(stakeHolders[msg.sender].exists = true);
      _;
  }

  /**
   * @dev Modifier that checks if a user is improperly using stakeFor to stake for themselves.
   * Used for ensuring a user can&#39;t use stakeFor to stake for themselves.
   * @param _address address being staked for.
   */
  modifier checkStakeFor(address _address) {
      require(_address != msg.sender, "User cannot use stakeFor to stake for themselves");
      _;
  }

  /**
   * @dev Modifier that verifies a user is staking more than 0.
   * Used for ensuring a user can only successfully call a stake function
   * if they are staking actual tokens.
   * @param _amount amount user is attempting to stake.
   */
  modifier checkAmount(uint256 _amount) {
      require(_amount > 0, "User cannot stake a 0 amount");
      _;
  }

  /**
   * @dev Constructor function
   * @param _elementToken ERC20 The address of the token contract used for airdropping and staking
   */
  constructor(Token _elementToken, uint256 _lockInDuration) public {
    elementToken = _elementToken;
    lockInDuration =_lockInDuration;
  }

  /**
   * @dev Returns the timestamps for when active personal stakes for an address will unlock
   * @dev These accessors functions are needed until https://github.com/ethereum/web3.js/issues/1241 is solved
   * @param _address address that created the stakes
   * @return uint256[] array of timestamps
   */
  function getPersonalStakeUnlockedTimestamps(address _address) external view returns (uint256[]) {
    uint256[] memory timestamps;
    (timestamps,,) = getPersonalStakes(_address);

    return timestamps;
  }

  /**
   * @dev Returns the stake amount for active personal stakes for an address
   * @dev These accessors functions are needed until https://github.com/ethereum/web3.js/issues/1241 is solved
   * @param _address address that created the stakes
   * @return uint256[] array of amounts
   */
  function getPersonalStakeAmounts(address _address) external view returns (uint256[]) {
    uint256[] memory amounts;
    (,amounts,) = getPersonalStakes(_address);

    return amounts;
  }

  /**
   * @dev Returns the addresses that each personal stake was created for by an address
   * @dev These accessors functions are needed until https://github.com/ethereum/web3.js/issues/1241 is solved
   * @param _address address that created the stakes
   * @return address[] array of amounts
   */
  function getPersonalStakeForAddresses(address _address) external view returns (address[]) {
    address[] memory stakedFor;
    (,,stakedFor) = getPersonalStakes(_address);

    return stakedFor;
  }

  /**
   * @notice Stakes a certain amount of tokens, this MUST transfer the given amount from the user
   * @notice MUST trigger Staked event
   * @param _amount uint256 the amount of tokens to stake
   * @param _data bytes optional data to include in the Stake event
   */
  function stake(uint256 _amount, bytes _data) public checkStake() setStake() checkAmount(_amount) {
    stakeForWithLockup(
      msg.sender,
      _amount,
      _data);
  }

  /**
   * @notice Stakes a certain amount of tokens, this MUST transfer the given amount from the caller
   * @notice MUST trigger Staked event
   * @param _user address the address the tokens are staked for
   * @param _amount uint256 the amount of tokens to stake
   * @param _data bytes optional data to include in the Stake event
   */
  function stakeFor(address _user, uint256 _amount, bytes _data) public checkStakeFor(_user) checkAmount(_amount) {
    stakeForWithLockup(
      _user,
      _amount,
      _data);
  }

  /**
   * @notice Unstakes a certain amount of tokens, this SHOULD return the given amount of tokens to the user, if unstaking is currently not possible the function MUST revert
   * @notice MUST trigger Unstaked event
   * @dev Unstaking tokens is an atomic operation—either all of the tokens in a stake, or none of the tokens.
   * @dev Users can only unstake a single stake at a time, it is must be their oldest active stake. Upon releasing that stake, the tokens will be
   *  transferred back to their account, and their personalStakeIndex will increment to the next active stake.
   * @param _amount uint256 the amount of tokens to unstake
   * @param _data bytes optional data to include in the Unstake event
   */
  function unstake(uint256 _amount, bytes _data) public {
    Stake storage personalStake = stakeHolders[msg.sender].personalStakes[stakeHolders[msg.sender].personalStakeIndex];

    // Check that the current stake has unlocked & matches the unstake amount
    require(
      personalStake.unlockedTimestamp <= now,
      "The current stake hasn&#39;t unlocked yet");

    require(
      personalStake.amount == _amount,
      "The unstake amount does not match the current stake");

    // Transfer the staked tokens from this contract back to the sender
    // Notice that we are using transfer instead of transferFrom here, so
    //  no approval is needed beforehand.
    require(
      elementToken.transfer(msg.sender, _amount),
      "Unable to withdraw stake");

    // Reducing totalStakedFor by the total amount of tokens staked
    stakeHolders[personalStake.stakedFor].totalStakedFor = stakeHolders[personalStake.stakedFor]
      .totalStakedFor.sub(personalStake.amount);

    // Reset personalStake amount to 0
    personalStake.amount = 0;
    stakeHolders[msg.sender].personalStakeIndex++;

    // If user is unstaking for themselves,
    // allow user to stake again (for themselves)
    if (personalStake.stakedFor == msg.sender) {
      stakeHolders[msg.sender].exists = false;
    }

    // Reducing totalstaked by the amount of tokens unstaked
    totalstaked = totalstaked.sub(_amount);

    emit Unstaked(
      msg.sender,
      _amount,
      totalStakedFor(msg.sender),
      _data);
  }

  /**
   * @notice Returns the current total of tokens staked for an address
   * @param _address address The address to query
   * @return uint256 The number of tokens staked for the given address
   */
  function totalStakedFor(address _address) public view returns (uint256) {
    return stakeHolders[_address].totalStakedFor;
  }

  /**
   * @notice Returns the current total of tokens staked
   * @return uint256 The number of tokens staked in the contract
   */
  function totalStaked() public view returns (uint256) {
    return totalstaked;
  }

  /**
   * @notice Address of the token being used by the interface
   * @return address The address of the ERC20 token used
   */
  function token() public view returns (address) {
    return elementToken;
  }

    /**
   * @notice MUST return true if the optional history functions are implemented, otherwise false
   * @dev Since we don&#39;t implement the optional interface, this always returns false
   * @return bool Whether or not the optional history functions are implemented
   */
  function supportsHistory() public pure returns (bool) {
    return false;
  }

  /**
   * @dev Helper function to get specific properties of all of the personal stakes created by an address
   * @param _address address The address to query
   * @return (uint256[], uint256[], address[])
   *  timestamps array, amounts array, stakedFor array
   */
  function getPersonalStakes(
    address _address
  )
    view
    public
    returns(uint256[], uint256[], address[])
  {
    StakeContainer storage stakeContainer = stakeHolders[_address];

    uint256 arraySize = stakeContainer.personalStakes.length - stakeContainer.personalStakeIndex;
    uint256[] memory unlockedTimestamps = new uint256[](arraySize);
    uint256[] memory amounts = new uint256[](arraySize);
    address[] memory stakedFor = new address[](arraySize);

    for (uint256 i = stakeContainer.personalStakeIndex; i < stakeContainer.personalStakes.length; i++) {
      uint256 index = i - stakeContainer.personalStakeIndex;
      unlockedTimestamps[index] = stakeContainer.personalStakes[i].unlockedTimestamp;
      amounts[index] = stakeContainer.personalStakes[i].amount;
      stakedFor[index] = stakeContainer.personalStakes[i].stakedFor;
    }

    return (
      unlockedTimestamps,
      amounts,
      stakedFor
    );
  }

    /**
   * @dev Helper function to create stakes and lockup for a given address
   * @param _address The address the stake is being created for
   * @param _amount uint256 The number of tokens being staked
   * @param _data bytes The optional data emitted in the Staked event
   */
  function stakeForWithLockup(
      address _address,
      uint256 _amount,
      bytes _data
    )
      internal
      canStake(msg.sender, _amount)
    {

    // Adding to totalStakedFor by the total amount of tokens staked
    stakeHolders[_address].totalStakedFor = stakeHolders[_address].totalStakedFor.add(_amount);

    // Adding to totalstaked by the total amount of tokens staked
    totalstaked = totalstaked.add(_amount);

    stakeHolders[msg.sender].personalStakes.push(
      Stake(
        now,
        now.add(lockInDuration),
        _amount,
        _address)
      );

    emit Staked(
      _address,
      _amount,
      totalStakedFor(_address),
      _data);
  }

  /**
   * @dev Returns the timestamps for when active personal stakes for an address will unlock
   * @dev These accessors functions are needed until https://github.com/ethereum/web3.js/issues/1241 is solved
   * @param _address address of airdropped user
   * @return uint256 timestamp
   */
  function getPersonalAirdropUnlockTimestamp(address _address) external view returns (uint256) {
    return _getPersonalAirdropUnlockTimestamp(_address);
  }

  /**
   * @dev Returns the stake amount for active personal stakes for an address
   * @dev These accessors functions are needed until https://github.com/ethereum/web3.js/issues/1241 is solved
   * @param _address address of airdropped user
   * @return uint256 amount
   */
  function getPersonalAirdropAmount(address _address) external view returns (uint256) {
    return _getPersonalAirdropAmount(_address);
  }

  /**
   * @notice Airdrops a certain amount of tokens to each user in a list
   * of approved user addresses. This MUST transfer the given amount from the caller to each user.
   * @notice MUST trigger Airdropped event
   * @param _users address[] the addresses of approved users to be airdropped
   * @param _amount uint256 the amount of tokens to airdrop to each user
   * @param _data bytes optional data to include in the Airdropped event
   */
  function transferAirdrop(address[] _users, uint256 _amount, bytes _data) public checkAmount(_amount) {
        _transferAirdrop(_users, _amount, _data);
  }

  /**
   * @notice Withdraws a certain amount of tokens, this SHOULD return the given
   * amount of tokens to the user, if withdrawing is currently not possible the function MUST revert.
   * @notice MUST trigger Withdrawn event
   * @dev Withdrawing tokens is an atomic operation—either all of the tokens, or none of the tokens.
   * @param _amount uint256 the amount of tokens to withdraw
   * @param _data bytes optional data to include in the Withdrawn event
   */
  function withdrawAirdrop(uint256 _amount, bytes _data) public {
    _withdrawAirdrop(_amount, _data);
  }

  /**
   * @dev Returns specific personal airdrop token data for an address
   * @param _address address to query
   * @return (uint256 unlockTimestamp, uint256 amount)
   */
  function getPersonalAirdrop(
    address _address
  )
    view
    public
    returns(uint256, uint256)
  {
    return _getPersonalAirdrop(_address);
  }

  /**
   * @notice Stakes a certain amount of airdropped tokens,
   * user MUST have the given amount in their airdrop balance.
   * @notice MUST trigger Staked event
   * @param _amount uint256 the amount of tokens to stake
   * @param _data bytes optional data to include in the Stake event
   */
  function stakeAirdrop(uint256 _amount, bytes _data) public checkStake() setStake() checkAmount(_amount) {
    stakeAirdropWhileLocked(
      msg.sender,
      _amount,
      _data);
  }

  /**
   * @notice Stakes a certain amount of airdropped tokens,
   * caller MUST have the given amount in their airdrop balance.
   * @notice MUST trigger Staked event
   * @param _amount uint256 the amount of tokens to stake
   * @param _data bytes optional data to include in the Stake event
   */
 function stakeForAirdrop(address _user, uint256 _amount, bytes _data) public checkStakeFor(_user) checkAmount(_amount) {
    stakeAirdropWhileLocked(
      _user,
      _amount,
      _data);
  }

   /**
   * @dev Helper function to create stakes and lockup for a given address.
   * Handles conversion of internal airdrop token data to internal stakeholder data
   * @param _address The address the stake is being created for
   * @param _amount uint256 The number of tokens being staked
   * @param _data bytes The optional data emitted in the Staked event
   */
  function stakeAirdropWhileLocked(
      address _address,
      uint256 _amount,
      bytes _data
    )
      internal
      canStakeAirdrop(msg.sender, _amount)
    {

    Airdrop storage airdrop = approvedUsers[msg.sender].airdrop;

    // Reducing personal airdrop amount by the amount of staked tokens
    airdrop.amount = airdrop.amount.sub(_amount);

    // If all airdropped tokens are gone, user has no more unstaked airdrop tokens
    if(airdrop.amount == 0) {
        approvedUsers[msg.sender].unstaked = false;
    }

    // Adding to totalStakedFor by the total amount of tokens staked
    stakeHolders[_address].totalStakedFor = stakeHolders[_address].totalStakedFor.add(_amount);

    // Adding to totalstaked by the total amount of tokens staked
    totalstaked = totalstaked.add(_amount);

    stakeHolders[msg.sender].personalStakes.push(
      Stake(
        airdrop.airdropTimestamp,
        airdrop.unlockTimestamp,
        _amount,
        _address)
      );

    emit Staked(
      _address,
      _amount,
      totalStakedFor(_address),
      _data);
  }
}