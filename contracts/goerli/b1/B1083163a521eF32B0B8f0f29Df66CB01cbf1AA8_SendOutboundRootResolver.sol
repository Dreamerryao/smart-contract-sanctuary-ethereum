// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

import {IResolver} from "../interfaces/IResolver.sol";
import {IConnector} from "../interfaces/IConnector.sol";
import {ProposedOwnable} from "../../shared/ProposedOwnable.sol";

contract SendOutboundRootResolver is IResolver, ProposedOwnable {
  IConnector public immutable CONNECTOR;
  uint256 public EXECUTION_INTERVAL;
  uint256 public lastExecuted;
  bytes32 public lastRootSent;

  constructor(address _connector, uint256 _executionInterval) ProposedOwnable() {
    require(_executionInterval > 0, "SendOutboundRootResolver: execution interval must be > 0");
    _setOwner(msg.sender);
    CONNECTOR = IConnector(_connector);
    EXECUTION_INTERVAL = _executionInterval;
  }

  function changeExecutionInterval(uint256 _executionInterval) public onlyOwner {
    require(_executionInterval > 0, "SendOutboundRootResolver: execution interval must be > 0");
    EXECUTION_INTERVAL = _executionInterval;
  }

  function sendMessage(bytes32 outboundRoot) external {
    CONNECTOR.sendMessage(abi.encode(outboundRoot));
    lastExecuted = block.timestamp;
    lastRootSent = outboundRoot;
  }

  function checker() external view override returns (bool canExec, bytes memory execPayload) {
    bytes32 outboundRoot = CONNECTOR.outboundRoot();
    if ((lastExecuted + EXECUTION_INTERVAL) > block.timestamp) {
      return (false, bytes("EXECUTION_INTERVAL seconds are not passed yet"));
    } else if (lastRootSent == outboundRoot) {
      return (false, bytes("Sent root is the same as the current root"));
    } else {
      execPayload = abi.encodeWithSelector(this.sendMessage.selector, outboundRoot);
      return (true, execPayload);
    }
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

import {IProposedOwnable} from "../../shared/interfaces/IProposedOwnable.sol";

/**
 * @notice This interface is what the Connext contract will send and receive messages through.
 * The messaging layer should conform to this interface, and should be interchangeable (i.e.
 * could be Nomad or a generic AMB under the hood).
 *
 * @dev This uses the nomad format to ensure nomad can be added in as it comes back online.
 *
 * Flow from transfer from polygon to optimism:
 * 1. User calls `xcall` with destination specified
 * 2. This will swap in to the bridge assets
 * 3. The swapped assets will get burned
 * 4. The Connext contract will call `dispatch` on the messaging contract to add the transfer
 *    to the root
 * 5. [At some time interval] Relayers call `send` to send the current root from polygon to
 *    mainnet. This is done on all "spoke" domains.
 * 6. [At some time interval] Relayers call `propagate` [better name] on mainnet, this generates a new merkle
 *    root from all of the AMBs
 *    - This function must be able to read root data from all AMBs and aggregate them into a single merkle
 *      tree root
 *    - Will send the mixed root from all chains back through the respective AMBs to all other chains
 * 7. AMB will call `update` to update the latest root on the messaging contract on spoke domains
 * 8. [At any point] Relayers can call `proveAndProcess` to prove inclusion of dispatched message, and call
 *    process on the `Connext` contract
 * 9. Takes minted bridge tokens and credits the LP
 *
 * AMB requirements:
 * - Access `msg.sender` both from mainnet -> spoke and vice versa
 * - Ability to read *our root* from the AMB
 *
 * AMBs:
 * - PoS bridge from polygon
 * - arbitrum bridge
 * - optimism bridge
 * - gnosis chain
 * - bsc (use multichain for messaging)
 */
interface IConnector is IProposedOwnable {
  function outboundRoot() external view returns (bytes32);

  function aggregateRoot() external view returns (bytes32);

  function sendMessage(bytes memory _data) external;

  function processMessage(address _sender, bytes memory _data) external;

  function verifySender(address _expected) external returns (bool);

  /**
   * @notice This function should send a message through the AMB by adding it to the merkle root
   * stored on that chain.
   */
  function dispatch(
    uint32 _destinationDomain,
    bytes32 _recipientAddress,
    bytes memory _messageBody
  ) external;

  /**
   * @notice Must be able to call the `handle` function on the BridgeRouter contract. This is called
   * on the destination domain to handle incoming messages
   */
  function proveAndProcess(
    bytes memory _message,
    bytes32[32] calldata _proof,
    uint256 _index
  ) external;

  /**
   * @notice This is called by relayers to trigger passing of current root to mainnet root manager
   * @dev This is called at specific time intervals
   */
  function send() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IResolver {
  function checker() external view returns (bool canExec, bytes memory execPayload);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IProposedOwnable} from "./interfaces/IProposedOwnable.sol";

/**
 * @title ProposedOwnable
 * @notice Contract module which provides a basic access control mechanism,
 * where there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed via a two step process:
 * 1. Call `proposeOwner`
 * 2. Wait out the delay period
 * 3. Call `acceptOwner`
 *
 * @dev This module is used through inheritance. It will make available the
 * modifier `onlyOwner`, which can be applied to your functions to restrict
 * their use to the owner.
 *
 * @dev The majority of this code was taken from the openzeppelin Ownable
 * contract
 *
 */
abstract contract ProposedOwnable is IProposedOwnable {
  // ========== Custom Errors ===========

  error ProposedOwnable__onlyOwner_notOwner();
  error ProposedOwnable__onlyProposed_notProposedOwner();
  error ProposedOwnable__proposeNewOwner_invalidProposal();
  error ProposedOwnable__proposeNewOwner_noOwnershipChange();
  error ProposedOwnable__renounceOwnership_noProposal();
  error ProposedOwnable__renounceOwnership_delayNotElapsed();
  error ProposedOwnable__renounceOwnership_invalidProposal();
  error ProposedOwnable__acceptProposedOwner_delayNotElapsed();

  // ============ Properties ============

  address private _owner;

  address private _proposed;
  uint256 private _proposedOwnershipTimestamp;

  uint256 private constant _delay = 7 days;

  // ======== Getters =========

  /**
   * @notice Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @notice Returns the address of the proposed owner.
   */
  function proposed() public view virtual returns (address) {
    return _proposed;
  }

  /**
   * @notice Returns the address of the proposed owner.
   */
  function proposedTimestamp() public view virtual returns (uint256) {
    return _proposedOwnershipTimestamp;
  }

  /**
   * @notice Returns the delay period before a new owner can be accepted.
   */
  function delay() public view virtual returns (uint256) {
    return _delay;
  }

  /**
   * @notice Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    if (_owner != msg.sender) revert ProposedOwnable__onlyOwner_notOwner();
    _;
  }

  /**
   * @notice Throws if called by any account other than the proposed owner.
   */
  modifier onlyProposed() {
    if (_proposed != msg.sender) revert ProposedOwnable__onlyProposed_notProposedOwner();
    _;
  }

  /**
   * @notice Indicates if the ownership has been renounced() by
   * checking if current owner is address(0)
   */
  function renounced() public view returns (bool) {
    return _owner == address(0);
  }

  // ======== External =========

  /**
   * @notice Sets the timestamp for an owner to be proposed, and sets the
   * newly proposed owner as step 1 in a 2-step process
   */
  function proposeNewOwner(address newlyProposed) public virtual onlyOwner {
    // Contract as source of truth
    if (_proposed == newlyProposed && newlyProposed != address(0))
      revert ProposedOwnable__proposeNewOwner_invalidProposal();

    // Sanity check: reasonable proposal
    if (_owner == newlyProposed) revert ProposedOwnable__proposeNewOwner_noOwnershipChange();

    _setProposed(newlyProposed);
  }

  /**
   * @notice Renounces ownership of the contract after a delay
   */
  function renounceOwnership() public virtual onlyOwner {
    // Ensure there has been a proposal cycle started
    if (_proposedOwnershipTimestamp == 0) revert ProposedOwnable__renounceOwnership_noProposal();

    // Ensure delay has elapsed
    if ((block.timestamp - _proposedOwnershipTimestamp) <= _delay)
      revert ProposedOwnable__renounceOwnership_delayNotElapsed();

    // Require proposed is set to 0
    if (_proposed != address(0)) revert ProposedOwnable__renounceOwnership_invalidProposal();

    // Emit event, set new owner, reset timestamp
    _setOwner(_proposed);
  }

  /**
   * @notice Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function acceptProposedOwner() public virtual onlyProposed {
    // NOTE: no need to check if _owner == _proposed, because the _proposed
    // is 0-d out and this check is implicitly enforced by modifier

    // NOTE: no need to check if _proposedOwnershipTimestamp > 0 because
    // the only time this would happen is if the _proposed was never
    // set (will fail from modifier) or if the owner == _proposed (checked
    // above)

    // Ensure delay has elapsed
    if ((block.timestamp - _proposedOwnershipTimestamp) <= _delay)
      revert ProposedOwnable__acceptProposedOwner_delayNotElapsed();

    // Emit event, set new owner, reset timestamp
    _setOwner(_proposed);
  }

  // ======== Internal =========

  function _setOwner(address newOwner) internal {
    address oldOwner = _owner;
    _owner = newOwner;
    _proposedOwnershipTimestamp = 0;
    _proposed = address(0);
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  function _setProposed(address newlyProposed) private {
    _proposedOwnershipTimestamp = block.timestamp;
    _proposed = newlyProposed;
    emit OwnershipProposed(newlyProposed);
  }
}

abstract contract ProposedOwnableUpgradeable is Initializable, ProposedOwnable {
  /**
   * @dev Initializes the contract setting the deployer as the initial
   */
  function __ProposedOwnable_init() internal onlyInitializing {
    __ProposedOwnable_init_unchained();
  }

  function __ProposedOwnable_init_unchained() internal onlyInitializing {
    _setOwner(msg.sender);
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __GAP;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/**
 * @title IProposedOwnable
 * @notice Defines a minimal interface for ownership with a two step proposal and acceptance
 * process
 */
interface IProposedOwnable {
  /**
   * @dev This emits when change in ownership of a contract is proposed.
   */
  event OwnershipProposed(address indexed proposedOwner);

  /**
   * @dev This emits when ownership of a contract changes.
   */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @notice Get the address of the owner
   * @return owner_ The address of the owner.
   */
  function owner() external view returns (address owner_);

  /**
   * @notice Get the address of the proposed owner
   * @return proposed_ The address of the proposed.
   */
  function proposed() external view returns (address proposed_);

  /**
   * @notice Set the address of the proposed owner of the contract
   * @param newlyProposed The proposed new owner of the contract
   */
  function proposeNewOwner(address newlyProposed) external;

  /**
   * @notice Set the address of the proposed owner of the contract
   */
  function acceptProposedOwner() external;
}