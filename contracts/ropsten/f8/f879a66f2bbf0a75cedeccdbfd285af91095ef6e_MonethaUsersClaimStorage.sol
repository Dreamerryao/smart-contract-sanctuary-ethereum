pragma solidity ^0.4.23;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


/**
 * @title Contactable token
 * @dev Basic version of a contactable contract, allowing the owner to provide a string with their
 * contact information.
 */
contract Contactable is Ownable {

  string public contactInformation;

  /**
    * @dev Allows the owner to set a string with their contact information.
    * @param info The contact information to attach to the contract.
    */
  function setContactInformation(string info) onlyOwner public {
    contactInformation = info;
  }
}

/**
 *  @title MonethaUsersClaimStorage
 *
 *  MonethaUsersClaimStorage is a storage contract. 
 *  It will be used by MonethaUsersClaimHandler to update and delete user claim. 
 */
contract MonethaUsersClaimStorage is Contactable {

    string constant VERSION = "0.1";
    
    // claimedTokens stores tokens claimed by the user.
    mapping (address => uint256) public claimedTokens;

    event UpdatedClaim(address indexed _userAddress, uint256 _claimedTokens, bool _isDeleted);
    event DeletedClaim(address indexed _userAddress, uint256 _unclaimedTokens, bool _isDeleted);

    /**
     *  updateUserClaim updates user claim status and adds token to his wallet
     *  @param _userAddress address of user's wallet
     *  @param _tokens corresponds to user's token that is to be claimed.
     */
    function updateUserClaim(address _userAddress, uint256 _tokens)
        external onlyOwner returns (bool)
    {
        claimedTokens[_userAddress] = _tokens;

        emit UpdatedClaim(_userAddress, _tokens, false);
        
        return true;
    }
    
    /**
     *  updateUserClaimInBulk updates multiple users claim status and adds token to their wallet
     */
    function updateUserClaimInBulk(address[] _userAddresses, uint256[] _tokens)
        external onlyOwner returns (bool)
    {
        require(_userAddresses.length == _tokens.length);

        for (uint16 i = 0; i < _userAddresses.length; i++) {
            claimedTokens[_userAddresses[i]] = _tokens[i];

            emit UpdatedClaim(_userAddresses[i],  _tokens[i], false);
        }

        return true;
    }

    /**
     *  deleteUserClaim deletes user account
     *  @param _userAddress corresponds to address of user's wallet
     */
    function deleteUserClaim(address _userAddress)
        external onlyOwner returns (bool)
    {
        delete claimedTokens[_userAddress];

        emit DeletedClaim(_userAddress, 0, true);

        return true;
    }

    /**
     *  deleteUserClaimInBulk deletes user account in bulk
     */
    function deleteUserClaimInBulk(address[] _userAddresses)
        external onlyOwner returns (bool)
    {
        for (uint16 i = 0; i < _userAddresses.length; i++) {
            delete claimedTokens[_userAddresses[i]];

            emit DeletedClaim(_userAddresses[i], 0, true);
        }

        return true;
    }
}