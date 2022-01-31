/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.4;

interface IOERC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Whitelist {
    
    address public owner;
    uint public totalWhitelisted;
    uint public totalAmount;
    uint public batchIDs;
    uint public batchSize;
    
    struct User {
        bool isWhitelisted;
        uint amount;
    }
    
    struct Batch {
        uint nonce;
        address[] users;
    }
    
    mapping(address => User) private _users;
    mapping(uint => Batch) private _batches;
    
    event NewWhitelist(address user, uint amount);
    event NewBatchCreated(uint indexed ID);

    constructor(address _owner, uint _batchSize) {
        owner = _owner;
        batchSize = _batchSize;
    }
    
    modifier onlyOwner() {
        
        require(msg.sender == owner, "only owner can do this");
        _;
    }
    
    function _whitelist(address _user, uint _amount) internal {
        
        User storage user = _users[_user];
        user.isWhitelisted = true;
        user.amount = _amount;
        
        totalWhitelisted++;
        totalAmount += _amount;

        if (batchIDs == 0) {
            batchIDs++;
            emit NewBatchCreated(batchIDs);
        }
        
        if (_batches[batchIDs].nonce == batchSize) {
            batchIDs++;
            emit NewBatchCreated(batchIDs);
        }
        
        _batches[batchIDs].nonce++;
        _batches[batchIDs].users.push(_user);
        
        emit NewWhitelist(_user, _amount);
    }
    
    function batchWhitelist(address[] memory _user, uint[] memory _amount) external onlyOwner returns(bool) {
        
        require(_user.length == _amount.length, "user and min entry must have the same length");
        
        for (uint i = 0; i < _user.length; i++) {
            require(!_users[_user[i]].isWhitelisted, "user already whitelisted"); 
            _whitelist(_user[i], _amount[i]);
        }
        return true;
    }
    
    function whitelist(address _user, uint _amount) external onlyOwner returns(bool){
        
        require(!_users[_user].isWhitelisted, "user already whitelisted");
        
        _whitelist(_user, _amount);
        return true;
    }
    
    function isWhitelisted(address _user) external view returns(bool) {
        
        return _users[_user].isWhitelisted == true;
    }
    
    function getAmount(address _user) external view returns(uint) {
        
        return _users[_user].amount;
    }
    
    function getBatch(uint _batchId) external view returns(address[] memory batchList) { 
        
        if(_batchId == 0 || _batchId > batchIDs) revert("invalid batch ID");
        return _batches[_batchId].users;
    }

}