/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-30
*/

// File: ..\node_modules\@chainlink\contracts\src\v0.6\vendor\SafeMathChainlink.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

// File: ..\node_modules\@chainlink\contracts\src\v0.6\interfaces\LinkTokenInterface.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// File: ..\node_modules\@chainlink\contracts\src\v0.6\VRFRequestIDBase.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// File: @chainlink\contracts\src\v0.6\VRFConsumerBase.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;




/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  using SafeMathChainlink for uint256;

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee)
    internal returns (bytes32 requestId)
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash].add(1);
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) public {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// File: @openzeppelin\contracts\math\SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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


// File: ..\node_modules\@openzeppelin\contracts\utils\Address.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// File: @openzeppelin\contracts\token\ERC20\SafeERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;




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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

// File: contracts\OwnableContract.sol

pragma solidity 0.6.6;

contract OwnableContract {
    address public owner;
    address public pendingOwner;
    address public admin;
    address public dev;

    event NewAdmin(address oldAdmin, address newAdmin);
    event NewDev(address oldDev, address newDev);
    event NewOwner(address oldOwner, address newOwner);
    event NewPendingOwner(address oldPendingOwner, address newPendingOwner);

    constructor() public {
        owner = msg.sender;
        admin = msg.sender;
        dev   = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"onlyOwner");
        _;
    }

    modifier onlyPendingOwner {
        require(msg.sender == pendingOwner,"onlyPendingOwner");
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == admin || msg.sender == owner,"onlyAdmin");
        _;
    } 

    modifier onlyDev {
        require(msg.sender == dev  || msg.sender == owner,"onlyDev");
        _;
    } 
    
    function transferOwnership(address _pendingOwner) public onlyOwner {
        emit NewPendingOwner(pendingOwner, _pendingOwner);
        pendingOwner = _pendingOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit NewOwner(owner, address(0));
        emit NewAdmin(admin, address(0));
        emit NewPendingOwner(pendingOwner, address(0));

        owner = address(0);
        pendingOwner = address(0);
        admin = address(0);
    }
    
    function acceptOwner() public onlyPendingOwner {
        emit NewOwner(owner, pendingOwner);
        owner = pendingOwner;

        address newPendingOwner = address(0);
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }    
    
    function setAdmin(address newAdmin) public onlyOwner {
        emit NewAdmin(admin, newAdmin);
        admin = newAdmin;
    }

    function setDev(address newDev) public onlyOwner {
        emit NewDev(dev, newDev);
        dev = newDev;
    }

}

// File: contracts\RandomInterface.sol

pragma solidity 0.6.6;

interface RandomInterface{

    function getRandomNumber() external returns(uint256);
}

// File: contracts\SmashEggFunctionV2.sol

pragma solidity 0.6.6;







interface LoserChickNftInterface{
     function createNFT(address owner) external returns(uint256);
     function totalSupply() external returns(uint256);
     function maxSupply() external returns(uint256);    
}

contract SmashEggFunctionV2 is OwnableContract, VRFConsumerBase{

    using SafeERC20 for IERC20;


    // ************** basic param *******************
    uint public constant PRECISION = 1e17;

    uint256 public constant LUCKY_CHICK_INDEX = 0;
    uint256 public constant LABOR_CHICK_INDEX = 1;
    uint256 public constant BOSS_CHICK_INDEX = 2;
    uint256 public constant TRUMP_CHICK_INDEX = 3;
    uint256 public constant SHRIEKING_CHICK_INDEX = 4;

    uint256 public winningProbability; // Get NFT Probability

    address[] public loserChickAddrArray;

    uint256[] public chickProbability; // Per chick Rate, 0 is luckyChick, 1 is laborChick, 2 is bossChick, 3 is trumpChick.

    //************** shrieking chick param *******************
    // for STRATEGY_ONE
    struct ShriekingProbability{
        uint256 minute;
        uint256 probability;
    }

    uint256 public constant STRATEGY_ONE = 1; // old
    uint256 public constant STRATEGY_TWO = 2; // new
    uint256 public strategy = STRATEGY_ONE;
    uint256 public maxOrderBlockDistanceForShriek = 43200 * 7 ; // for STRATEGY_ONE
    bool public shriekingSwitch = false;
    ShriekingProbability[] public shriekingArray;
    uint256 public shriekingTokenId;
    uint256 public shriekingStartTimestamp = 0;    
    uint256 public shriekingEndTimestamp = 0;
    uint256 public remainingShriekingCount;

    mapping(uint256 /* shriekingTokenId */ => mapping(address /* user */ => uint256 /* eggCount */)) public smashEggCountInShriekingTimeRangeChickPerUser;
    mapping(uint256 /* shriekingTokenId */ => address /* user */) public shriekingWinner;
    mapping(uint256 /* shriekingTokenId */ => uint256 /* birth timestamp */) public shriekingBirthday;
    mapping(uint256 /* shriekingTokenId */ => mapping(uint256 /* eggNumber */ => address /* user */)) public eggToUserAddressMapPer;
    mapping(uint256 /* shriekingTokenId */ => uint256 /* smashEggTotal */) public shriekingActivitySmashEggTotalPer;
    mapping(uint256 /* shriekingTokenId */ => mapping(address /* user */ => bool /* Are you involved */)) public isShriekingParticipatoryAddress;
    mapping(uint256 /* shriekingTokenId */ => uint256 /* Number of participants */) public shriekingParticipatoryUserCount;


    // ************ VRF param *******************
    bytes32 public immutable vrfKeyHash;
    uint256 public  vrfFee;
    uint256 public vrfRandomResult;

    // *********** events *******************
    event SmashEggsEvent(address userAddr, uint256 eggCount, uint256 chickCount, address[] chickAddrArray, uint256[] tokenIdArray);


    constructor(address _shriekingChickAddr, address _luckyChickAddr, address _laborChickAddr, address _bossChickAddr, address _trumpChickAddr, 
                address _vrfCoordinator, address _linkToken, bytes32 _vrfKeyHash, uint256 _vrfFee) 
            VRFConsumerBase(
                _vrfCoordinator, // VRF Coordinator
                _linkToken  // LINK Token
        )public{

        vrfKeyHash = _vrfKeyHash;
        vrfFee = _vrfFee;


        loserChickAddrArray = new address[](5);
        loserChickAddrArray[LUCKY_CHICK_INDEX] = _luckyChickAddr;
        loserChickAddrArray[LABOR_CHICK_INDEX] = _laborChickAddr;
        loserChickAddrArray[BOSS_CHICK_INDEX] = _bossChickAddr;
        loserChickAddrArray[TRUMP_CHICK_INDEX] = _trumpChickAddr;
        loserChickAddrArray[SHRIEKING_CHICK_INDEX] = _shriekingChickAddr;

        chickProbability = new uint256[](4);
        chickProbability[LUCKY_CHICK_INDEX] = 99957157142857140; // luckyChick   
        chickProbability[LABOR_CHICK_INDEX] = 99714314285714270; // laborChick    
        chickProbability[BOSS_CHICK_INDEX] = 98571471428571410;  // bossChick    
        chickProbability[TRUMP_CHICK_INDEX] = 41428628571428510; // trumpChick  

        winningProbability = 41428628571428510; 
    }

    function updateVrfFee(uint256 _vrfFee) external onlyOwner {
        vrfFee = _vrfFee;
    }

    function updateLoserChickAddr(uint256 index, address loserChickAddr) public onlyOwner{
        loserChickAddrArray[index] = loserChickAddr;
    }

    function updateChickProbability(uint index, uint256 probability) public onlyOwner{
        require(index < 4, 'Index is wrong!');
        chickProbability[index] = probability;
    }

    function updateTotalProbability(uint256 probability) public onlyOwner{
        winningProbability = probability;
    }

    function withdrawLink(address _to) external onlyOwner {
        uint256 balance = LINK.balanceOf(address(this));
        LINK.transfer(_to, balance);
    }

    function smashEggs(uint256 _amount, uint256 _seed, uint256 _randomIndex, uint256 _orderBlockNumber, uint256 _orderId)  external onlyDev returns(uint256){
        require(0 < _amount && _amount <= 10, '_amount should be greater than 0 and less than or equal to 10');

        address[] memory chickAddrArray = new address[](_amount);
        uint256[] memory tokenIds = new uint256[](_amount);
        uint256 count = 0;

        for(uint256 i=0; i<_amount; i++){
            uint256 random = uint256(keccak256(abi.encode(_seed, _randomIndex)));
            if(isWon(random)){
                (uint256 tokenId, address chickAddr) = getOneChickNFT(random, _orderBlockNumber);
                if(tokenId != 0){
                    chickAddrArray[count] = chickAddr;
                    tokenIds[count] = tokenId;

                    count++;
                }
            }
            _randomIndex++;

            checkShriekingStrategyTwo();
        }

        if(_amount == 10 && count < 5){
            uint256 count2 = uint256(5).sub(count);
            for(uint256 i=0; i<count2; i++){
                uint256 random = uint256(keccak256(abi.encode(_seed, _randomIndex)));
                (uint256 tokenId, address chickAddr) = getOneChickNFT(random, _orderBlockNumber);
                if(tokenId != 0){
                    chickAddrArray[count] = chickAddr;
                    tokenIds[count] = tokenId;

                    count++;
                }
                _randomIndex++;
            }
        }

        emit SmashEggsEvent(tx.origin, _amount, count, chickAddrArray, tokenIds);
        return _randomIndex;
    }

    /**
     * @notice Won or not
     */
    function isWon(uint256 _random) internal view returns(bool){
        uint256 random = _random % PRECISION;
        return (random > winningProbability);       
    }

    function getOneChickNFT(uint _random, uint256 _orderBlockNumber) internal returns(uint256, address){
        uint256 random = _random % PRECISION;
        uint256 index = TRUMP_CHICK_INDEX;

        if( shouldCreateShriekingForStrategyOne(_random, _orderBlockNumber)){
            index = SHRIEKING_CHICK_INDEX;
            remainingShriekingCount = remainingShriekingCount.sub(uint256(1));
        }else{
            for(uint256 i=0; i<chickProbability.length; i++){
                if(random > chickProbability[i]){
                    index = i;
                    break;
                }
            }
        }

        return getGenerateOneChick(index, tx.origin);
    }

    function getGenerateOneChick(uint256 index, address user) internal returns(uint256, address){
        address chickAddr = loserChickAddrArray[index];
        LoserChickNftInterface loserChickNFT = LoserChickNftInterface(chickAddr);

        uint256 tokenId = 0;
        if(loserChickNFT.totalSupply() < loserChickNFT.maxSupply()){
            tokenId = loserChickNFT.createNFT(user);
        }
        return (tokenId, chickAddr);
    }


    function updateShriekingSwitch(bool _shriekingSwitch) public onlyOwner{
        shriekingSwitch = _shriekingSwitch;
    }

    function updateMaxOrderBlockDistanceForShriek(uint256 _maxOrderBlockDistanceForShriek) public onlyAdmin{
        maxOrderBlockDistanceForShriek = _maxOrderBlockDistanceForShriek;
    }    

    function isSatisfyShriekingStrategyOne() internal view returns(bool){
        if(strategy == STRATEGY_ONE && shriekingSwitch && shriekingStartTimestamp < now && now <= shriekingEndTimestamp && remainingShriekingCount != 0) {
            return true;
        }
        return false;
    }

    function isSatisfyShriekingStrategyTwo() internal view returns(bool){
        if(strategy == STRATEGY_TWO && shriekingSwitch && shriekingStartTimestamp < now && now <= shriekingEndTimestamp) {
            return true;
        }
        return false;
    }

    function shouldCreateShriekingForStrategyOne(uint _random, uint256 _orderBlockNumber) internal view  returns(bool){
        if(!isSatisfyShriekingStrategyOne()) {
            return false;
        }

        if(block.number - _orderBlockNumber > maxOrderBlockDistanceForShriek) {
            return false;
        }
        
        uint256 probability = PRECISION;
        for(uint256 i=0; i<shriekingArray.length; i++){
            ShriekingProbability memory shrieking = shriekingArray[i];
            if(now <= shriekingStartTimestamp.add(shrieking.minute.mul(60))){
                probability = shrieking.probability;
                break;
            }
        }
        uint256 random = uint256(keccak256(abi.encodePacked(_random, vrfRandomResult))) % PRECISION;
        return random > probability;
    }

    function checkShriekingStrategyTwo() internal{
        if(!isSatisfyShriekingStrategyTwo()) {
            return;
        }

        smashEggCountInShriekingTimeRangeChickPerUser[shriekingTokenId][tx.origin]++;
        if(!isShriekingParticipatoryAddress[shriekingTokenId][tx.origin]){
            shriekingParticipatoryUserCount[shriekingTokenId]++;
            isShriekingParticipatoryAddress[shriekingTokenId][tx.origin] = true;
        }

        uint256 _eggToUserAddressMapCount = shriekingActivitySmashEggTotalPer[shriekingTokenId];
        eggToUserAddressMapPer[shriekingTokenId][_eggToUserAddressMapCount] = tx.origin;
        shriekingActivitySmashEggTotalPer[shriekingTokenId] = _eggToUserAddressMapCount + 1;        
    }

    function distributeShriekingForStrategyTwo() public onlyAdmin{
        require(strategy == STRATEGY_TWO, "current strategy is not two.");
        require(now > shriekingEndTimestamp, 'please execute after the activity.');
        require(shriekingWinner[shriekingTokenId] == address(0x0), "The current activity has ended.");
        require(vrfRandomResult != 0, "Please call VRF first.");

        uint256 index = vrfRandomResult % shriekingActivitySmashEggTotalPer[shriekingTokenId];
        address owner = eggToUserAddressMapPer[shriekingTokenId][index];
        getGenerateOneChick(SHRIEKING_CHICK_INDEX, owner);
        shriekingWinner[shriekingTokenId] = owner;
        shriekingBirthday[shriekingTokenId] = block.timestamp;
        vrfRandomResult = 0;
        remainingShriekingCount = 0;
    }

    function requestRandomNumberForStrategyOne() public onlyAdmin returns (bytes32 requestId){
        require(strategy == STRATEGY_ONE , "current strategy is not 1.");
        require(shriekingStartTimestamp.sub(1200) < now && now < shriekingEndTimestamp, "wrong time.");
        require(LINK.balanceOf(address(this)) >= vrfFee, "not enough LINK - fill contract with faucet");
        return requestRandomness(vrfKeyHash, vrfFee);
    }

    function requestRandomNumberForStrategyTwo() public onlyAdmin returns (bytes32 requestId){
        require(strategy == STRATEGY_TWO, "current strategy is not two.");
        require(now > shriekingEndTimestamp, 'please execute after the activity.');
        require(LINK.balanceOf(address(this)) >= vrfFee, "not enough LINK - fill contract with faucet");
        return requestRandomness(vrfKeyHash, vrfFee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        if(vrfRandomResult == 0) {
           vrfRandomResult = randomness;
        }
    }

    function getShriekingWinnerAndSmashEggCount(uint256 _shriekingChickTokenId) public view returns(address, uint256){
        address winner = shriekingWinner[_shriekingChickTokenId];
        uint256 amount = smashEggCountInShriekingTimeRangeChickPerUser[_shriekingChickTokenId][winner];
        return (winner, amount);
    }

    function getShriekingSmashEggCountUser(uint256 _shriekingChickTokenId, address user) public view returns(uint256){
        return smashEggCountInShriekingTimeRangeChickPerUser[_shriekingChickTokenId][user];
    }

    function updateShriekingArray(uint256[] memory _minute, uint256[] memory _probability) public onlyOwner{
        require(_minute.length == _probability.length, "Parameter is error !");
        require(shriekingStartTimestamp > now, "Please set shriekingstarttimestamp first !");

        delete shriekingArray;

        uint256 spare = 0;
        for(uint256 i=0; i<_minute.length; i++){
            require(_minute[i] > spare, "minute error");
            ShriekingProbability memory shrieking;
            shrieking.minute = _minute[i];
            shrieking.probability = _probability[i];
            shriekingArray.push(shrieking);

            spare = _minute[i];
        }
    }

    function updateShriekingArraySingle(uint256 index, uint256 _minute, uint256 _probability) public onlyOwner{
        require(index < shriekingArray.length, "index is error !");
        shriekingArray[index].minute = _minute;
        shriekingArray[index].probability = _probability;
    }

    function updateShriekingTimestamp(uint256 _startTimestamp, uint256 _minute, uint256 _strategy) public onlyOwner {
        shriekingStartTimestamp = _startTimestamp;
        shriekingEndTimestamp = shriekingStartTimestamp.add(_minute.mul(60));

        remainingShriekingCount = 1;
        vrfRandomResult = 0;

        strategy = _strategy;
        if(_strategy == STRATEGY_TWO){
            LoserChickNftInterface loserChickNFT = LoserChickNftInterface(loserChickAddrArray[SHRIEKING_CHICK_INDEX]);
            shriekingTokenId = loserChickNFT.totalSupply() + 1;
        }
    }
}