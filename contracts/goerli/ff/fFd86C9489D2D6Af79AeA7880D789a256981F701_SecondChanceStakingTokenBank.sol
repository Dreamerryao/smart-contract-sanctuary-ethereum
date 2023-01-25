// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Helpers/IERC20Extended.sol";
import "../models/StakeEntry.sol";

contract SecondChanceStakingTokenBank is ReentrancyGuard, Ownable {
    event Staked(uint256 _id, uint256 _timestamp, uint256 _windowStartDate, uint256 _windowEndDate, uint256 _poolEndDate, address _staker, address _token, uint256 _amount, uint256 _decimals);
    event UnStaked(uint256 _id, uint256 _timestamp);
    
    mapping(uint256 => StakeEntry) public StakeEntries;
    mapping(address => uint256[]) public StakeEntryIds;

    uint256 public LastId;
    uint256 public PoolEndDate;
    uint256 public BaseFee;
    uint256 public PenaltyFee;

    uint256 public WindowStart;
    uint256 public WindowEnd;

    constructor(uint256 endDate, uint256 windowStart, uint256 windowEnd, uint256 baseFee, uint256 penaltyFee) {
        PoolEndDate = endDate;
        BaseFee = baseFee;
        PenaltyFee = penaltyFee;
        WindowStart = windowStart;
        WindowEnd = windowEnd;
    }

    function stakeEntryIdsFullMapping(address _address) external view returns (uint256[] memory) {
        return StakeEntryIds[_address];
    }

    /**
    * @dev function to stake the given token (amount = all msgSender has)
    * @param stakingTokenAddress the token to stake
    */ 
    function stake(address stakingTokenAddress) external nonReentrant {
        uint balanceOf = IERC20(stakingTokenAddress).balanceOf(_msgSender());       
        require(IERC20(stakingTokenAddress).allowance(_msgSender(), address(this)) >= balanceOf, "Allowance not set");
        require(block.timestamp > WindowStart, "Cannot stake before start");
        require(block.timestamp < WindowEnd, "Cannot stake after end");

        LastId += 1;
        StakeEntries[LastId].Staker = _msgSender();
        StakeEntries[LastId].TokenAddress = stakingTokenAddress;        
        StakeEntries[LastId].State = State.STAKED;
        StakeEntries[LastId].EntryTime = block.timestamp;
        StakeEntries[LastId].PeriodFinish = PoolEndDate;

        StakeEntryIds[_msgSender()].push(LastId);
        uint256 balanceOfContractBefore = IERC20(stakingTokenAddress).balanceOf(address(this));
        IERC20(stakingTokenAddress).transferFrom(_msgSender(), address(this), balanceOf);
        uint256 balanceOfContractAfter = IERC20(stakingTokenAddress).balanceOf(address(this));
        uint256 actualTransfer = balanceOfContractAfter - balanceOfContractBefore;
        
        StakeEntries[LastId].Amount = actualTransfer;
        emit Staked(LastId, block.timestamp, WindowStart, WindowEnd, PoolEndDate, _msgSender(), stakingTokenAddress, actualTransfer, IERC20Extended(stakingTokenAddress).decimals());
    }

    /**
    * @dev function to unStake the given token
    * @param id the id of the entry to unstake
    */ 
    function unStake(uint256 id) external nonReentrant {
        require(StakeEntries[id].Staker == _msgSender(), "not allowed to unstake this entry");
        require(StakeEntries[id].State == State.STAKED, "already unstaked");

        uint256 fee = (StakeEntries[id].Amount * BaseFee) / 100;
        if(block.timestamp < StakeEntries[LastId].PeriodFinish) fee = (StakeEntries[id].Amount * PenaltyFee) / 100;

        uint256 amount = StakeEntries[id].Amount - fee;
        StakeEntries[id].State = State.UNSTAKED;

        IERC20(StakeEntries[id].TokenAddress).transfer(_msgSender(), amount);
        IERC20(StakeEntries[id].TokenAddress).transfer(owner(), fee);
        emit UnStaked(id, block.timestamp);
    }

    /**
    * @dev function to set the pool end date
    * @param endDate the end date to set
    */
    function setPoolEndDate(uint256 endDate) external onlyOwner {
        PoolEndDate = endDate;
    }

    /**
    * @dev function to set the window start
    * @param startDate the start date to set
    */
    function setWindowStart(uint256 startDate) external onlyOwner {
        WindowStart = startDate;
    }

    /**
    * @dev function to set the window end
    * @param endDate the end date to set
    */
    function setWindowEnd(uint256 endDate) external onlyOwner {
        WindowEnd = endDate;
    }

    /**
    * @dev function to set the base fee
    * @param baseFee the base fee to set
    */
    function setBaseFee(uint256 baseFee) external onlyOwner {
        BaseFee = baseFee;
    }

    /**
    * @dev function to set the penalty fee
    * @param penaltyFee the penalty fee to set
    */
    function setPenaltyFee(uint256 penaltyFee) external onlyOwner {
        PenaltyFee = penaltyFee;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20Extended{
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct StakeEntry{
    address Staker;
    address TokenAddress;
    uint Amount;
    State State;
    uint EntryTime;
    uint PeriodFinish;
}

enum State {
    STAKED,
    UNSTAKED
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}