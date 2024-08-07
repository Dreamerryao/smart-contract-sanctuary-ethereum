// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

/* solhint-disable func-name-mixedcase */

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface ISwapManager {
    event OracleCreated(address indexed _sender, address indexed _newOracle, uint256 _period);

    function N_DEX() external view returns (uint256);

    function ROUTERS(uint256 i) external view returns (IUniswapV2Router02);

    function bestOutputFixedInput(
        address _from,
        address _to,
        uint256 _amountIn
    )
        external
        view
        returns (
            address[] memory path,
            uint256 amountOut,
            uint256 rIdx
        );

    function bestPathFixedInput(
        address _from,
        address _to,
        uint256 _amountIn,
        uint256 _i
    ) external view returns (address[] memory path, uint256 amountOut);

    function bestInputFixedOutput(
        address _from,
        address _to,
        uint256 _amountOut
    )
        external
        view
        returns (
            address[] memory path,
            uint256 amountIn,
            uint256 rIdx
        );

    function bestPathFixedOutput(
        address _from,
        address _to,
        uint256 _amountOut,
        uint256 _i
    ) external view returns (address[] memory path, uint256 amountIn);

    function safeGetAmountsOut(
        uint256 _amountIn,
        address[] memory _path,
        uint256 _i
    ) external view returns (uint256[] memory result);

    function unsafeGetAmountsOut(
        uint256 _amountIn,
        address[] memory _path,
        uint256 _i
    ) external view returns (uint256[] memory result);

    function safeGetAmountsIn(
        uint256 _amountOut,
        address[] memory _path,
        uint256 _i
    ) external view returns (uint256[] memory result);

    function unsafeGetAmountsIn(
        uint256 _amountOut,
        address[] memory _path,
        uint256 _i
    ) external view returns (uint256[] memory result);

    function comparePathsFixedInput(
        address[] memory pathA,
        address[] memory pathB,
        uint256 _amountIn,
        uint256 _i
    ) external view returns (address[] memory path, uint256 amountOut);

    function comparePathsFixedOutput(
        address[] memory pathA,
        address[] memory pathB,
        uint256 _amountOut,
        uint256 _i
    ) external view returns (address[] memory path, uint256 amountIn);

    function ours(address a) external view returns (bool);

    function oracleCount() external view returns (uint256);

    function oracleAt(uint256 idx) external view returns (address);

    function getOracle(
        address _tokenA,
        address _tokenB,
        uint256 _period,
        uint256 _i
    ) external view returns (address);

    function createOrUpdateOracle(
        address _tokenA,
        address _tokenB,
        uint256 _period,
        uint256 _i
    ) external returns (address oracleAddr);

    function consultForFree(
        address _from,
        address _to,
        uint256 _amountIn,
        uint256 _period,
        uint256 _i
    ) external view returns (uint256 amountOut, uint256 lastUpdatedAt);

    /// get the data we want and pay the gas to update
    function consult(
        address _from,
        address _to,
        uint256 _amountIn,
        uint256 _period,
        uint256 _i
    )
        external
        returns (
            uint256 amountOut,
            uint256 lastUpdatedAt,
            bool updated
        );

    function updateOracles() external returns (uint256 updated, uint256 expected);

    function updateOracles(address[] memory _oracleAddrs) external returns (uint256 updated, uint256 expected);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

interface IConvex {
    function poolInfo(uint256)
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address,
            bool
        );

    // deposit lp tokens and stake
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    // deposit all lp tokens and stake
    function depositAll(uint256 _pid, bool _stake) external returns (bool);

    // withdraw lp tokens
    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    // withdraw all lp tokens
    function withdrawAll(uint256 _pid) external returns (bool);

    // claim crv + extra rewards
    function earmarkRewards(uint256 _pid) external returns (bool);

    // claim  rewards on stash (msg.sender == stash)
    function claimRewards(uint256 _pid, address _gauge) external returns (bool);

    // delegate address votes on dao (needs to be voteDelegate)
    function vote(
        uint256 _voteId,
        address _votingAddress,
        bool _support
    ) external returns (bool);

    function voteGaugeWeight(address[] calldata _gauge, uint256[] calldata _weight) external returns (bool);
}

interface Rewards {
    function pid() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function extraRewardsLength() external view returns (uint256);

    function extraRewards(uint256) external view returns (address);

    function rewardPerToken() external view returns (uint256);

    function rewardPerTokenStored() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function rewardToken() external view returns (address);

    function rewards(address) external view returns (uint256);

    function userRewardPerTokenPaid(address) external view returns (uint256);

    function stakingToken() external view returns (address);

    function stake(uint256) external returns (bool);

    function stakeAll() external returns (bool);

    function stakeFor(address, uint256) external returns (bool);

    function withdraw(uint256 amount, bool claim) external returns (bool);

    function withdrawAll(bool claim) external returns (bool);

    function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);

    function withdrawAllAndUnwrap(bool claim) external;

    function getReward() external returns (bool);

    function getReward(address _account, bool _claimExtras) external returns (bool);

    function donate(uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

interface IConvexToken {
    function maxSupply() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function reductionPerCliff() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.8.3;

interface IDepositZap4x {
    function calc_token_amount(
        address _pool,
        uint256[4] memory _amounts,
        bool is_deposit
    ) external view returns (uint256);

    function add_liquidity(
        address _pool,
        uint256[4] memory _amounts,
        uint256 _min_mint_amount
    ) external;

    function remove_liquidity(
        address _pool,
        uint256 _amount,
        uint256[4] memory _min_amounts
    ) external;

    function remove_liquidity_one_coin(
        address _pool,
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external;

    function calc_withdraw_one_coin(
        address _pool,
        uint256 _token_amount,
        int128 i
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Not a complete interface, but should have what we need
interface ILiquidityGaugeV2 is IERC20 {
    function deposit(uint256 _value) external;

    function deposit(uint256 _value, address addr) external;

    function withdraw(uint256 _value) external;

    function claim_rewards(address addr) external;

    function claimable_tokens(address addr) external returns (uint256);

    function claimable_reward(address, address) external returns (uint256);

    function integrate_fraction(address addr) external view returns (uint256);

    function user_checkpoint(address addr) external returns (bool);

    function reward_integral(address) external view returns (uint256);

    function reward_integral_for(address, address) external view returns (uint256);

    function lp_token() external view returns (address);

    function reward_count() external view returns (uint256);

    function reward_tokens(uint256 _i) external view returns (address);
}

interface ILiquidityGaugeV3 is ILiquidityGaugeV2 {
    function claimable_reward(address addr, address token) external view override returns (uint256);
}

/* solhint-enable */

// SPDX-License-Identifier: MIT

/* solhint-disable func-name-mixedcase*/
pragma solidity 0.8.3;

interface IMetapoolFactory {
    function get_underlying_coins(address _pool) external view returns (address[8] memory _coins);

    function get_underlying_decimals(address _pool) external view returns (uint256[8] memory _decimals);
}

// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.8.3;

// Not a complete interface, but should have what we need
interface IStableSwap {
    function coins(uint256 i) external view returns (address);

    function fee() external view returns (uint256); // fee * 1e10

    function lp_token() external view returns (address);

    function A() external view returns (uint256);

    function A_precise() external view returns (uint256);

    function balances(uint256 i) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external;
}

interface IStableSwapV2 {
    function coins(int128 i) external view returns (address);
}

interface IStableSwapUnderlying is IStableSwap {
    function underlying_coins(uint256 i) external view returns (address);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount,
        bool _use_underlying
    ) external;
}

interface IStableSwap2x is IStableSwap {
    function calc_token_amount(uint256[2] memory _amounts, bool is_deposit) external view returns (uint256);

    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external;

    function remove_liquidity(uint256 _amount, uint256[2] memory _min_amounts) external;

    function remove_liquidity_imbalance(uint256[2] memory _amounts, uint256 _max_burn_amount)
        external
        returns (uint256);
}

interface IStableSwap3x is IStableSwap {
    function calc_token_amount(uint256[3] memory _amounts, bool is_deposit) external view returns (uint256);

    function add_liquidity(uint256[3] memory _amounts, uint256 _min_mint_amount) external;

    function remove_liquidity(uint256 _amount, uint256[3] memory _min_amounts) external;

    function remove_liquidity_imbalance(uint256[3] memory _amounts, uint256 _max_burn_amount)
        external
        returns (uint256);
}

interface IStableSwap4x is IStableSwap {
    function calc_token_amount(uint256[4] memory _amounts, bool is_deposit) external view returns (uint256);

    function add_liquidity(uint256[4] memory _amounts, uint256 _min_mint_amount) external;

    function remove_liquidity(uint256 _amount, uint256[4] memory _min_amounts) external;

    function remove_liquidity_imbalance(uint256[4] memory _amounts, uint256 _max_burn_amount)
        external
        returns (uint256);
}

interface IStableSwap2xUnderlying is IStableSwap2x, IStableSwapUnderlying {
    function add_liquidity(
        uint256[2] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external;

    function remove_liquidity_imbalance(
        uint256[2] calldata amounts,
        uint256 max_burn_amount,
        bool use_underlying
    ) external;

    function remove_liquidity(
        uint256 amount,
        uint256[2] calldata min_amounts,
        bool use_underlying
    ) external;
}

interface IStableSwap3xUnderlying is IStableSwap3x, IStableSwapUnderlying {
    function add_liquidity(
        uint256[3] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external;

    function remove_liquidity_imbalance(
        uint256[3] calldata amounts,
        uint256 max_burn_amount,
        bool use_underlying
    ) external;

    function remove_liquidity(
        uint256 amount,
        uint256[3] calldata min_amounts,
        bool use_underlying
    ) external;
}

interface IStableSwap4xUnderlying is IStableSwap4x, IStableSwapUnderlying {
    function add_liquidity(
        uint256[4] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying
    ) external;

    function remove_liquidity_imbalance(
        uint256[4] calldata amounts,
        uint256 max_burn_amount,
        bool use_underlying
    ) external;

    function remove_liquidity(
        uint256 amount,
        uint256[4] calldata min_amounts,
        bool use_underlying
    ) external;
}

/* solhint-enable */

// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.8.3;

// Not a complete interface, but should have what we need
interface ITokenMinter {
    function minted(address arg0, address arg1) external view returns (uint256);

    function mint(address gauge_addr) external;
}
/* solhint-enable */

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

interface IStrategy {
    function rebalance() external;

    function sweepERC20(address _fromToken) external;

    function withdraw(uint256 _amount) external;

    function feeCollector() external view returns (address);

    function isReservedToken(address _token) external view returns (bool);

    function keepers() external view returns (address[] memory);

    function migrate(address _newStrategy) external;

    function token() external view returns (address);

    function totalValue() external view returns (uint256);

    function totalValueCurrent() external returns (uint256);

    function pool() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVesperPool is IERC20 {
    function deposit() external payable;

    function deposit(uint256 _share) external;

    function multiTransfer(address[] memory _recipients, uint256[] memory _amounts) external returns (bool);

    function excessDebt(address _strategy) external view returns (uint256);

    function permit(
        address,
        address,
        uint256,
        uint256,
        uint8,
        bytes32,
        bytes32
    ) external;

    function poolRewards() external returns (address);

    function reportEarning(
        uint256 _profit,
        uint256 _loss,
        uint256 _payback
    ) external;

    function reportLoss(uint256 _loss) external;

    function resetApproval() external;

    function sweepERC20(address _fromToken) external;

    function withdraw(uint256 _amount) external;

    function withdrawETH(uint256 _amount) external;

    function whitelistedWithdraw(uint256 _amount) external;

    function governor() external view returns (address);

    function keepers() external view returns (address[] memory);

    function isKeeper(address _address) external view returns (bool);

    function maintainers() external view returns (address[] memory);

    function isMaintainer(address _address) external view returns (bool);

    function feeCollector() external view returns (address);

    function pricePerShare() external view returns (uint256);

    function strategy(address _strategy)
        external
        view
        returns (
            bool _active,
            uint256 _interestFee,
            uint256 _debtRate,
            uint256 _lastRebalance,
            uint256 _totalDebt,
            uint256 _totalLoss,
            uint256 _totalProfit,
            uint256 _debtRatio
        );

    function stopEverything() external view returns (bool);

    function token() external view returns (IERC20);

    function tokensHere() external view returns (uint256);

    function totalDebtOf(address _strategy) external view returns (uint256);

    function totalValue() external view returns (uint256);

    function withdrawFee() external view returns (uint256);

    // Function to get pricePerShare from V2 pools
    function getPricePerShare() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "../dependencies/openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/bloq/ISwapManager.sol";
import "../interfaces/vesper/IStrategy.sol";
import "../interfaces/vesper/IVesperPool.sol";

abstract contract Strategy is IStrategy, Context {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 internal constant MAX_UINT_VALUE = type(uint256).max;

    // solhint-disable-next-line  var-name-mixedcase
    address internal WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IERC20 public immutable collateralToken;
    address public receiptToken;
    address public immutable override pool;
    address public override feeCollector;
    ISwapManager public swapManager;

    uint256 public oraclePeriod = 3600; // 1h
    uint256 public oracleRouterIdx = 0; // Uniswap V2
    uint256 public swapSlippage = 10000; // 100% Don't use oracles by default

    EnumerableSet.AddressSet private _keepers;

    event UpdatedFeeCollector(address indexed previousFeeCollector, address indexed newFeeCollector);
    event UpdatedSwapManager(address indexed previousSwapManager, address indexed newSwapManager);
    event UpdatedSwapSlippage(uint256 oldSwapSlippage, uint256 newSwapSlippage);
    event UpdatedOracleConfig(uint256 oldPeriod, uint256 newPeriod, uint256 oldRouterIdx, uint256 newRouterIdx);

    constructor(
        address _pool,
        address _swapManager,
        address _receiptToken
    ) {
        require(_pool != address(0), "pool-address-is-zero");
        require(_swapManager != address(0), "sm-address-is-zero");
        swapManager = ISwapManager(_swapManager);
        pool = _pool;
        collateralToken = IVesperPool(_pool).token();
        receiptToken = _receiptToken;
        require(_keepers.add(_msgSender()), "add-keeper-failed");
    }

    modifier onlyGovernor {
        require(_msgSender() == IVesperPool(pool).governor(), "caller-is-not-the-governor");
        _;
    }

    modifier onlyKeeper() {
        require(_keepers.contains(_msgSender()), "caller-is-not-a-keeper");
        _;
    }

    modifier onlyPool() {
        require(_msgSender() == pool, "caller-is-not-vesper-pool");
        _;
    }

    /**
     * @notice Add given address in keepers list.
     * @param _keeperAddress keeper address to add.
     */
    function addKeeper(address _keeperAddress) external onlyGovernor {
        require(_keepers.add(_keeperAddress), "add-keeper-failed");
    }

    /// @notice Return list of keepers
    function keepers() external view override returns (address[] memory) {
        return _keepers.values();
    }

    /**
     * @notice Migrate all asset and vault ownership,if any, to new strategy
     * @dev _beforeMigration hook can be implemented in child strategy to do extra steps.
     * @param _newStrategy Address of new strategy
     */
    function migrate(address _newStrategy) external virtual override onlyPool {
        require(_newStrategy != address(0), "new-strategy-address-is-zero");
        require(IStrategy(_newStrategy).pool() == pool, "not-valid-new-strategy");
        _beforeMigration(_newStrategy);
        IERC20(receiptToken).safeTransfer(_newStrategy, IERC20(receiptToken).balanceOf(address(this)));
        collateralToken.safeTransfer(_newStrategy, collateralToken.balanceOf(address(this)));
    }

    /**
     * @notice Remove given address from keepers list.
     * @param _keeperAddress keeper address to remove.
     */
    function removeKeeper(address _keeperAddress) external onlyGovernor {
        require(_keepers.remove(_keeperAddress), "remove-keeper-failed");
    }

    /**
     * @notice Update fee collector
     * @param _feeCollector fee collector address
     */
    function updateFeeCollector(address _feeCollector) external onlyGovernor {
        require(_feeCollector != address(0), "fee-collector-address-is-zero");
        require(_feeCollector != feeCollector, "fee-collector-is-same");
        emit UpdatedFeeCollector(feeCollector, _feeCollector);
        feeCollector = _feeCollector;
    }

    /**
     * @notice Update swap manager address
     * @param _swapManager swap manager address
     */
    function updateSwapManager(address _swapManager) external onlyGovernor {
        require(_swapManager != address(0), "sm-address-is-zero");
        require(_swapManager != address(swapManager), "sm-is-same");
        emit UpdatedSwapManager(address(swapManager), _swapManager);
        swapManager = ISwapManager(_swapManager);
    }

    function updateSwapSlippage(uint256 _newSwapSlippage) external onlyGovernor {
        require(_newSwapSlippage <= 10000, "invalid-slippage-value");
        emit UpdatedSwapSlippage(swapSlippage, _newSwapSlippage);
        swapSlippage = _newSwapSlippage;
    }

    function updateOracleConfig(uint256 _newPeriod, uint256 _newRouterIdx) external onlyGovernor {
        require(_newRouterIdx < swapManager.N_DEX(), "invalid-router-index");
        if (_newPeriod == 0) _newPeriod = oraclePeriod;
        require(_newPeriod > 59, "invalid-oracle-period");
        emit UpdatedOracleConfig(oraclePeriod, _newPeriod, oracleRouterIdx, _newRouterIdx);
        oraclePeriod = _newPeriod;
        oracleRouterIdx = _newRouterIdx;
    }

    /// @dev Approve all required tokens
    function approveToken() external onlyKeeper {
        _approveToken(0);
        _approveToken(MAX_UINT_VALUE);
    }

    function setupOracles() external onlyKeeper {
        _setupOracles();
    }

    /**
     * @dev Withdraw collateral token from lending pool.
     * @param _amount Amount of collateral token
     */
    function withdraw(uint256 _amount) external override onlyPool {
        _withdraw(_amount);
    }

    /**
     * @dev Rebalance profit, loss and investment of this strategy
     */
    function rebalance() external virtual override onlyKeeper {
        (uint256 _profit, uint256 _loss, uint256 _payback) = _generateReport();
        IVesperPool(pool).reportEarning(_profit, _loss, _payback);
        _reinvest();
    }

    /**
     * @dev sweep given token to feeCollector of strategy
     * @param _fromToken token address to sweep
     */
    function sweepERC20(address _fromToken) external override onlyKeeper {
        require(feeCollector != address(0), "fee-collector-not-set");
        require(_fromToken != address(collateralToken), "not-allowed-to-sweep-collateral");
        require(!isReservedToken(_fromToken), "not-allowed-to-sweep");
        if (_fromToken == ETH) {
            Address.sendValue(payable(feeCollector), address(this).balance);
        } else {
            uint256 _amount = IERC20(_fromToken).balanceOf(address(this));
            IERC20(_fromToken).safeTransfer(feeCollector, _amount);
        }
    }

    /// @notice Returns address of token correspond to collateral token
    function token() external view override returns (address) {
        return receiptToken;
    }

    /**
     * @notice Calculate total value of asset under management
     * @dev Report total value in collateral token
     */
    function totalValue() public view virtual override returns (uint256 _value);

    /**
     * @notice Calculate total value of asset under management (in real-time)
     * @dev Report total value in collateral token
     */
    function totalValueCurrent() external virtual override returns (uint256) {
        return totalValue();
    }

    /// @notice Check whether given token is reserved or not. Reserved tokens are not allowed to sweep.
    function isReservedToken(address _token) public view virtual override returns (bool);

    /**
     * @notice some strategy may want to prepare before doing migration.
        Example In Maker old strategy want to give vault ownership to new strategy
     * @param _newStrategy .
     */
    function _beforeMigration(address _newStrategy) internal virtual;

    /**
     *  @notice Generate report for current profit and loss. Also liquidate asset to payback
     * excess debt, if any.
     * @return _profit Calculate any realized profit and convert it to collateral, if not already.
     * @return _loss Calculate any loss that strategy has made on investment. Convert into collateral token.
     * @return _payback If strategy has any excess debt, we have to liquidate asset to payback excess debt.
     */
    function _generateReport()
        internal
        virtual
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _payback
        )
    {
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        uint256 _totalDebt = IVesperPool(pool).totalDebtOf(address(this));
        _profit = _realizeProfit(_totalDebt);
        _loss = _realizeLoss(_totalDebt);
        _payback = _liquidate(_excessDebt);
    }

    function _calcAmtOutAfterSlippage(uint256 _amount, uint256 _slippage) internal pure returns (uint256) {
        return (_amount * (10000 - _slippage)) / (10000);
    }

    function _simpleOraclePath(address _from, address _to) internal view returns (address[] memory path) {
        if (_from == WETH || _to == WETH) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = WETH;
            path[2] = _to;
        }
    }

    function _consultOracle(
        address _from,
        address _to,
        uint256 _amt
    ) internal returns (uint256, bool) {
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            (bool _success, bytes memory _returnData) =
                address(swapManager).call(
                    abi.encodePacked(swapManager.consult.selector, abi.encode(_from, _to, _amt, oraclePeriod, i))
                );
            if (_success) {
                (uint256 rate, uint256 lastUpdate, ) = abi.decode(_returnData, (uint256, uint256, bool));
                if ((lastUpdate > (block.timestamp - oraclePeriod)) && (rate != 0)) return (rate, true);
                return (0, false);
            }
        }
        return (0, false);
    }

    function _getOracleRate(address[] memory path, uint256 _amountIn) internal returns (uint256 amountOut) {
        require(path.length > 1, "invalid-oracle-path");
        amountOut = _amountIn;
        bool isValid;
        for (uint256 i = 0; i < path.length - 1; i++) {
            (amountOut, isValid) = _consultOracle(path[i], path[i + 1], amountOut);
            require(isValid, "invalid-oracle-rate");
        }
    }

    /**
     * @notice Safe swap via Uniswap / Sushiswap (better rate of the two)
     * @dev There are many scenarios when token swap via Uniswap can fail, so this
     * method will wrap Uniswap call in a 'try catch' to make it fail safe.
     * however, this method will throw minAmountOut is not met
     * @param _from address of from token
     * @param _to address of to token
     * @param _amountIn Amount to be swapped
     * @param _minAmountOut minimum amount out
     */
    function _safeSwap(
        address _from,
        address _to,
        uint256 _amountIn,
        uint256 _minAmountOut
    ) internal {
        (address[] memory path, uint256 amountOut, uint256 rIdx) =
            swapManager.bestOutputFixedInput(_from, _to, _amountIn);
        if (_minAmountOut == 0) _minAmountOut = 1;
        if (amountOut != 0) {
            swapManager.ROUTERS(rIdx).swapExactTokensForTokens(
                _amountIn,
                _minAmountOut,
                path,
                address(this),
                block.timestamp
            );
        }
    }

    // These methods can be implemented by the inheriting strategy.
    /* solhint-disable no-empty-blocks */
    function _claimRewardsAndConvertTo(address _toToken) internal virtual {}

    /**
     * @notice Set up any oracles that are needed for this strategy.
     */
    function _setupOracles() internal virtual {}

    /* solhint-enable */

    // These methods must be implemented by the inheriting strategy
    function _withdraw(uint256 _amount) internal virtual;

    function _approveToken(uint256 _amount) internal virtual;

    /**
     * @notice Withdraw collateral to payback excess debt in pool.
     * @param _excessDebt Excess debt of strategy in collateral token
     * @return _payback amount in collateral token. Usually it is equal to excess debt.
     */
    function _liquidate(uint256 _excessDebt) internal virtual returns (uint256 _payback);

    /**
     * @notice Calculate earning and withdraw/convert it into collateral token.
     * @param _totalDebt Total collateral debt of this strategy
     * @return _profit Profit in collateral token
     */
    function _realizeProfit(uint256 _totalDebt) internal virtual returns (uint256 _profit);

    /**
     * @notice Calculate loss
     * @param _totalDebt Total collateral debt of this strategy
     * @return _loss Realized loss in collateral token
     */
    function _realizeLoss(uint256 _totalDebt) internal virtual returns (uint256 _loss);

    /**
     * @notice Reinvest collateral.
     * @dev Once we file report back in pool, we might have some collateral in hand
     * which we want to reinvest aka deposit in lender/provider.
     */
    function _reinvest() internal virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "../../curve/4Pool/Crv4MetaPoolStrategy.sol";
import "../ConvexStrategyBase.sol";

/// @title This strategy will deposit collateral token in Curve 4MetaPool and stake lp token to convex.
abstract contract Convex4MetaPoolStrategy is Crv4MetaPoolStrategy, ConvexStrategyBase {
    using SafeERC20 for IERC20;

    constructor(
        address _pool,
        address _swapManager,
        address _metapool,
        address _gauge,
        uint256 _collateralIdx,
        uint256 _convexPoolId,
        string memory _name
    )
        Crv4MetaPoolStrategy(_pool, _swapManager, _metapool, _gauge, _collateralIdx, _name)
        ConvexStrategyBase(_metapool, _convexPoolId)
    {
        oracleRouterIdx = 0;
    }

    /// @dev convex pool can add new rewards. This method refresh list.
    function setRewardTokens(
        address[] memory /*_rewardTokens*/
    ) external override onlyKeeper {
        rewardTokens = _getRewardTokens();
        _approveToken(0);
        _approveToken(MAX_UINT_VALUE);
        _setupOracles();
    }

    function updateClaimRewards(bool _isClaimRewards) external onlyGovernor {
        isClaimRewards = _isClaimRewards;
    }

    function _approveToken(uint256 _amount) internal virtual override {
        IERC20(crvLp).safeApprove(BOOSTER, _amount);
        super._approveToken(_amount);
    }

    function _stakeAllLp() internal override {
        uint256 balance = IERC20(crvLp).balanceOf(address(this));
        if (balance != 0) {
            require(IConvex(BOOSTER).deposit(convexPoolId, balance, true), "booster-deposit-failed");
        }
    }

    function _unstakeAllLp() internal override {
        Rewards(cvxCrvRewards).withdrawAllAndUnwrap(isClaimRewards);
    }

    function _unstakeLp(uint256 _amount) internal override {
        if (_amount != 0) {
            require(Rewards(cvxCrvRewards).withdrawAndUnwrap(_amount, false), "withdraw-and-unwrap-failed");
        }
    }

    function _claimRewards() internal override {
        require(Rewards(cvxCrvRewards).getReward(address(this), true), "reward-claim-failed");
    }

    function totalStaked() public view override returns (uint256 total) {
        total = Rewards(cvxCrvRewards).balanceOf(address(this));
    }

    function totalLp() public view override returns (uint256 total) {
        total = IERC20(crvLp).balanceOf(address(this)) + Rewards(cvxCrvRewards).balanceOf(address(this));
    }

    /// @dev Claimable rewards estimated into pool's collateral value
    function claimableRewardsInCollateral() public view virtual override returns (uint256 rewardAsCollateral) {
        ClaimableRewardInfo[] memory _claimableRewardsInfo = _claimableRewards();
        for (uint256 i = 0; i < _claimableRewardsInfo.length; i++) {
            if (_claimableRewardsInfo[i].amount != 0) {
                (, uint256 _reward, ) =
                    swapManager.bestOutputFixedInput(
                        _claimableRewardsInfo[i].token,
                        address(collateralToken),
                        _claimableRewardsInfo[i].amount
                    );
                rewardAsCollateral += _reward;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./Convex4MetaPoolStrategy.sol";

//solhint-disable no-empty-blocks
contract Convex4MetaPoolStrategyIBBTCPool is Convex4MetaPoolStrategy {
    // ibbtc/sbtcCRV-f Metapool
    // Composed of [ ibBTC , [ renBTC, WBTC, SBTC ] ]
    address internal constant METAPOOL = 0xFbdCA68601f835b27790D98bbb8eC7f05FDEaA9B;
    // Gauge for FRAX-3CRV Metapool
    address internal constant GAUGE = 0x346C7BB1A7a6A30c8e81c14e90FC2f0FBddc54d8;
    // Convex Pool ID for ibbtc/sbtcCRV-f
    uint256 internal constant CONVEX_POOL_ID = 53;

    constructor(
        address _pool,
        address _swapManager,
        uint256 _collateralIdx,
        string memory _name
    ) Convex4MetaPoolStrategy(_pool, _swapManager, METAPOOL, GAUGE, _collateralIdx, CONVEX_POOL_ID, _name) {
        oracleRouterIdx = 1;
        // Curve sBTC DepositZap Contract
        DEPOSIT_ZAP = 0x7AbDBAf29929e7F8621B757D2a7c04d78d633834;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/convex/IConvex.sol";
import "../../interfaces/convex/IConvexToken.sol";

// Convex Strategies common variables and helper functions
abstract contract ConvexStrategyBase {
    using SafeERC20 for IERC20;

    address public constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address private constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    address public constant BOOSTER = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address public immutable cvxCrvRewards;
    uint256 public immutable convexPoolId;
    bool public isClaimRewards;
    uint256 internal constant SUSHISWAP_ROUTER_INDEX = 1;

    struct ClaimableRewardInfo {
        address token;
        uint256 amount;
    }

    constructor(address _crvLp, uint256 _convexPoolId) {
        (address _lp, , , address _reward, , ) = IConvex(BOOSTER).poolInfo(_convexPoolId);
        require(_lp == address(_crvLp), "incorrect-lp-token");
        cvxCrvRewards = _reward;
        convexPoolId = _convexPoolId;
    }

    function _getRewardTokens() internal view returns (address[] memory) {
        uint256 extraRewardCount;
        for (uint256 i = 0; i < Rewards(cvxCrvRewards).extraRewardsLength(); i++) {
            Rewards rewardContract = Rewards(Rewards(cvxCrvRewards).extraRewards(i));
            // Some pool has CVX as extra rewards but other do not. CVX still reward token
            if (rewardContract.rewardToken() != CRV && rewardContract.rewardToken() != CVX) {
                extraRewardCount++;
            }
        }
        address[] memory _rewardTokens = new address[](extraRewardCount + 2);
        _rewardTokens[0] = CRV;
        _rewardTokens[1] = CVX;
        uint256 index = 2;
        for (uint256 i = 0; i < Rewards(cvxCrvRewards).extraRewardsLength(); i++) {
            Rewards rewardContract = Rewards(Rewards(cvxCrvRewards).extraRewards(i));
            // CRV and CVX already added in array
            if (rewardContract.rewardToken() != CRV && rewardContract.rewardToken() != CVX) {
                _rewardTokens[index] = rewardContract.rewardToken();
                index++;
            }
        }
        return _rewardTokens;
    }

    /// @dev Returns a list of (token, amount) for all rewards claimable in a Convex Pool
    function _claimableRewards() internal view returns (ClaimableRewardInfo[] memory) {
        uint256 _extraRewardCount = Rewards(cvxCrvRewards).extraRewardsLength();
        ClaimableRewardInfo[] memory _claimableRewardsInfo = new ClaimableRewardInfo[](_extraRewardCount + 2);
        uint256 _baseReward = Rewards(cvxCrvRewards).earned(address(this));

        // CVX rewards are minted proportionally to baseReward (CRV)
        uint256 _cvxReward = _calculateCVXRewards(_baseReward);
        _claimableRewardsInfo[0] = ClaimableRewardInfo(CRV, _baseReward);
        _claimableRewardsInfo[1] = ClaimableRewardInfo(CVX, _cvxReward);

        // Don't care if there are additional CRV, or CVX in extraRewards
        // total amount will be summed together in claimableRewardsInCollateral()
        for (uint256 i = 0; i < _extraRewardCount; i++) {
            Rewards _rewardContract = Rewards(Rewards(cvxCrvRewards).extraRewards(i));
            _claimableRewardsInfo[2 + i] = ClaimableRewardInfo(
                _rewardContract.rewardToken(),
                _rewardContract.earned(address(this))
            );
        }
        return _claimableRewardsInfo;
    }

    // TODO: review this again.  There may be substitute
    function _calculateCVXRewards(uint256 _claimableCrvRewards) internal view returns (uint256 _total) {
        // CVX Rewards are minted based on CRV rewards claimed upon withdraw
        // This will calculate the CVX amount based on CRV rewards accrued
        // without having to claim CRV rewards first
        // ref 1: https://github.com/convex-eth/platform/blob/main/contracts/contracts/Cvx.sol#L61-L76
        // ref 2: https://github.com/convex-eth/platform/blob/main/contracts/contracts/Booster.sol#L458-L466

        uint256 _reductionPerCliff = IConvexToken(CVX).reductionPerCliff();
        uint256 _totalSupply = IConvexToken(CVX).totalSupply();
        uint256 _maxSupply = IConvexToken(CVX).maxSupply();
        uint256 _cliff = _totalSupply / _reductionPerCliff;
        uint256 _totalCliffs = 1000;

        if (_cliff < _totalCliffs) {
            //for reduction% take inverse of current cliff
            uint256 _reduction = _totalCliffs - _cliff;
            //reduce
            _total = (_claimableCrvRewards * _reduction) / _totalCliffs;

            //supply cap check
            uint256 _amtTillMax = _maxSupply - _totalSupply;
            if (_total > _amtTillMax) {
                _total = _amtTillMax;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../../interfaces/vesper/IVesperPool.sol";
import "../../Strategy.sol";
import "../CrvPoolStrategyBase.sol";

/// @title This strategy will deposit collateral token in Curve a 4Pool Metapool and earn interest.
abstract contract Crv4MetaPoolStrategy is CrvPoolStrategyBase {
    using SafeERC20 for IERC20;

    // No. of pooled tokens in the metapool
    uint256 private constant N = 4;
    // Curve Metapool Factory
    address private constant FACTORY = 0xB9fC157394Af804a3578134A6585C0dc9cc990d4;
    // Curve BASE-3CRV DepositZap Contract
    address internal DEPOSIT_ZAP = 0xA79828DF1850E8a3A3064576f380D90aECDD3359;

    constructor(
        address _pool,
        address _swapManager,
        address _metapool,
        address _gauge,
        uint256 _collateralIdx,
        string memory _name
    ) CrvPoolStrategyBase(_pool, _metapool, _metapool, _gauge, _swapManager, _collateralIdx, N, _name) {
        require(ILiquidityGaugeV2(_gauge).lp_token() == _metapool, "invalid-gauge");
    }

    function _init(
        address _crvPool,
        uint256 /* _n */
    ) internal virtual override {
        coins = IMetapoolFactory(FACTORY).get_underlying_coins(_crvPool);
        coinDecimals = IMetapoolFactory(FACTORY).get_underlying_decimals(_crvPool);
    }

    function _approveToken(uint256 _amount) internal virtual override {
        super._approveToken(_amount);
        collateralToken.safeApprove(DEPOSIT_ZAP, _amount);
        IERC20(crvLp).safeApprove(DEPOSIT_ZAP, _amount);
    }

    function _depositToCurve(uint256 _amt) internal virtual override returns (bool) {
        if (_amt != 0) {
            uint256[4] memory _depositAmounts;
            _depositAmounts[collIdx] = _amt;
            uint256 expectedOut =
                _calcAmtOutAfterSlippage(
                    IDepositZap4x(DEPOSIT_ZAP).calc_token_amount(crvLp, _depositAmounts, true),
                    crvSlippage
                );
            uint256 _minLpAmount =
                ((_amt * _getSafeUsdRate()) / crvPool.get_virtual_price()) * 10**(18 - coinDecimals[collIdx]);

            if (expectedOut > _minLpAmount) _minLpAmount = expectedOut;

            // solhint-disable-next-line no-empty-blocks
            try IDepositZap4x(DEPOSIT_ZAP).add_liquidity(crvLp, _depositAmounts, _minLpAmount) {} catch Error(
                string memory _reason
            ) {
                emit DepositFailed(_reason);
                return false;
            }
        }
        return true;
    }

    function _withdrawAsFromCrvPool(
        uint256 _lpAmount,
        uint256 _minAmt,
        uint256 _i
    ) internal virtual override {
        IDepositZap4x(DEPOSIT_ZAP).remove_liquidity_one_coin(crvLp, _lpAmount, SafeCast.toInt128(int256(_i)), _minAmt);
    }

    function getLpValueAs(uint256 _lpAmount, uint256 _i) public view virtual override returns (uint256) {
        return
            (_lpAmount != 0)
                ? IDepositZap4x(DEPOSIT_ZAP).calc_withdraw_one_coin(crvLp, _lpAmount, SafeCast.toInt128(int256(_i)))
                : 0;
    }

    function _claimRewards() internal virtual override {
        ITokenMinter(CRV_MINTER).mint(crvGauge);
        ILiquidityGaugeV2(crvGauge).claim_rewards(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../../interfaces/curve/IStableSwap.sol";
import "../../interfaces/curve/ILiquidityGauge.sol";
import "../../interfaces/curve/ITokenMinter.sol";
import "../../interfaces/curve/IMetapoolFactory.sol";
import "../../interfaces/curve/IDepositZap.sol";

abstract contract CrvBase {
    using SafeERC20 for IERC20;

    address public constant CRV_MINTER = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;

    // solhint-disable-next-line  var-name-mixedcase
    address public CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    IStableSwapUnderlying public immutable crvPool;
    address public immutable crvLp;
    address public immutable crvGauge;

    constructor(
        address _pool,
        address _lp,
        address _gauge
    ) {
        require(_pool != address(0x0), "CRVMgr: invalid curve pool");
        require(_lp != address(0x0), "CRVMgr: invalid lp token");
        require(_gauge != address(0x0), "CRVMgr: invalid gauge");

        crvPool = IStableSwapUnderlying(_pool);
        crvLp = _lp;
        crvGauge = _gauge;
    }

    function _minimumLpPrice(uint256 _safeRate) internal view returns (uint256) {
        return ((crvPool.get_virtual_price() * _safeRate) / 1e18);
    }

    function _withdrawAsFromCrvPool(
        uint256 _lpAmount,
        uint256 _minAmt,
        uint256 i
    ) internal virtual {
        crvPool.remove_liquidity_one_coin(_lpAmount, SafeCast.toInt128(int256(i)), _minAmt);
    }

    function _withdrawAllAs(uint256 i) internal virtual {
        uint256 lpAmt = IERC20(crvLp).balanceOf(address(this));
        if (lpAmt != 0) {
            crvPool.remove_liquidity_one_coin(lpAmt, SafeCast.toInt128(int256(i)), 0);
        }
    }

    function calcWithdrawLpAs(uint256 _amtNeeded, uint256 i)
        public
        view
        returns (uint256 lpToWithdraw, uint256 unstakeAmt)
    {
        uint256 lp = getLp();
        uint256 tlp = totalLp();
        lpToWithdraw = (_amtNeeded * tlp) / getLpValueAs(tlp, i);
        lpToWithdraw = (lpToWithdraw > tlp) ? tlp : lpToWithdraw;
        if (lpToWithdraw > lp) {
            unstakeAmt = lpToWithdraw - lp;
        }
    }

    function getLpValueAs(uint256 _lpAmount, uint256 i) public view virtual returns (uint256) {
        return (_lpAmount != 0) ? crvPool.calc_withdraw_one_coin(_lpAmount, SafeCast.toInt128(int256(i))) : 0;
    }

    // While this is inaccurate in terms of slippage, this gives us the
    // best estimate (least manipulatable value) to calculate share price
    function getLpValue(uint256 _lpAmount) public view virtual returns (uint256) {
        return (_lpAmount != 0) ? (crvPool.get_virtual_price() * _lpAmount) / 1e18 : 0;
    }

    function setCheckpoint() external {
        _setCheckpoint();
    }

    // requires that gauge has approval for lp token
    function _stakeAllLp() internal virtual {
        uint256 balance = IERC20(crvLp).balanceOf(address(this));
        if (balance != 0) {
            ILiquidityGaugeV2(crvGauge).deposit(balance);
        }
    }

    function _unstakeAllLp() internal virtual {
        _unstakeLp(IERC20(crvGauge).balanceOf(address(this)));
    }

    function _unstakeLp(uint256 _amount) internal virtual {
        if (_amount != 0) {
            ILiquidityGaugeV2(crvGauge).withdraw(_amount);
        }
    }

    function _claimRewards() internal virtual {
        ITokenMinter(CRV_MINTER).mint(crvGauge);
    }

    function _setCheckpoint() internal virtual {
        ILiquidityGaugeV2(crvGauge).user_checkpoint(address(this));
    }

    function totalStaked() public view virtual returns (uint256 total) {
        total = IERC20(crvGauge).balanceOf(address(this));
    }

    function totalLp() public view virtual returns (uint256 total) {
        total = getLp() + IERC20(crvGauge).balanceOf(address(this));
    }

    // Gets LP value not staked in gauge
    function getLp() public view virtual returns (uint256 total) {
        total = IERC20(crvLp).balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../../interfaces/vesper/IVesperPool.sol";
import "../Strategy.sol";
import "./CrvBase.sol";

/// @title This strategy will deposit collateral token in a Curve Pool and earn interest.
abstract contract CrvPoolStrategyBase is CrvBase, Strategy {
    using SafeERC20 for IERC20;

    // solhint-disable-next-line var-name-mixedcase
    string public NAME;
    string public constant VERSION = "4.0.0";

    mapping(address => bool) internal reservedToken;

    uint256 public immutable collIdx;
    uint256 public usdRate;
    uint256 public usdRateTimestamp;

    address[] public coins;
    uint256[] public coinDecimals;
    address[] public rewardTokens;
    bool public depositError;

    uint256 public crvSlippage = 10; // 10000 is 100%; 10 is 0.1%
    uint256 public decimalConversionFactor; // It will be used in converting value to/from 18 decimals

    // No. of pooled tokens in the Pool
    uint256 internal immutable n;
    event UpdatedCrvSlippage(uint256 oldCrvSlippage, uint256 newCrvSlippage);

    event DepositFailed(string reason);

    constructor(
        address _pool,
        address _crvPool,
        address _crvLp,
        address _crvGauge,
        address _swapManager,
        uint256 _collateralIdx,
        uint256 _n,
        string memory _name
    )
        CrvBase(_crvPool, _crvLp, _crvGauge) // 3Pool Manager
        Strategy(_pool, _swapManager, _crvLp)
    {
        require(_collateralIdx < _n, "invalid-collateral");

        n = _n;
        reservedToken[_crvLp] = true;
        reservedToken[CRV] = true;
        collIdx = _collateralIdx;
        _init(_crvPool, _n);
        require(coins[_collateralIdx] == address(IVesperPool(_pool).token()), "collateral-mismatch");
        // Assuming token supports 18 or less decimals. _init will initialize coins array
        uint256 _decimals = IERC20Metadata(coins[_collateralIdx]).decimals();
        decimalConversionFactor = 10**(18 - _decimals);
        NAME = _name;
        rewardTokens.push(CRV);
    }

    /// @dev Rewards token in gauge can be updated any time. Governor can set reward tokens
    /// Different version of gauge has different method to read reward tokens better governor set it
    function setRewardTokens(address[] memory _rewardTokens) external virtual onlyGovernor {
        rewardTokens = _rewardTokens;
        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            require(
                _rewardTokens[i] != receiptToken &&
                    _rewardTokens[i] != address(collateralToken) &&
                    _rewardTokens[i] != pool &&
                    _rewardTokens[i] != crvLp,
                "Invalid reward token"
            );
            reservedToken[_rewardTokens[i]] = true;
        }
        _approveToken(0);
        _approveToken(MAX_UINT_VALUE);
        _setupOracles();
    }

    function updateCrvSlippage(uint256 _newCrvSlippage) external onlyGovernor {
        require(_newCrvSlippage < 10000, "invalid-slippage-value");
        emit UpdatedCrvSlippage(crvSlippage, _newCrvSlippage);
        crvSlippage - _newCrvSlippage;
    }

    /// @dev Claimable rewards estimated into pool's collateral value
    function claimableRewardsInCollateral() public view virtual returns (uint256 rewardAsCollateral) {
        //Total Mintable - Previously minted
        uint256 claimable =
            ILiquidityGaugeV2(crvGauge).integrate_fraction(address(this)) -
                ITokenMinter(CRV_MINTER).minted(address(this), crvGauge);
        if (claimable != 0) {
            (, rewardAsCollateral, ) = swapManager.bestOutputFixedInput(CRV, address(collateralToken), claimable);
        }
    }

    /// @dev Convert from 18 decimals to token defined decimals.
    function convertFrom18(uint256 _amount) public view returns (uint256) {
        return _amount / decimalConversionFactor;
    }

    /// @dev Check whether given token is reserved or not. Reserved tokens are not allowed to sweep.
    function isReservedToken(address _token) public view override returns (bool) {
        return reservedToken[_token];
    }

    /**
     * @notice Calculate total value of asset under management
     * @dev Report total value in collateral token
     */
    function totalValue() public view virtual override returns (uint256 _value) {
        _value =
            collateralToken.balanceOf(address(this)) +
            convertFrom18(_calcAmtOutAfterSlippage(getLpValue(totalLp()), crvSlippage)) +
            claimableRewardsInCollateral();
    }

    function _setupOracles() internal virtual override {
        _safeCreateOrUpdateOracle(CRV, WETH);
        for (uint256 i = 0; i < n; i++) {
            _safeCreateOrUpdateOracle(coins[i], WETH);
        }
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            _safeCreateOrUpdateOracle(rewardTokens[i], WETH);
        }
    }

    /**
     * @dev Creates Oracle pair preventing revert if it doesn't exist in a DEX
     */
    function _safeCreateOrUpdateOracle(address _tokenA, address _tokenB) internal {
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            // solhint-disable no-empty-blocks
            try swapManager.createOrUpdateOracle(_tokenA, _tokenB, oraclePeriod, i) {
                break;
            } catch Error(
                string memory /* reason */
            ) {}
            // solhint-enable no-empty-blocks
        }
    }

    // given the rates of 3 stablecoins compared with a common denominator
    // return the lowest divided by the highest
    function _getSafeUsdRate() internal returns (uint256) {
        // use a stored rate if we've looked it up recently
        if (usdRateTimestamp > block.timestamp - oraclePeriod && usdRate != 0) return usdRate;
        // otherwise, calculate a rate and store it.
        uint256 lowest;
        uint256 highest;
        for (uint256 i = 0; i < n; i++) {
            // get the rate for $1
            (uint256 rate, bool isValid) = _consultOracle(coins[i], WETH, 10**coinDecimals[i]);
            if (isValid) {
                if (lowest == 0 || rate < lowest) {
                    lowest = rate;
                }
                if (highest < rate) {
                    highest = rate;
                }
            }
        }
        // We only need to check one of them because if a single valid rate is returned,
        // highest == lowest and highest > 0 && lowest > 0
        require(lowest != 0, "no-oracle-rates");
        usdRateTimestamp = block.timestamp;
        usdRate = (lowest * 1e18) / highest;
        return usdRate;
    }

    function _approveToken(uint256 _amount) internal virtual override {
        collateralToken.safeApprove(pool, _amount);
        collateralToken.safeApprove(address(crvPool), _amount);
        for (uint256 j = 0; j < swapManager.N_DEX(); j++) {
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                IERC20(rewardTokens[i]).safeApprove(address(swapManager.ROUTERS(j)), _amount);
            }
            collateralToken.safeApprove(address(swapManager.ROUTERS(j)), _amount);
        }
        IERC20(crvLp).safeApprove(crvGauge, _amount);
    }

    function _init(address _crvPool, uint256 _n) internal virtual {
        for (uint256 i = 0; i < _n; i++) {
            coins.push(IStableSwapUnderlying(_crvPool).coins(i));
            coinDecimals.push(IERC20Metadata(coins[i]).decimals());
        }
    }

    function _reinvest() internal override {
        depositError = false;
        uint256 amt = collateralToken.balanceOf(address(this));
        depositError = !_depositToCurve(amt);
        _stakeAllLp();
    }

    function _depositToCurve(uint256 amt) internal virtual returns (bool) {
        if (amt != 0) {
            uint256[3] memory depositAmounts;
            depositAmounts[collIdx] = amt;
            uint256 expectedOut =
                _calcAmtOutAfterSlippage(
                    IStableSwap3xUnderlying(address(crvPool)).calc_token_amount(depositAmounts, true),
                    crvSlippage
                );
            uint256 minLpAmount =
                ((amt * _getSafeUsdRate()) / crvPool.get_virtual_price()) * 10**(18 - coinDecimals[collIdx]);
            if (expectedOut > minLpAmount) minLpAmount = expectedOut;
            // solhint-disable-next-line no-empty-blocks
            try IStableSwap3xUnderlying(address(crvPool)).add_liquidity(depositAmounts, minLpAmount) {} catch Error(
                string memory reason
            ) {
                emit DepositFailed(reason);
                return false;
            }
        }
        return true;
    }

    function _withdraw(uint256 _amount) internal override {
        // This adds some gas but will save loss on exchange fees
        uint256 balanceHere = collateralToken.balanceOf(address(this));
        if (_amount > balanceHere) {
            _unstakeAndWithdrawAsCollateral(_amount - balanceHere);
        }
        collateralToken.safeTransfer(pool, _amount);
    }

    function _unstakeAndWithdrawAsCollateral(uint256 _amount) internal returns (uint256 toWithdraw) {
        if (_amount == 0) return 0;
        uint256 i = collIdx;
        (uint256 lpToWithdraw, uint256 unstakeAmt) = calcWithdrawLpAs(_amount, i);
        _unstakeLp(unstakeAmt);
        uint256 minAmtOut =
            convertFrom18(
                (lpToWithdraw * _calcAmtOutAfterSlippage(_minimumLpPrice(_getSafeUsdRate()), crvSlippage)) / 1e18
            );
        _withdrawAsFromCrvPool(lpToWithdraw, minAmtOut, i);
        toWithdraw = collateralToken.balanceOf(address(this));
        if (toWithdraw > _amount) toWithdraw = _amount;
    }

    /**
     * @notice some strategy may want to prepare before doing migration. 
        Example In Maker old strategy want to give vault ownership to new strategy
     */
    function _beforeMigration(
        address /*_newStrategy*/
    ) internal override {
        _unstakeAllLp();
    }

    /**
     * @notice Curve pool may have more than one reward token. Child contract should override _claimRewards
     */
    function _claimRewardsAndConvertTo(address _toToken) internal virtual override {
        _claimRewards();
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            uint256 _amt = IERC20(rewardTokens[i]).balanceOf(address(this));
            if (_amt != 0) {
                uint256 _minAmtOut;
                if (swapSlippage < 10000) {
                    (uint256 _minWethOut, bool _isValid) = _consultOracle(rewardTokens[i], WETH, _amt);
                    (uint256 _minTokenOut, bool _isValidTwo) = _consultOracle(WETH, _toToken, _minWethOut);
                    require(_isValid, "stale-reward-oracle");
                    require(_isValidTwo, "stale-collateral-oracle");
                    _minAmtOut = _calcAmtOutAfterSlippage(_minTokenOut, swapSlippage);
                }
                _safeSwap(rewardTokens[i], _toToken, _amt, _minAmtOut);
            }
        }
    }

    /**
     * @notice Withdraw collateral to payback excess debt in pool.
     * @param _excessDebt Excess debt of strategy in collateral token
     * @param _extra additional amount to unstake and withdraw, in collateral token
     * @return _payback amount in collateral token. Usually it is equal to excess debt.
     */
    function _liquidate(uint256 _excessDebt, uint256 _extra) internal returns (uint256 _payback) {
        _payback = _unstakeAndWithdrawAsCollateral(_excessDebt + _extra);
        // we dont want to return a value greater than we need to
        if (_payback > _excessDebt) _payback = _excessDebt;
    }

    function _realizeLoss(uint256 _totalDebt) internal view override returns (uint256 _loss) {
        uint256 _collateralBalance = convertFrom18(_calcAmtOutAfterSlippage(getLpValue(totalLp()), crvSlippage));
        if (_collateralBalance < _totalDebt) {
            _loss = _totalDebt - _collateralBalance;
        }
    }

    function _realizeGross(uint256 _totalDebt)
        internal
        virtual
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _toUnstake
        )
    {
        uint256 baseline = collateralToken.balanceOf(address(this));
        _claimRewardsAndConvertTo(address(collateralToken));
        uint256 newBalance = collateralToken.balanceOf(address(this));
        _profit = newBalance - baseline;

        uint256 _collateralBalance =
            baseline + convertFrom18(_calcAmtOutAfterSlippage(getLpValue(totalLp()), crvSlippage));
        if (_collateralBalance > _totalDebt) {
            _profit += _collateralBalance - _totalDebt;
        } else {
            _loss = _totalDebt - _collateralBalance;
        }

        if (_profit > _loss) {
            _profit = _profit - _loss;
            _loss = 0;
            if (_profit > newBalance) _toUnstake = _profit - newBalance;
        } else {
            _loss = _loss - _profit;
            _profit = 0;
        }
    }

    function _generateReport()
        internal
        virtual
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _payback
        )
    {
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        uint256 _totalDebt = IVesperPool(pool).totalDebtOf(address(this));
        uint256 _toUnstake;
        (_profit, _loss, _toUnstake) = _realizeGross(_totalDebt);
        // only make call to unstake and withdraw once
        _payback = _liquidate(_excessDebt, _toUnstake);
    }

    function rebalance() external virtual override onlyKeeper {
        (uint256 _profit, uint256 _loss, uint256 _payback) = _generateReport();
        IVesperPool(pool).reportEarning(_profit, _loss, _payback);
        _reinvest();
        if (!depositError) {
            uint256 _depositLoss = _realizeLoss(IVesperPool(pool).totalDebtOf(address(this)));
            IVesperPool(pool).reportLoss(_depositLoss);
        }
    }

    // Unused
    /* solhint-disable no-empty-blocks */

    function _liquidate(uint256 _excessDebt) internal override returns (uint256 _payback) {}

    function _realizeProfit(uint256 _totalDebt) internal override returns (uint256 _profit) {}
}