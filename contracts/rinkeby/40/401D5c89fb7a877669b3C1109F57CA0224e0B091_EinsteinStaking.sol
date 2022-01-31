/**
 *Submitted for verification at Etherscan.io on 2021-12-31
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: stakingTest.sol


pragma solidity ^0.8.7;





interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract EinsteinStaking is
    Ownable,
    Pausable,
    ReentrancyGuard
{
    using SafeMath for uint256;
    string public constant name = "EINSTEIN - Staking";

    IERC20 public stakeToken; // Token which users stake to get reward
    IERC20 public rewardToken; // holds token address which we are giving it as reward
    uint256 public rewardRate; // APR of the staking
    uint256 public startTime; // Block number after which reward should start
    uint256 public endTime; // End time of staking
    uint256 public rewardInterval; // Time difference for calculating reward, eg., Day, Months, Years, etc.,
    address[] public stakers;
    mapping(address => uint256) public stakingStartTime; // to manage the time when the user started the staking
    mapping(address => uint256) public stakedBalance; // to manage the staking of token A  and distibue the profit as token B
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;
    mapping(address => uint256) public oldReward; // Stores the old reward
    uint256 public _totalStakedAmount; // Total amount of tokens that users have staked
    mapping(address => uint256) public userTimeBounds; // mapping stores the withdraw time request
    uint256 public timeBound;

    // Upgraded state variables
    mapping(address => uint256[]) public stakingTimestamps;
    mapping(address => uint256[]) public stakedBalances;
    mapping(address => uint256) public userStakeCount;
    mapping(address => uint256) public claimedReward; // Accumulated reward for each user which is subtracted every time user withdraws

    event Reward(address indexed from, address indexed to, uint256 amount);
    event StakedToken(address indexed from, address indexed to, uint256 amount);
    event UnStakedToken(
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event WithdrawnFromStakedBalance(address indexed user, uint256 amount);
    event ExternalTokenTransferred(
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event EthFromContractTransferred(uint256 amount);
    event UpdatedRewardRate(uint256 rate);
    event UpdatedRewardToken(IERC20 token);
    event UpdatedRewardInterval(uint256 interval);
    event UpdatedStakingEndTime(uint256 endTime);
    event WithdrawRequested(address indexed to);
    event TimeBoundChanged(uint256 newTimeBound);

    constructor() {
        stakeToken = IERC20(0x3A52F6D452f74735b2db052fA295cCbDDC38B3B2);
        rewardToken = IERC20(0x3A52F6D452f74735b2db052fA295cCbDDC38B3B2);
        rewardRate = 20;
        startTime = 1638789600;
        rewardInterval = 30;
        timeBound = 20;

        address[3] memory users = [0xa6510E349be7786200AC9eDC6443D09FE486Cb40, 0xbCC2d6fD76c84Ca240321E87AF74Aa159B155E93, 0x674EB6965EAb2B66571966b56f9747698E9AD9d0];
        uint256[3] memory amounts = [uint256(100), uint256(200), uint256(300)];
        for(uint i = 0; i < users.length; i++) {
            stakedBalances[users[i]].push(amounts[i]); // update user staking balance
            stakingTimestamps[users[i]].push(block.timestamp); // update user staking start time for this stake amount
            stakedBalance[users[i]] = stakedBalance[users[i]] + amounts[i]; // update user staked balance
            userStakeCount[users[i]]++; // increment user stake count
            _totalStakedAmount += amounts[i]; // update Contract Staking balance
            stakingStartTime[users[i]] = block.timestamp; // save the time when they started staking
            // update staking status
            isStaking[users[i]] = true;
            hasStaked[users[i]] = true;
        }
    }

    //    constructor() initializer {}

    /* Stakes Tokens (Deposit): An investor will deposit the stakeToken into the smart contracts
    to starting earning rewards.

    Core Thing: Transfer the stakeToken from the investor's wallet to this smart contract. */
    function stakeTokenForReward(uint256 _amount)
        external
        virtual
        nonReentrant
        whenNotPaused
    {
        require(
            block.timestamp >= startTime,
            "STAKING: Start Block has not reached"
        );
        if (endTime > 0)
            require(block.timestamp <= endTime, "STAKING: Has ended");
        require(_amount > 0, "STAKING: Balance cannot be 0"); // Staking amount cannot be zero
        require(
            stakeToken.balanceOf(msg.sender) >= _amount,
            "STAKING: Insufficient stake token balance"
        ); // Checking msg.sender balance

        // add user to stakers array *only* if they haven't staked already
        if (!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }
        if (isStaking[msg.sender]) {
            // (uint256 oldR, ) = estimateReward(msg.sender);
            // oldReward[msg.sender] = oldReward[msg.sender] + oldR;
        }

        bool transferStatus = stakeToken.transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        if (transferStatus) {
            emit StakedToken(msg.sender, address(this), _amount);
            stakedBalances[msg.sender].push(_amount); // update user staking balance
            stakingTimestamps[msg.sender].push(block.timestamp); // update user staking start time for this stake amount
            stakedBalance[msg.sender] = stakedBalance[msg.sender] + _amount; // update user staked balance
            userStakeCount[msg.sender]++; // increment user stake count
            _totalStakedAmount += _amount; // update Contract Staking balance
            stakingStartTime[msg.sender] = block.timestamp; // save the time when they started staking
            // update staking status
            isStaking[msg.sender] = true;
            hasStaked[msg.sender] = true;
        }
    }

    function unStakeToken() external virtual nonReentrant whenNotPaused {
        require(
            isStaking[msg.sender],
            "STAKING: No staked token balance available"
        );
        uint256 balance = stakedBalance[msg.sender];
        require(balance > 0, "STAKING: Balance cannot be 0");
        require(
            stakeToken.balanceOf(address(this)) >= balance,
            "STAKING: Not enough stake token balance"
        );
        require(
            userTimeBounds[msg.sender] > 0,
            "STAKING: Request withdraw before withdraw"
        );
        require(
            block.timestamp >= (userTimeBounds[msg.sender] + timeBound),
            "STAKING: Cannot withdraw within un-bound time period"
        );

        (uint256 reward, ) = calculateReward(msg.sender);
        bool status = SendRewardTo(reward, msg.sender); // Checks if the contract has enough tokens to reward or not
        require(status, "STAKING: Reward transfer failed");
        claimedReward[msg.sender] = claimedReward[msg.sender] + reward;

        // unstaking of staked tokens
        bool transferStatus = stakeToken.transfer(msg.sender, balance);
        if (transferStatus) {
            emit UnStakedToken(address(this), msg.sender, balance);
            _totalStakedAmount -= balance;
            stakedBalance[msg.sender] = 0; // reset staking balance
            isStaking[msg.sender] = false; // update staking status and stakingStartTime (restore to zero)
            stakingStartTime[msg.sender] = 0;
            delete stakedBalances[msg.sender]; // update user staking balance
            delete stakingTimestamps[msg.sender]; // update user staking start time for this stake amount
            userStakeCount[msg.sender] = 0; // increment user stake count
            claimedReward[msg.sender] = 0; // reset user claimed reward
        }
        userTimeBounds[msg.sender] = 0;
    }

    /* @dev check if the reward token is same as the staking token
    If staking token and reward token is same then -
    Contract should always contain more or equal tokens than staked tokens
    Because staked tokens are the locked amount that staker can unstake any time */
    function SendRewardTo(uint256 calculatedReward, address _toAddress)
        internal
        virtual
        returns (bool)
    {
        require(_toAddress != address(0), "STAKING: Address cannot be zero");
        require(
            rewardToken.balanceOf(address(this)) >= calculatedReward,
            "STAKING: Not enough reward balance"
        );

        bool successStatus = false;
        if (
            rewardToken.balanceOf(address(this)) > calculatedReward &&
            calculatedReward > 0
        ) {
            if (stakeToken == rewardToken) {
                if (
                    (rewardToken.balanceOf(address(this)) - calculatedReward) <
                    _totalStakedAmount
                ) {
                    calculatedReward = 0;
                }
            }
            if (calculatedReward > 0) {
                bool transferStatus = rewardToken.transfer(
                    _toAddress,
                    calculatedReward
                );
                require(transferStatus, "STAKING: Transfer Failed");
                oldReward[_toAddress] = 0;
                emit Reward(address(this), _toAddress, calculatedReward);
                successStatus = true;
            }
        }
        return successStatus;
    }

    /*
    @dev calculateReward() function returns the reward of the caller of this function
    */
    function estimateReward(address _rewardAddress)
        public
        view
        returns (uint256, uint256)
    {
        uint256 balances = stakedBalance[_rewardAddress] / 10**18;
        uint256 rewards = 0;
        uint256 timeDifferences;
        if (balances > 0) {
            if (endTime > 0) {
                if (block.timestamp > endTime) {
                    timeDifferences = endTime.sub(
                        stakingStartTime[_rewardAddress]
                    );
                } else {
                    timeDifferences =
                        block.timestamp -
                        stakingStartTime[_rewardAddress];
                }
            } else {
                timeDifferences =
                    block.timestamp -
                    stakingStartTime[_rewardAddress];
            }
            /* reward calculation
            Reward  = ((Total staked amount / User Staked Amount * 100) + timeFactor + Reward Rate (APY)) * User Staked Amount / 100
            */
            uint256 timeFactor = timeDifferences.div(60).div(60).div(24).div(7); //consider week
            uint256 apyFactorInWei = (rewardRate * timeFactor) / 52;
            rewards = ((((((balances * 100) / (_totalStakedAmount / 10**18)) *
                (10**18)) +
                (timeFactor * (10**18)) +
                apyFactorInWei) * balances) / 100);
        }
        return (rewards, timeDifferences);
    }

    /*
    @dev calculateReward() function returns the reward of the caller of this function
    */
    function calculateReward(address _rewardAddress)
        public
        view
        returns (uint256, uint256)
    {
        uint256 balances;
        uint256 rewards = 0;
        uint256 timeDifferences;
        for (uint256 i = 0; i < userStakeCount[_rewardAddress]; i++) {
            if (
                block.timestamp >=
                stakingTimestamps[_rewardAddress][i] + rewardInterval
            ) {
                balances =
                    balances +
                    stakedBalances[_rewardAddress][i] /
                    10**18;
                if (balances > 0) {
                    if (endTime > 0) {
                        if (block.timestamp > endTime) {
                            timeDifferences = endTime.sub(
                                stakingTimestamps[_rewardAddress][i]
                            );
                        } else {
                            timeDifferences =
                                block.timestamp -
                                stakingTimestamps[_rewardAddress][i];
                        }
                    } else {
                        timeDifferences =
                            block.timestamp -
                            stakingTimestamps[_rewardAddress][i];
                    }
                    uint256 timeFactor = timeDifferences
                        .div(60)
                        .div(60)
                        .div(24)
                        .div(7); //consider week
                    uint256 apyFactorInWei = (rewardRate * timeFactor) / 52;
                    rewards =
                        rewards +
                        ((((((balances * 100) / (_totalStakedAmount / 10**18)) *
                            (10**18)) +
                            (timeFactor * (10**18)) +
                            apyFactorInWei) * balances) / 100);
                }
            } else {
                break;
            }
        }
        uint256 totalReward = (rewards + oldReward[_rewardAddress]) - claimedReward[_rewardAddress];
        return (totalReward, timeDifferences);
    }

    /*
    @dev Users withdraw balance from the staked balance, reduced directly from the staked balance
    */
    function withdrawFromStakedBalance(uint256 amount)
        external
        virtual
        nonReentrant
        whenNotPaused
    {
        require(
            isStaking[msg.sender],
            "STAKING: No staked token balance available"
        );
        require(amount > 0, "STAKING: Cannot withdraw 0");
        require(
            userTimeBounds[msg.sender] > 0,
            "STAKING: Request withdraw before withdraw"
        );
        require(
            block.timestamp >= (userTimeBounds[msg.sender] + timeBound),
            "STAKING: Cannot withdraw within interval period"
        );
        (uint256 oldRewardAmount, ) = calculateReward(msg.sender);
        if (
            oldRewardAmount > 0 &&
            oldRewardAmount <= rewardToken.balanceOf(address(this))
        ) {
            oldReward[msg.sender] = oldReward[msg.sender] + oldRewardAmount;
        }
        stakedBalance[msg.sender] = stakedBalance[msg.sender].sub(amount);
        _totalStakedAmount -= amount;
        bool transferStatus = stakeToken.transfer(msg.sender, amount);
        require(transferStatus, "STAKING: Transfer Failed");
        emit WithdrawnFromStakedBalance(msg.sender, amount);
        userTimeBounds[msg.sender] = 0;
    }

    /* @dev returns the total staked tokens
    and it is independent of the total tokens the contract keeps
    */
    function getTotalStaked() external view returns (uint256) {
        return _totalStakedAmount;
    }

    /*
    @dev function used to claim only the reward for the caller of the method
    */
    function claimMyReward() external nonReentrant whenNotPaused {
        require(
            isStaking[msg.sender],
            "STAKING: No staked token balance available"
        );
        uint256 balance = stakedBalance[msg.sender];
        require(balance > 0, "STAKING: Balance cannot be 0");
        (uint256 reward, uint256 timeDifferences) = calculateReward(msg.sender);
        require(reward > 0, "STAKING: Calculated Reward zero");
        require(
            timeDifferences / rewardInterval >= 1,
            "STAKING: Can be claimed only after the interval"
        );
        uint256 rewardTokens = rewardToken.balanceOf(address(this));
        require(
            rewardTokens > reward,
            "STAKING: Not Enough Reward Balance"
        );
        bool rewardSuccessStatus = SendRewardTo(reward, msg.sender);
        //stakingStartTime (set to current time)
        require(rewardSuccessStatus, "STAKING: Claim Reward Failed");
        claimedReward[msg.sender] = claimedReward[msg.sender] + reward;
        stakingStartTime[msg.sender] = block.timestamp;
    }

    function withdrawERC20Token(address _tokenContract, uint256 _amount)
        external
        virtual
        onlyOwner
    {
        require(
            _tokenContract != address(0),
            "STAKING: Address cant be zero address"
        ); // 0 address validation
        require(_amount > 0, "STAKING: amount cannot be 0"); // require amount greater than 0
        IERC20 tokenContract = IERC20(_tokenContract);
        require(tokenContract.balanceOf(address(this)) > _amount);
        bool transferStatus = tokenContract.transfer(msg.sender, _amount);
        require(transferStatus, "STAKING: Transfer Failed");
        emit ExternalTokenTransferred(_tokenContract, msg.sender, _amount);
    }

    function getBalance() internal view returns (uint256) {
        return address(this).balance;
    }

    /*
    @dev setting reward rate in weiAmount
    */
    function setRewardRate(uint256 _rewardRate)
        external
        virtual
        onlyOwner
        whenNotPaused
    {
        rewardRate = _rewardRate;
        emit UpdatedRewardRate(_rewardRate);
    }

    /*
    @dev setting reward token address
    */
    function setRewardToken(IERC20 _rewardToken)
        external
        virtual
        onlyOwner
        whenNotPaused
    {
        rewardToken = _rewardToken;
        emit UpdatedRewardToken(rewardToken);
    }

    /*
    @dev setting reward interval
    */
    function setRewardInterval(uint256 _rewardInterval)
        external
        virtual
        onlyOwner
        whenNotPaused
    {
        rewardInterval = _rewardInterval;
        emit UpdatedRewardInterval(rewardInterval);
    }

    /*
    @dev setting staking end time
    */
    function setStakingEndTime(uint256 _endTime)
        external
        virtual
        onlyOwner
        whenNotPaused
    {
        endTime = _endTime;
        emit UpdatedStakingEndTime(_endTime);
    }

    /*
    @Dev user request for a withdraw
*/
    function requestWithdraw() external virtual whenNotPaused {
        userTimeBounds[msg.sender] = block.timestamp;
        emit WithdrawRequested(msg.sender);
    }

    function setTimeBound(uint256 _newTimeBound)
        external
        virtual
        onlyOwner
        whenNotPaused
    {
        timeBound = _newTimeBound;
        emit TimeBoundChanged(timeBound);
    }

    function upgradeUsers(
        address userAddress,
        uint256[] memory balances,
        uint256[] memory timestamps,
        uint256 _claimedReward
    ) public onlyOwner {
        for (uint256 i = 0; i < balances.length; i++) {
            stakedBalances[userAddress].push(balances[i]);
            stakingTimestamps[userAddress].push(timestamps[i]);
            userStakeCount[userAddress]++;
        }
        claimedReward[userAddress] = _claimedReward;
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}