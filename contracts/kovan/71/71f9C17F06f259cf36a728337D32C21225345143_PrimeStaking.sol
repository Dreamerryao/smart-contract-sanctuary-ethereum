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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice The (older) Staking contract gives out a constant number of PRIME tokens per block.
/// It is the only address with minting rights for PRIME.
/// The idea for this Staking V2 (MCV2) contract is therefore to be the owner of a dummy token
/// that is deposited into the Staking V1 (MCV1) contract.
/// The allocation point for this pool on MCV1 is the total allocation point for all pools that receive double incentives.
contract PrimeStaking is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using SignedSafeMath for int256;

  uint256 public constant YEAR_TIMESTAMP = 31536000;

  uint256 public vestingPeriod;

  // Deposit struct to keep track of user's rewards and deposit amounts.
  struct Deposit {
    uint256 depositTimestamp;
    uint256 depositBlock;
    uint256 amount;
    uint256 withdrawTimestamp;
    int256 rewardDebt;
  }

  /// @notice Info of each deposit that stakes LP tokens for each user.
  mapping(uint256 => mapping(address => Deposit[])) public deposits;

  /// @notice Info of each MCV2 pool.
  /// `allocPoint` The amount of allocation points assigned to the pool.
  /// Also known as the amount of PRIME to distribute per block.
  struct PoolInfo {
    uint128 accPrimePerShare;
    uint64 lastRewardBlock;
    uint64 allocPoint;
  }

  /// @notice Address of PRIME contract.
  IERC20 public immutable PRIME;

  /// @notice Info of each MCV2 pool.
  PoolInfo[] public poolInfo;
  /// @notice Address of the LP token for each MCV2 pool.
  IERC20[] public lpToken;
  /// @notice Address of the rewarder.
  address public rewarder;

  /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
  uint256 public totalAllocPoint;

  uint256 private constant ACC_PRIME_PRECISION = 1e12;

  uint256 public primePerBlock;

  event Deposited(
    address indexed user,
    uint256 indexed pid,
    uint256 amount,
    address indexed to
  );
  event Withdraw(
    address indexed user,
    uint256 indexed pid,
    uint256 amount,
    address indexed to
  );
  event EmergencyWithdraw(
    address indexed user,
    uint256 indexed pid,
    uint256 amount,
    address indexed to
  );
  event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
  event HarvestAll(
    address indexed user,
    uint256 indexed pid,
    uint256 totalAmount
  );
  event LogPoolAddition(
    uint256 indexed pid,
    uint256 allocPoint,
    IERC20 indexed lpToken
  );
  event LogSetPool(uint256 indexed pid, uint256 allocPoint);
  event LogUpdatePool(
    uint256 indexed pid,
    uint64 lastRewardBlock,
    uint256 lpSupply,
    uint256 accPrimePerShare
  );
  event LogInit();

  /// @param _prime The PRIME token contract address.
  constructor(IERC20 _prime, address _rewarder) {
    PRIME = _prime;
    rewarder = _rewarder;

    vestingPeriod = YEAR_TIMESTAMP;
    primePerBlock = 1e18;
  }

  /// @notice Returns the number of deposits made by a user.
  /// @param pid The index of the pool.
  /// @param user Address of user whose deposit count should be returned.
  function depositLength(uint256 pid, address user)
    public
    view
    returns (uint256 count)
  {
    require(pid < poolInfo.length, "Pool doesn't exist!");
    count = deposits[pid][user].length;
  }

  function getDeposit(
    uint256 pid,
    address user,
    uint256 depositId
  ) public view returns (Deposit memory) {
    return deposits[pid][user][depositId];
  }

  /// @notice Returns the number of pools.
  function poolLength() public view returns (uint256 pools) {
    pools = poolInfo.length;
  }

  /// @notice Add a new LP to the pool. Can only be called by the owner.
  /// DO NOT add the same LP token more than once. Rewards will be messed up if you do.
  /// @param allocPoint AP of the new pool.
  /// @param _lpToken Address of the LP ERC-20 token.
  function addPool(uint256 allocPoint, IERC20 _lpToken) public onlyOwner {
    uint256 lastRewardBlock = block.number;
    totalAllocPoint = totalAllocPoint.add(allocPoint);
    lpToken.push(_lpToken);

    poolInfo.push(
      PoolInfo({
        allocPoint: uint64(allocPoint),
        lastRewardBlock: uint64(lastRewardBlock),
        accPrimePerShare: 0
      })
    );
    emit LogPoolAddition(lpToken.length.sub(1), allocPoint, _lpToken);
  }

  /// @notice Update the given pool"s PRIME allocation point. Can only be called by the owner.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _allocPoint New AP of the pool.
  function setPoolAllocPoint(uint256 _pid, uint256 _allocPoint)
    public
    onlyOwner
  {
    totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
      _allocPoint
    );
    poolInfo[_pid].allocPoint = uint64(_allocPoint);
    emit LogSetPool(_pid, _allocPoint);
  }

  function setRewarder(address _rewarder) public onlyOwner {
    rewarder = _rewarder;
  }

  /// @notice View function to see pending PRIME on frontend.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _user Address of user.
  /// @param depositId The index of the deposit that the pending rewards are being displayed
  /// @return pending PRIME reward for a given user.
  function pendingPrime(
    uint256 _pid,
    address _user,
    uint256 depositId
  ) external view returns (uint256 pending) {
    PoolInfo memory pool = poolInfo[_pid];
    Deposit storage currentDeposit = deposits[_pid][_user][depositId];
    uint256 accPrimePerShare = pool.accPrimePerShare;
    uint256 lpSupply = lpToken[_pid].balanceOf(address(this));
    if (block.number > pool.lastRewardBlock && lpSupply != 0) {
      uint256 blocks = block.number.sub(pool.lastRewardBlock);
      uint256 primeReward = blocks.mul(primePerBlock).mul(pool.allocPoint) /
        totalAllocPoint;
      accPrimePerShare = uint256(
        accPrimePerShare.add(primeReward.mul(ACC_PRIME_PRECISION) / lpSupply)
      );
    }
    pending = uint256(
      int256(currentDeposit.amount.mul(accPrimePerShare) / ACC_PRIME_PRECISION)
        .sub(currentDeposit.rewardDebt)
    );
  }

  /// @notice Update reward variables for all pools. Be careful of gas spending!
  /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
  function massUpdatePools(uint256[] calldata pids) external {
    uint256 len = pids.length;
    for (uint256 i = 0; i < len; ++i) {
      updatePool(pids[i], 0);
    }
  }

  /// @notice Calculates and returns the `amount` of PRIME per block.
  function setPrimePerBlock(uint256 _primePerBlock) public onlyOwner {
    primePerBlock = _primePerBlock;
  }

  function setVestingPeriod(uint256 _vestingPeriod) public onlyOwner {
    vestingPeriod = _vestingPeriod;
  }

  /// @notice Update reward variables of the given pool.
  /// @param pid The index of the pool. See `poolInfo`.
  /// @param amount The amount to subtract from lpSupply, unused for updatePool invocation after a lpToken deposit
  /// @return pool Returns the pool that was updated.
  function updatePool(uint256 pid, uint256 amount)
    public
    returns (PoolInfo memory pool)
  {
    pool = poolInfo[pid];
    if (block.number > pool.lastRewardBlock) {
      uint256 lpSupply = lpToken[pid].balanceOf(address(this)) - amount;
      if (lpSupply > 0) {
        uint256 blocks = block.number.sub(pool.lastRewardBlock);
        uint256 primeReward = blocks.mul(primePerBlock).mul(pool.allocPoint) /
          totalAllocPoint;
        pool.accPrimePerShare = uint128(
          uint256(pool.accPrimePerShare).add(
            (primeReward.mul(ACC_PRIME_PRECISION) / lpSupply)
          )
        );
      }
      pool.lastRewardBlock = uint64(block.number);
      poolInfo[pid] = pool;
      emit LogUpdatePool(
        pid,
        pool.lastRewardBlock,
        lpSupply,
        pool.accPrimePerShare
      );
    }
  }

  function handleInvokeEchelon(
    address _from,
    address _ethDestination,
    address _primeDestination,
    uint256 _id,
    uint256 _ethValue,
    uint256 _primeValue,
    bytes memory _data
  ) public payable {
    require(
      msg.sender == address(PRIME),
      "Can only be called by the PrimeToken contract"
    );

    // Refund ETH
    if (_ethValue > 0 && _ethDestination == address(this)) {
      (bool sent, bytes memory data) = _from.call{ value: msg.value }("");
      require(sent, "Failed to send ETH");
    }

    // Stake with PRIME
    if (_primeValue > 0 && _primeDestination == address(this)) {
      (uint256 pid, address _to) = abi.decode(_data, (uint256, address));

      // updatePool needs balanceOf(address(this)) before the transfer, but this handler is called after the transfer, we subtract amount
      PoolInfo memory pool = updatePool(pid, _primeValue);

      // Create the Deposit object to be pushed into the user's array of Deposits
      Deposit memory currentDeposit = Deposit({
        depositTimestamp: block.timestamp,
        depositBlock: block.number,
        amount: _primeValue,
        withdrawTimestamp: 0,
        rewardDebt: int256(
          _primeValue.mul(pool.accPrimePerShare) / ACC_PRIME_PRECISION
        )
      });

      // Pushes the previously declared Deposit object into the user's array of Deposits
      deposits[pid][_to].push(currentDeposit);

      emit Deposited(msg.sender, pid, _primeValue, _to);
    }
  }

  /// @notice Deposit LP tokens to MCV2 for PRIME allocation.
  /// @param pid The index of the pool. See `poolInfo`.
  /// @param amount LP token amount to deposit.
  /// @param to The receiver of `amount` deposit benefit.
  function deposit(
    uint256 pid,
    uint256 amount,
    address to
  ) public {
    PoolInfo memory pool = updatePool(pid, 0);

    // Create the Deposit object to be pushed into the user's array of Deposits
    Deposit memory currentDeposit = Deposit({
      depositTimestamp: block.timestamp,
      depositBlock: block.number,
      amount: amount,
      withdrawTimestamp: 0,
      rewardDebt: int256(
        amount.mul(pool.accPrimePerShare) / ACC_PRIME_PRECISION
      )
    });

    // Transfers the PRIME tokens from message sender to this contract
    lpToken[pid].safeTransferFrom(msg.sender, address(this), amount);

    // Pushes the previously declared Deposit object into the user's array of Deposits
    deposits[pid][to].push(currentDeposit);

    emit Deposited(msg.sender, pid, amount, to);
  }

  /// @notice Withdraw LP tokens from MCV2.
  /// @param pid The index of the pool. See `poolInfo`.
  /// @param to Receiver of the LP tokens.
  /// @param depositId The index of the deposit that the user wants to withdraw
  function withdraw(
    uint256 pid,
    address to,
    uint256 depositId
  ) public {
    PoolInfo memory pool = updatePool(pid, 0);
    Deposit storage currentDeposit = deposits[pid][msg.sender][depositId];

    // Check if the deposit has already been withdrawn
    require(currentDeposit.amount != 0, "Deposit has already been withdrawn!");

    // Update the state of the deposit to reflect that it has been withdrawn
    currentDeposit.withdrawTimestamp = block.timestamp;

    // Effects
    currentDeposit.rewardDebt = currentDeposit.rewardDebt.sub(
      int256(
        currentDeposit.amount.mul(pool.accPrimePerShare) / ACC_PRIME_PRECISION
      )
    );

    lpToken[pid].safeTransfer(to, currentDeposit.amount);

    currentDeposit.amount = 0;

    emit Withdraw(msg.sender, pid, currentDeposit.amount, to);
  }

  /// @notice Harvest proceeds for transaction sender to `to`.
  /// @param pid The index of the pool. See `poolInfo`.
  /// @param to Receiver of PRIME rewards.
  /// @param depositId The index of the deposit that the user wants to harvest
  function harvest(
    uint256 pid,
    address to,
    uint256 depositId
  ) public {
    PoolInfo memory pool = updatePool(pid, 0);
    Deposit storage currentDeposit = deposits[pid][msg.sender][depositId];
    uint256 currentTimestamp = block.timestamp;

    // Check if at least 12 months has passed since the initial deposit
    require(
      currentDeposit.depositTimestamp + vestingPeriod < currentTimestamp,
      "The 12 month vesting period is not up!"
    );

    // Calculate pending rewards
    int256 accumulatedPrime = int256(
      currentDeposit.amount.mul(pool.accPrimePerShare) / ACC_PRIME_PRECISION
    );
    uint256 pendingRewards = uint256(
      accumulatedPrime.sub(currentDeposit.rewardDebt)
    );
    uint256 _pendingPrime;

    if (currentDeposit.withdrawTimestamp + vestingPeriod < currentTimestamp) {
      _pendingPrime = pendingRewards;
    } else {
      uint256 timeDifference = currentTimestamp -
        currentDeposit.depositTimestamp;
      uint256 blockDifference = block.number - currentDeposit.depositBlock;
      uint256 pendingPrimePerBlock = pendingRewards.mul(ACC_PRIME_PRECISION) /
        blockDifference;
      uint256 timeDifferenceLeft = timeDifference.sub(vestingPeriod);
      uint256 maturityRatio = timeDifferenceLeft.mul(ACC_PRIME_PRECISION) /
        timeDifference;

      _pendingPrime =
        maturityRatio.mul(blockDifference.mul(pendingPrimePerBlock)) /
        ACC_PRIME_PRECISION /
        ACC_PRIME_PRECISION;
    }

    // Sends out the rewards that is ready to be harvested
    if (_pendingPrime != 0) {
      // Update the state for the deposit that the reward has been claimed
      currentDeposit.rewardDebt = currentDeposit.rewardDebt.add(
        int256(_pendingPrime)
      );
      PRIME.safeTransferFrom(rewarder, to, _pendingPrime);
    }

    emit Harvest(msg.sender, pid, _pendingPrime);
  }

  /// @notice Harvest proceeds for every transaction sender to `to`.
  /// @param pid The index of the pool. See `poolInfo`.
  /// @param to Receiver of PRIME rewards.
  function harvestAll(uint256 pid, address to) public {
    PoolInfo memory pool = updatePool(pid, 0);
    uint256 currentTimestamp = block.timestamp;
    uint256 totalRewards = 0;

    // Iterate through all of the deposits for a certain user
    for (uint256 i = 0; i < deposits[pid][msg.sender].length; i++) {
      Deposit storage currentDeposit = deposits[pid][msg.sender][i];

      // Check if at least 12 months has passed since the initial deposit
      if (currentDeposit.depositTimestamp + vestingPeriod < currentTimestamp) {
        // Calculate pending rewards
        int256 accumulatedPrime = int256(
          currentDeposit.amount.mul(pool.accPrimePerShare) / ACC_PRIME_PRECISION
        );
        uint256 pendingRewards = uint256(
          accumulatedPrime.sub(currentDeposit.rewardDebt)
        );
        uint256 _pendingPrime;

        if (
          currentDeposit.withdrawTimestamp + vestingPeriod < currentTimestamp
        ) {
          _pendingPrime = pendingRewards;
        } else {
          uint256 timeDifference = currentTimestamp -
            currentDeposit.depositTimestamp;
          uint256 blockDifference = block.number - currentDeposit.depositBlock;
          uint256 pendingPrimePerBlock = pendingRewards.mul(
            ACC_PRIME_PRECISION
          ) / blockDifference;
          uint256 timeDifferenceLeft = timeDifference.sub(vestingPeriod);
          uint256 maturityRatio = timeDifferenceLeft.mul(ACC_PRIME_PRECISION) /
            timeDifference;

          _pendingPrime =
            maturityRatio.mul(blockDifference.mul(pendingPrimePerBlock)) /
            ACC_PRIME_PRECISION /
            ACC_PRIME_PRECISION;
        }

        // Update the state for the deposit that the reward has been claimed
        currentDeposit.rewardDebt = currentDeposit.rewardDebt.add(
          int256(_pendingPrime)
        );

        // Add the pending rewards to a accumulator
        totalRewards.add(_pendingPrime);
      }
    }

    // Sends out the rewards equal to the amount in the accumulator
    if (totalRewards != 0) {
      PRIME.safeTransferFrom(rewarder, to, totalRewards);
    }
    emit HarvestAll(msg.sender, pid, totalRewards);
  }

  /// @notice Withdraw LP tokens from MCV2 and harvest proceeds for transaction sender to `to`.
  /// @param pid The index of the pool. See `poolInfo`.
  /// @param to Receiver of the LP tokens and PRIME rewards.
  /// @param depositId The index of the deposit that the user wants to withdraw and harvest
  function withdrawAndHarvest(
    uint256 pid,
    address to,
    uint256 depositId
  ) public {
    PoolInfo memory pool = updatePool(pid, 0);
    Deposit storage currentDeposit = deposits[pid][msg.sender][depositId];

    // Check if the deposit has already been withdrawn
    require(currentDeposit.amount != 0, "Deposit has already been withdrawn!");

    // Check if at least 12 months has passed since the initial deposit
    uint256 currentTimestamp = block.timestamp;
    require(
      currentDeposit.depositTimestamp + vestingPeriod < currentTimestamp,
      "The 12 month vesting period is not up!"
    );

    // Withdraw deposit amount
    currentDeposit.withdrawTimestamp = currentTimestamp;
    currentDeposit.rewardDebt = currentDeposit.rewardDebt.sub(
      int256(
        currentDeposit.amount.mul(pool.accPrimePerShare) / ACC_PRIME_PRECISION
      )
    );
    lpToken[pid].safeTransfer(to, currentDeposit.amount);
    currentDeposit.amount = 0;

    // Calculate pending rewards
    int256 accumulatedPrime = int256(
      currentDeposit.amount.mul(pool.accPrimePerShare) / ACC_PRIME_PRECISION
    );
    uint256 pendingRewards = uint256(
      accumulatedPrime.sub(currentDeposit.rewardDebt)
    );
    uint256 _pendingPrime;

    if (currentDeposit.withdrawTimestamp + vestingPeriod < currentTimestamp) {
      _pendingPrime = pendingRewards;
    } else {
      uint256 timeDifference = currentTimestamp -
        currentDeposit.depositTimestamp;
      uint256 blockDifference = block.number - currentDeposit.depositBlock;
      uint256 pendingPrimePerBlock = pendingRewards.mul(ACC_PRIME_PRECISION) /
        blockDifference;
      uint256 timeDifferenceLeft = timeDifference.sub(vestingPeriod);
      uint256 maturityRatio = timeDifferenceLeft.mul(ACC_PRIME_PRECISION) /
        timeDifference;

      _pendingPrime =
        maturityRatio.mul(blockDifference.mul(pendingPrimePerBlock)) /
        ACC_PRIME_PRECISION /
        ACC_PRIME_PRECISION;
    }

    // Withdraw the staked rewards, and update the state of the deposit remaining rewards
    if (_pendingPrime != 0) {
      currentDeposit.rewardDebt = currentDeposit.rewardDebt.add(
        int256(_pendingPrime)
      );
      PRIME.safeTransferFrom(rewarder, to, _pendingPrime);
    }

    emit Withdraw(msg.sender, pid, currentDeposit.amount, to);
    emit Harvest(msg.sender, pid, _pendingPrime);
  }
}