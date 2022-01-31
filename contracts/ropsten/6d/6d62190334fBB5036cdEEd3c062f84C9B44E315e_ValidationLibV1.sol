// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
/* solhint-disable ordering  */
pragma solidity 0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/access/IAccessControl.sol";
import "./ProtoUtilV1.sol";
import "./StoreKeyUtil.sol";
import "./RegistryLibV1.sol";
import "./CoverUtilV1.sol";
import "./GovernanceUtilV1.sol";
import "../interfaces/IStore.sol";
import "../interfaces/IPausable.sol";
import "../interfaces/ICxToken.sol";

library ValidationLibV1 {
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;
  using CoverUtilV1 for IStore;
  using GovernanceUtilV1 for IStore;

  /*********************************************************************************************
    _______ ______    ________ ______
    |      |     |\  / |______|_____/
    |_____ |_____| \/  |______|    \_
                                  
   *********************************************************************************************/

  /**
   * @dev Reverts if the protocol is paused
   */
  function mustNotBePaused(IStore s) public view {
    address protocol = s.getProtocolAddress();
    require(IPausable(protocol).paused() == false, "Protocol is paused");
  }

  /**
   * @dev Reverts if the key does not resolve in a valid cover contract
   * or if the cover is under governance.
   * @param key Enter the cover key to check
   */
  function mustBeValidCover(IStore s, bytes32 key) public view {
    require(s.getBoolByKeys(ProtoUtilV1.NS_COVER, key), "Cover does not exist");
    require(s.getCoverStatus(key) == CoverUtilV1.CoverStatus.Normal, "Actively Reporting");
  }

  /**
   * @dev Reverts if the key does not resolve in a valid cover contract.
   * @param key Enter the cover key to check
   */
  function mustBeValidCoverKey(IStore s, bytes32 key) public view {
    require(s.getBoolByKeys(ProtoUtilV1.NS_COVER, key), "Cover does not exist");
  }

  /**
   * @dev Reverts if the sender is not the cover owner
   * @param key Enter the cover key to check
   * @param sender The `msg.sender` value
   */
  function mustBeCoverOwner(
    IStore s,
    bytes32 key,
    address sender
  ) public view {
    bool isCoverOwner = s.getCoverOwner(key) == sender;
    require(isCoverOwner, "Forbidden");
  }

  function callerMustBePolicyContract(IStore s) external view {
    s.callerMustBeExactContract(ProtoUtilV1.NS_COVER_POLICY);
  }

  function callerMustBePolicyManagerContract(IStore s) external view {
    s.callerMustBeExactContract(ProtoUtilV1.NS_COVER_POLICY_MANAGER);
  }

  function callerMustBeCoverContract(IStore s) external view {
    s.callerMustBeExactContract(ProtoUtilV1.NS_COVER);
  }

  function callerMustBeGovernanceContract(IStore s) external view {
    s.callerMustBeExactContract(ProtoUtilV1.NS_GOVERNANCE);
  }

  function callerMustBeClaimsProcessorContract(IStore s) external view {
    s.callerMustBeExactContract(ProtoUtilV1.NS_CLAIMS_PROCESSOR);
  }

  /*********************************************************************************************
   ______  _____  _    _ _______  ______ __   _ _______ __   _ _______ _______
  |  ____ |     |  \  /  |______ |_____/ | \  | |_____| | \  | |       |______
  |_____| |_____|   \/   |______ |    \_ |  \_| |     | |  \_| |_____  |______

  *********************************************************************************************/

  function mustBeReporting(IStore s, bytes32 key) public view {
    require(s.getCoverStatus(key) == CoverUtilV1.CoverStatus.IncidentHappened, "Not reporting");
  }

  function mustBeDisputed(IStore s, bytes32 key) public view {
    require(s.getCoverStatus(key) == CoverUtilV1.CoverStatus.FalseReporting, "Not disputed");
  }

  function mustBeClaimable(IStore s, bytes32 key) public view {
    require(s.getCoverStatus(key) == CoverUtilV1.CoverStatus.Claimable, "Not claimable");
  }

  function mustBeClaimingOrDisputed(IStore s, bytes32 key) public view {
    CoverUtilV1.CoverStatus status = s.getCoverStatus(key);

    bool claiming = status == CoverUtilV1.CoverStatus.Claimable;
    bool falseReporting = status == CoverUtilV1.CoverStatus.FalseReporting;

    require(claiming || falseReporting, "Not reported nor disputed");
  }

  function mustBeReportingOrDisputed(IStore s, bytes32 key) public view {
    CoverUtilV1.CoverStatus status = s.getCoverStatus(key);
    bool incidentHappened = status == CoverUtilV1.CoverStatus.IncidentHappened;
    bool falseReporting = status == CoverUtilV1.CoverStatus.FalseReporting;

    require(incidentHappened || falseReporting, "Not reported nor disputed");
  }

  function mustBeValidIncidentDate(
    IStore s,
    bytes32 key,
    uint256 incidentDate
  ) public view {
    require(s.getLatestIncidentDate(key) == incidentDate, "Invalid incident date");
  }

  function mustNotHaveDispute(IStore s, bytes32 key) public view {
    address reporter = s.getAddressByKeys(ProtoUtilV1.NS_REPORTING_WITNESS_NO, key);
    require(reporter == address(0), "Already disputed");
  }

  function mustBeDuringReportingPeriod(IStore s, bytes32 key) public view {
    require(s.getUintByKeys(ProtoUtilV1.NS_RESOLUTION_TS, key) >= block.timestamp, "Reporting window closed"); // solhint-disable-line
  }

  function mustBeAfterReportingPeriod(IStore s, bytes32 key) public view {
    require(block.timestamp > s.getUintByKeys(ProtoUtilV1.NS_RESOLUTION_TS, key), "Reporting still active"); // solhint-disable-line
  }

  function mustBeValidCxToken(
    bytes32 key,
    address cxToken,
    uint256 incidentDate
  ) public view {
    // Vulnerability in mustBeValidCToken validation logic #5
    // https://github.com/neptune-mutual/protocol/issues/5
    bytes32 coverKey = ICxToken(cxToken).coverKey();
    require(coverKey == key, "Invalid cxToken");

    uint256 expires = ICxToken(cxToken).expiresOn();
    require(expires > incidentDate, "Invalid or expired cxToken");
  }

  function mustBeValidClaim(
    IStore s,
    bytes32 key,
    address cxToken,
    uint256 incidentDate
  ) public view {
    require(s.getCoverStatus(key) == CoverUtilV1.CoverStatus.Claimable, "Your claim is denied");

    s.mustBeProtocolMember(cxToken);
    mustBeValidIncidentDate(s, key, incidentDate);
    mustBeValidCxToken(key, cxToken, incidentDate);
    mustBeDuringClaimPeriod(s, key);
  }

  function mustNotHaveUnstaken(
    IStore s,
    address account,
    bytes32 key,
    uint256 incidentDate
  ) public view {
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_UNSTAKE_TS, key, incidentDate, account));
    uint256 withdrawal = s.getUintByKey(k);

    require(withdrawal == 0, "Already unstaken");
  }

  function mustBeDuringClaimPeriod(IStore s, bytes32 key) public view {
    uint256 beginsFrom = s.getUintByKeys(ProtoUtilV1.NS_CLAIM_BEGIN_TS, key);
    require(block.timestamp >= beginsFrom, "Claim period hasn't begun"); // solhint-disable-line

    uint256 expiresAt = s.getUintByKeys(ProtoUtilV1.NS_CLAIM_EXPIRY_TS, key);
    require(block.timestamp <= expiresAt, "Claim period has expired"); // solhint-disable-line
  }

  function mustBeAfterClaimExpiry(IStore s, bytes32 key) public view {
    require(block.timestamp > s.getUintByKeys(ProtoUtilV1.NS_CLAIM_EXPIRY_TS, key), "Claim still active"); // solhint-disable-line
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "../interfaces/IStore.sol";
import "../interfaces/IProtocol.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./StoreKeyUtil.sol";

library ProtoUtilV1 {
  using StoreKeyUtil for IStore;

  bytes32 public constant NS_CORE = "proto:core";
  bytes32 public constant NS_REASSURANCE_VAULT = "proto:core:reassurance:vault";

  /// @dev The address where burn tokens are sent or collected.
  /// This behavior (collection) is required if the instance of
  /// the Neptune Mutual protocol is deployed on a sidechain
  /// or a layer-2 blockchain.
  /// &nbsp;\n
  /// The collected NPM tokens are will be periodically bridged back to Ethereum
  /// and then burned.
  bytes32 public constant NS_BURNER = "proto:core:burner";

  /// @dev Namespace for all protocol members.
  bytes32 public constant NS_MEMBERS = "proto:members";

  /// @dev Namespace for protocol contract members.
  bytes32 public constant NS_CONTRACTS = "proto:contracts";

  /// @dev Key prefix for creating a new cover product on chain
  bytes32 public constant NS_COVER = "proto:cover";

  /// @dev Governance contract address
  bytes32 public constant NS_GOVERNANCE = "proto:gov";

  /// @dev Governance:Resolution contract address
  bytes32 public constant NS_RESOLUTION = "proto:gov:resolution";

  /// @dev The timestamp when a tokenholder withdraws their reporting stake
  bytes32 public constant NS_UNSTAKEN = "proto:gov:unstaken";

  /// @dev The timestamp when a tokenholder withdraws their reporting stake
  bytes32 public constant NS_UNSTAKE_TS = "proto:gov:unstake:ts";

  /// @dev The reward received by the winning camp
  bytes32 public constant NS_UNSTAKE_REWARD = "proto:gov:unstake:reward";

  /// @dev The stakes burned during incident resolution
  bytes32 public constant NS_UNSTAKE_BURNED = "proto:gov:unstake:burned";

  /// @dev The stakes burned during incident resolution
  bytes32 public constant NS_UNSTAKE_REPORTER_FEE = "proto:gov:unstake:rep:fee";

  /// @dev Claims processor contract address
  bytes32 public constant NS_CLAIMS_PROCESSOR = "proto:claims:processor";

  bytes32 public constant NS_COVER_REASSURANCE = "proto:cover:reassurance";
  bytes32 public constant NS_COVER_REASSURANCE_TOKEN = "proto:cover:reassurance:token";
  bytes32 public constant NS_COVER_REASSURANCE_WEIGHT = "proto:cover:reassurance:weight";
  bytes32 public constant NS_COVER_CLAIMABLE = "proto:cover:claimable";
  bytes32 public constant NS_COVER_FEE = "proto:cover:fee";
  bytes32 public constant NS_COVER_INFO = "proto:cover:info";
  bytes32 public constant NS_COVER_LIQUIDITY = "proto:cover:liquidity";
  bytes32 public constant NS_COVER_LIQUIDITY_COMMITTED = "proto:cover:liquidity:committed";
  bytes32 public constant NS_COVER_LIQUIDITY_NAME = "proto:cover:liquidityName";
  bytes32 public constant NS_COVER_LIQUIDITY_TOKEN = "proto:cover:liquidityToken";
  bytes32 public constant NS_COVER_LIQUIDITY_RELEASE_DATE = "proto:cover:liquidity:release";
  bytes32 public constant NS_COVER_OWNER = "proto:cover:owner";
  bytes32 public constant NS_COVER_POLICY = "proto:cover:policy";
  bytes32 public constant NS_COVER_POLICY_ADMIN = "proto:cover:policy:admin";
  bytes32 public constant NS_COVER_POLICY_MANAGER = "proto:cover:policy:manager";
  bytes32 public constant NS_COVER_POLICY_RATE_FLOOR = "proto:cover:policy:rate:floor";
  bytes32 public constant NS_COVER_POLICY_RATE_CEILING = "proto:cover:policy:rate:ceiling";
  bytes32 public constant NS_COVER_PROVISION = "proto:cover:provision";
  bytes32 public constant NS_COVER_STAKE = "proto:cover:stake";
  bytes32 public constant NS_COVER_STAKE_OWNED = "proto:cover:stake:owned";
  bytes32 public constant NS_COVER_STATUS = "proto:cover:status";
  bytes32 public constant NS_COVER_VAULT = "proto:cover:vault";
  bytes32 public constant NS_COVER_VAULT_FACTORY = "proto:cover:vault:factory";
  bytes32 public constant NS_COVER_CXTOKEN = "proto:cover:cxtoken";
  bytes32 public constant NS_COVER_CXTOKEN_FACTORY = "proto:cover:cxtoken:factory";
  bytes32 public constant NS_COVER_WHITELIST = "proto:cover:whitelist";
  bytes32 public constant NS_TREASURY = "proto:core:treasury";
  bytes32 public constant NS_PRICE_DISCOVERY = "proto:core:price:discovery";

  /// @dev An approximate date and time when trigger event or cover incident occured
  bytes32 public constant NS_REPORTING_INCIDENT_DATE = "proto:reporting:incident:date";

  /// @dev A period (in solidity timestamp) configurable by cover creators during
  /// when NPM tokenholders can vote on incident reporting proposals
  bytes32 public constant NS_REPORTING_PERIOD = "proto:reporting:period";

  /// @dev Resolution timestamp = timestamp of first reporting + reporting period
  bytes32 public constant NS_RESOLUTION_TS = "proto:reporting:resolution:ts";

  /// @dev A 24-hour delay after a governance agent "resolves" an actively reported cover.
  bytes32 public constant NS_CLAIM_BEGIN_TS = "proto:claim:begin:ts";

  /// @dev Claim expiry date = Claim begin date + claim duration
  bytes32 public constant NS_CLAIM_EXPIRY_TS = "proto:claim:expiry:ts";

  /// @dev Used as key element in a couple of places:
  /// 1. For uint256 --> Sum total of NPM witnesses who saw incident to have happened
  /// 2. For address --> The address of the first reporter
  bytes32 public constant NS_REPORTING_WITNESS_YES = "proto:reporting:witness:yes";

  /// @dev Used as key element in a couple of places:
  /// 1. For uint256 --> Sum total of NPM witnesses who disagreed with and disputed an incident reporting
  /// 2. For address --> The address of the first disputing reporter (disputer / candidate reporter)
  bytes32 public constant NS_REPORTING_WITNESS_NO = "proto:reporting:witness:no";

  /// @dev Stakes guaranteed by an individual witness supporting the "incident happened" camp
  bytes32 public constant NS_REPORTING_STAKE_OWNED_YES = "proto:reporting:stake:owned:yes";

  /// @dev Stakes guaranteed by an individual witness supporting the "false reporting" camp
  bytes32 public constant NS_REPORTING_STAKE_OWNED_NO = "proto:reporting:stake:owned:no";

  /// @dev The address of NPM token available in this blockchain
  bytes32 public constant NS_SETUP_NPM = "proto:setup:npm";

  /// @dev The percentage rate (x 1 ether) of amount of reporting/unstake reward to burn.
  /// Note that the reward comes from the losing camp after resolution is achieved.
  bytes32 public constant NS_REPORTING_BURN_RATE = "proto:reporting:burn:rate";

  /// @dev The percentage rate (x 1 ether) of amount of reporting/unstake
  /// reward to provide to the final reporter.
  bytes32 public constant NS_REPORTER_COMMISSION = "proto:reporter:commission";

  bytes32 public constant NS_SETUP_COVER_FEE = "proto:setup:cover:fee";
  bytes32 public constant NS_SETUP_MIN_STAKE = "proto:setup:min:stake";
  bytes32 public constant NS_SETUP_FIRST_REPORTING_STAKE = "proto:setup:1st:reporting:stake";
  bytes32 public constant NS_SETUP_MIN_LIQ_PERIOD = "proto:setup:min:liq:period";
  bytes32 public constant NS_SETUP_CLAIM_PERIOD = "proto:setup:claim:period";
  bytes32 public constant NS_SETUP_UNISWAP_V2_ROUTER = "proto:uniswap:v2:router";

  bytes32 public constant CNAME_PROTOCOL = "Protocol";
  bytes32 public constant CNAME_TREASURY = "Treasury";
  bytes32 public constant CNAME_POLICY = "Policy";
  bytes32 public constant CNAME_POLICY_ADMIN = "PolicyAdmin";
  bytes32 public constant CNAME_POLICY_MANAGER = "PolicyManager";
  bytes32 public constant CNAME_CLAIMS_PROCESSOR = "ClaimsProcessor";
  bytes32 public constant CNAME_PRICE_DISCOVERY = "PriceDiscovery";
  bytes32 public constant CNAME_COVER = "Cover";
  bytes32 public constant CNAME_GOVERNANCE = "Governance";
  bytes32 public constant CNAME_RESOLUTION = "Resolution";
  bytes32 public constant CNAME_VAULT_FACTORY = "VaultFactory";
  bytes32 public constant CNAME_CXTOKEN_FACTORY = "cxTokenFactory";
  bytes32 public constant CNAME_COVER_PROVISION = "CoverProvison";
  bytes32 public constant CNAME_COVER_STAKE = "CoverStake";
  bytes32 public constant CNAME_COVER_REASSURANCE = "CoverReassurance";
  bytes32 public constant CNAME_LIQUIDITY_VAULT = "Vault";

  function getProtocol(IStore s) external view returns (IProtocol) {
    return IProtocol(getProtocolAddress(s));
  }

  function getProtocolAddress(IStore s) public view returns (address) {
    return s.getAddressByKey(NS_CORE);
  }

  function getContract(IStore s, bytes32 name) external view returns (address) {
    return _getContract(s, name);
  }

  function isProtocolMember(IStore s, address contractAddress) external view returns (bool) {
    return _isProtocolMember(s, contractAddress);
  }

  /**
   * @dev Reverts if the caller is one of the protocol members.
   */
  function mustBeProtocolMember(IStore s, address contractAddress) external view {
    bool isMember = _isProtocolMember(s, contractAddress);
    require(isMember, "Not a protocol member");
  }

  /**
   * @dev Ensures that the sender matches with the exact contract having the specified name.
   * @param name Enter the name of the contract
   * @param sender Enter the `msg.sender` value
   */
  function mustBeExactContract(
    IStore s,
    bytes32 name,
    address sender
  ) public view {
    address contractAddress = _getContract(s, name);
    require(sender == contractAddress, "Access denied");
  }

  /**
   * @dev Ensures that the sender matches with the exact contract having the specified name.
   * @param name Enter the name of the contract
   */
  function callerMustBeExactContract(IStore s, bytes32 name) external view {
    return mustBeExactContract(s, name, msg.sender);
  }

  function npmToken(IStore s) external view returns (IERC20) {
    address npm = s.getAddressByKey(NS_SETUP_NPM);
    return IERC20(npm);
  }

  function getUniswapV2Router(IStore s) external view returns (address) {
    return s.getAddressByKey(NS_SETUP_UNISWAP_V2_ROUTER);
  }

  function getTreasury(IStore s) external view returns (address) {
    return s.getAddressByKey(NS_TREASURY);
  }

  function getReassuranceVault(IStore s) external view returns (address) {
    return s.getAddressByKey(NS_REASSURANCE_VAULT);
  }

  function getLiquidityToken(IStore s) public view returns (address) {
    return s.getAddressByKey(NS_COVER_LIQUIDITY_TOKEN);
  }

  function getBurnAddress(IStore s) external view returns (address) {
    return s.getAddressByKey(NS_BURNER);
  }

  function toKeccak256(bytes memory value) external pure returns (bytes32) {
    return keccak256(value);
  }

  function _isProtocolMember(IStore s, address contractAddress) private view returns (bool) {
    return s.getBoolByKeys(ProtoUtilV1.NS_MEMBERS, contractAddress);
  }

  function _getContract(IStore s, bytes32 name) private view returns (address) {
    return s.getAddressByKeys(NS_CONTRACTS, name);
  }

  function addContract(
    IStore s,
    bytes32 namespace,
    address contractAddress
  ) external {
    _addContract(s, namespace, contractAddress);
  }

  function _addContract(
    IStore s,
    bytes32 namespace,
    address contractAddress
  ) private {
    s.setAddressByKeys(ProtoUtilV1.NS_CONTRACTS, namespace, contractAddress);
    _addMember(s, contractAddress);
  }

  function deleteContract(
    IStore s,
    bytes32 namespace,
    address contractAddress
  ) external {
    _deleteContract(s, namespace, contractAddress);
  }

  function _deleteContract(
    IStore s,
    bytes32 namespace,
    address contractAddress
  ) private {
    s.deleteAddressByKeys(ProtoUtilV1.NS_CONTRACTS, namespace);
    _removeMember(s, contractAddress);
  }

  function upgradeContract(
    IStore s,
    bytes32 namespace,
    address previous,
    address current
  ) external {
    bool isMember = _isProtocolMember(s, previous);
    require(isMember, "Not a protocol member");

    _deleteContract(s, namespace, previous);
    _addContract(s, namespace, current);
  }

  function addMember(IStore s, address member) external {
    _addMember(s, member);
  }

  function removeMember(IStore s, address member) external {
    _removeMember(s, member);
  }

  function _addMember(IStore s, address member) private {
    require(s.getBoolByKeys(ProtoUtilV1.NS_MEMBERS, member) == false, "Already exists");
    s.setBoolByKeys(ProtoUtilV1.NS_MEMBERS, member, true);
  }

  function _removeMember(IStore s, address member) private {
    s.deleteBoolByKeys(ProtoUtilV1.NS_MEMBERS, member);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
// solhint-disable func-order
pragma solidity 0.8.0;
import "../interfaces/IStore.sol";

library StoreKeyUtil {
  function setUintByKey(
    IStore s,
    bytes32 key,
    uint256 value
  ) external {
    require(key > 0, "Invalid key");
    return s.setUint(key, value);
  }

  function setUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    uint256 value
  ) external {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.setUint(keccak256(abi.encodePacked(key1, key2)), value);
  }

  function setUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account,
    uint256 value
  ) external {
    require(key1 > 0 && key2 > 0 && account != address(0), "Invalid key(s)");
    return s.setUint(keccak256(abi.encodePacked(key1, key2, account)), value);
  }

  function addUintByKey(
    IStore s,
    bytes32 key,
    uint256 value
  ) external {
    require(key > 0, "Invalid key");
    return s.addUint(key, value);
  }

  function addUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    uint256 value
  ) external {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.addUint(keccak256(abi.encodePacked(key1, key2)), value);
  }

  function addUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account,
    uint256 value
  ) external {
    require(key1 > 0 && key2 > 0 && account != address(0), "Invalid key(s)");
    return s.addUint(keccak256(abi.encodePacked(key1, key2, account)), value);
  }

  function subtractUintByKey(
    IStore s,
    bytes32 key,
    uint256 value
  ) external {
    require(key > 0, "Invalid key");
    return s.subtractUint(key, value);
  }

  function subtractUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    uint256 value
  ) external {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.subtractUint(keccak256(abi.encodePacked(key1, key2)), value);
  }

  function subtractUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account,
    uint256 value
  ) external {
    require(key1 > 0 && key2 > 0 && account != address(0), "Invalid key(s)");
    return s.subtractUint(keccak256(abi.encodePacked(key1, key2, account)), value);
  }

  function setBytes32ByKey(
    IStore s,
    bytes32 key,
    bytes32 value
  ) external {
    require(key > 0, "Invalid key");
    s.setBytes32(key, value);
  }

  function setBytes32ByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 value
  ) external {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.setBytes32(keccak256(abi.encodePacked(key1, key2)), value);
  }

  function setBoolByKey(
    IStore s,
    bytes32 key,
    bool value
  ) external {
    require(key > 0, "Invalid key");
    return s.setBool(key, value);
  }

  function setBoolByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bool value
  ) external {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.setBool(keccak256(abi.encodePacked(key1, key2)), value);
  }

  function setBoolByKeys(
    IStore s,
    bytes32 key,
    address account,
    bool value
  ) external {
    require(key > 0 && account != address(0), "Invalid key(s)");
    return s.setBool(keccak256(abi.encodePacked(key, account)), value);
  }

  function setAddressByKey(
    IStore s,
    bytes32 key,
    address value
  ) external {
    require(key > 0, "Invalid key");
    return s.setAddress(key, value);
  }

  function setAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address value
  ) external {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.setAddress(keccak256(abi.encodePacked(key1, key2)), value);
  }

  function setAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address value
  ) external {
    require(key1 > 0 && key2 > 0 && key3 > 0, "Invalid key(s)");
    return s.setAddress(keccak256(abi.encodePacked(key1, key2, key3)), value);
  }

  function setAddressBooleanByKey(
    IStore s,
    bytes32 key,
    address account,
    bool value
  ) external {
    require(key > 0, "Invalid key");
    return s.setAddressBoolean(key, account, value);
  }

  function setAddressBooleanByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account,
    bool value
  ) external {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.setAddressBoolean(keccak256(abi.encodePacked(key1, key2)), account, value);
  }

  function setAddressBooleanByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address account,
    bool value
  ) external {
    require(key1 > 0 && key2 > 0 && key3 > 0, "Invalid key(s)");
    return s.setAddressBoolean(keccak256(abi.encodePacked(key1, key2, key3)), account, value);
  }

  function deleteUintByKey(IStore s, bytes32 key) external {
    require(key > 0, "Invalid key");
    return s.deleteUint(key);
  }

  function deleteUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.deleteUint(keccak256(abi.encodePacked(key1, key2)));
  }

  function deleteBytes32ByKey(IStore s, bytes32 key) external {
    require(key > 0, "Invalid key");
    s.deleteBytes32(key);
  }

  function deleteBytes32ByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.deleteBytes32(keccak256(abi.encodePacked(key1, key2)));
  }

  function deleteBoolByKey(IStore s, bytes32 key) external {
    require(key > 0, "Invalid key");
    return s.deleteBool(key);
  }

  function deleteBoolByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.deleteBool(keccak256(abi.encodePacked(key1, key2)));
  }

  function deleteBoolByKeys(
    IStore s,
    bytes32 key,
    address account
  ) external {
    require(key > 0 && account != address(0), "Invalid key(s)");
    return s.deleteBool(keccak256(abi.encodePacked(key, account)));
  }

  function deleteAddressByKey(IStore s, bytes32 key) external {
    require(key > 0, "Invalid key");
    return s.deleteAddress(key);
  }

  function deleteAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.deleteAddress(keccak256(abi.encodePacked(key1, key2)));
  }

  function getUintByKey(IStore s, bytes32 key) external view returns (uint256) {
    require(key > 0, "Invalid key");
    return s.getUint(key);
  }

  function getUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (uint256) {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.getUint(keccak256(abi.encodePacked(key1, key2)));
  }

  function getUintByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account
  ) external view returns (uint256) {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.getUint(keccak256(abi.encodePacked(key1, key2, account)));
  }

  function getBytes32ByKey(IStore s, bytes32 key) external view returns (bytes32) {
    require(key > 0, "Invalid key");
    return s.getBytes32(key);
  }

  function getBytes32ByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (bytes32) {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.getBytes32(keccak256(abi.encodePacked(key1, key2)));
  }

  function getBoolByKey(IStore s, bytes32 key) external view returns (bool) {
    require(key > 0, "Invalid key");
    return s.getBool(key);
  }

  function getBoolByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (bool) {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.getBool(keccak256(abi.encodePacked(key1, key2)));
  }

  function getBoolByKeys(
    IStore s,
    bytes32 key,
    address account
  ) external view returns (bool) {
    require(key > 0 && account != address(0), "Invalid key(s)");
    return s.getBool(keccak256(abi.encodePacked(key, account)));
  }

  function getAddressByKey(IStore s, bytes32 key) external view returns (address) {
    require(key > 0, "Invalid key");
    return s.getAddress(key);
  }

  function getAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2
  ) external view returns (address) {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.getAddress(keccak256(abi.encodePacked(key1, key2)));
  }

  function getAddressByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3
  ) external view returns (address) {
    require(key1 > 0 && key2 > 0 && key3 > 0, "Invalid key(s)");
    return s.getAddress(keccak256(abi.encodePacked(key1, key2, key3)));
  }

  function getAddressBooleanByKey(
    IStore s,
    bytes32 key,
    address account
  ) external view returns (bool) {
    require(key > 0, "Invalid key");
    return s.getAddressBoolean(key, account);
  }

  function getAddressBooleanByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    address account
  ) external view returns (bool) {
    require(key1 > 0 && key2 > 0, "Invalid key(s)");
    return s.getAddressBoolean(keccak256(abi.encodePacked(key1, key2)), account);
  }

  function getAddressBooleanByKeys(
    IStore s,
    bytes32 key1,
    bytes32 key2,
    bytes32 key3,
    address account
  ) external view returns (bool) {
    require(key1 > 0 && key2 > 0 && key3 > 0, "Invalid key(s)");
    return s.getAddressBoolean(keccak256(abi.encodePacked(key1, key2, key3)), account);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;

import "./ProtoUtilV1.sol";
import "./StoreKeyUtil.sol";
import "../interfaces/IPolicy.sol";
import "../interfaces/ICoverStake.sol";
import "../interfaces/IPriceDiscovery.sol";
import "../interfaces/ICxTokenFactory.sol";
import "../interfaces/ICoverReassurance.sol";
import "../interfaces/IGovernance.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IVaultFactory.sol";

library RegistryLibV1 {
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;

  function getPriceDiscoveryContract(IStore s) public view returns (IPriceDiscovery) {
    return IPriceDiscovery(s.getContract(ProtoUtilV1.NS_PRICE_DISCOVERY));
  }

  function getGovernanceContract(IStore s) public view returns (IGovernance) {
    return IGovernance(s.getContract(ProtoUtilV1.NS_GOVERNANCE));
  }

  function getResolutionContract(IStore s) public view returns (IGovernance) {
    return IGovernance(s.getContract(ProtoUtilV1.NS_RESOLUTION));
  }

  function getStakingContract(IStore s) public view returns (ICoverStake) {
    return ICoverStake(s.getContract(ProtoUtilV1.NS_COVER_STAKE));
  }

  function getCxTokenFactory(IStore s) public view returns (ICxTokenFactory) {
    return ICxTokenFactory(s.getContract(ProtoUtilV1.NS_COVER_CXTOKEN_FACTORY));
  }

  function getPolicyContract(IStore s) public view returns (IPolicy) {
    return IPolicy(s.getContract(ProtoUtilV1.NS_COVER_POLICY));
  }

  function getReassuranceContract(IStore s) public view returns (ICoverReassurance) {
    return ICoverReassurance(s.getContract(ProtoUtilV1.NS_COVER_REASSURANCE));
  }

  function getVault(IStore s, bytes32 key) public view returns (IVault) {
    address vault = s.getAddressByKeys(ProtoUtilV1.NS_CONTRACTS, ProtoUtilV1.NS_COVER_VAULT, key);
    return IVault(vault);
  }

  function getVaultFactoryContract(IStore s) public view returns (IVaultFactory) {
    address factory = s.getContract(ProtoUtilV1.NS_COVER_VAULT_FACTORY);
    return IVaultFactory(factory);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "../interfaces/IStore.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./ProtoUtilV1.sol";
import "./StoreKeyUtil.sol";
import "./RegistryLibV1.sol";

library CoverUtilV1 {
  using RegistryLibV1 for IStore;
  using ProtoUtilV1 for IStore;
  using StoreKeyUtil for IStore;

  enum CoverStatus {
    Normal,
    Stopped,
    IncidentHappened,
    FalseReporting,
    Claimable
  }

  function getCoverOwner(IStore s, bytes32 key) external view returns (address) {
    return _getCoverOwner(s, key);
  }

  function _getCoverOwner(IStore s, bytes32 key) private view returns (address) {
    return s.getAddressByKeys(ProtoUtilV1.NS_COVER_OWNER, key);
  }

  function getCoverFee(IStore s) external view returns (uint256 fee, uint256 minStake) {
    fee = s.getUintByKey(ProtoUtilV1.NS_SETUP_COVER_FEE);
    minStake = s.getUintByKey(ProtoUtilV1.NS_SETUP_MIN_STAKE);
  }

  function getMinCoverStake(IStore s) external view returns (uint256) {
    return s.getUintByKey(ProtoUtilV1.NS_SETUP_MIN_STAKE);
  }

  function getMinLiquidityPeriod(IStore s) external view returns (uint256) {
    return s.getUintByKey(ProtoUtilV1.NS_SETUP_MIN_LIQ_PERIOD);
  }

  function getClaimPeriod(IStore s) external view returns (uint256) {
    return s.getUintByKey(ProtoUtilV1.NS_SETUP_CLAIM_PERIOD);
  }

  /**
   * @dev Gets the current status of a given cover
   *
   * 0 - normal
   * 1 - stopped, can not purchase covers or add liquidity
   * 2 - reporting, incident happened
   * 3 - reporting, false reporting
   * 4 - claimable, claims accepted for payout
   *
   */
  function getCoverStatus(IStore s, bytes32 key) public view returns (CoverStatus) {
    return CoverStatus(getStatus(s, key));
  }

  function getStatus(IStore s, bytes32 key) public view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_COVER_STATUS, key);
  }

  /**
   * @dev Todo: Returns the values of the given cover key
   * @param _values[0] The total amount in the cover pool
   * @param _values[1] The total commitment amount
   * @param _values[2] The total amount of NPM provision
   * @param _values[3] NPM price
   * @param _values[4] The total amount of reassurance tokens
   * @param _values[5] Reassurance token price
   * @param _values[6] Reassurance pool weight
   */
  function getCoverPoolSummary(IStore s, bytes32 key) external view returns (uint256[] memory _values) {
    require(getCoverStatus(s, key) == CoverStatus.Normal, "Invalid cover");
    IPriceDiscovery discovery = s.getPriceDiscoveryContract();

    _values = new uint256[](7);

    _values[0] = s.getUintByKeys(ProtoUtilV1.NS_COVER_LIQUIDITY, key);
    _values[1] = s.getUintByKeys(ProtoUtilV1.NS_COVER_LIQUIDITY_COMMITTED, key); // <-- Todo: liquidity commitment should expire as policies expire
    _values[2] = s.getUintByKeys(ProtoUtilV1.NS_COVER_PROVISION, key);
    _values[3] = discovery.getTokenPriceInStableCoin(address(s.npmToken()), 1 ether);
    _values[4] = s.getUintByKeys(ProtoUtilV1.NS_COVER_REASSURANCE, key);
    _values[5] = discovery.getTokenPriceInStableCoin(address(s.getAddressByKeys(ProtoUtilV1.NS_COVER_REASSURANCE_TOKEN, key)), 1 ether);
    _values[6] = s.getUintByKeys(ProtoUtilV1.NS_COVER_REASSURANCE_WEIGHT, key);
  }

  function getPolicyRates(IStore s, bytes32 key) external view returns (uint256 floor, uint256 ceiling) {
    floor = s.getUintByKeys(ProtoUtilV1.NS_COVER_POLICY_RATE_FLOOR, key);
    ceiling = s.getUintByKeys(ProtoUtilV1.NS_COVER_POLICY_RATE_CEILING, key);

    if (floor == 0) {
      // Fallback to default values
      floor = s.getUintByKey(ProtoUtilV1.NS_COVER_POLICY_RATE_FLOOR);
      ceiling = s.getUintByKey(ProtoUtilV1.NS_COVER_POLICY_RATE_CEILING);
    }
  }

  function getLiquidity(IStore s, bytes32 key) public view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_COVER_LIQUIDITY, key);
  }

  function getStake(IStore s, bytes32 key) public view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_COVER_STAKE, key);
  }

  function getClaimable(IStore s, bytes32 key) external view returns (uint256) {
    return _getClaimable(s, key);
  }

  function getCoverInfo(IStore s, bytes32 key)
    external
    view
    returns (
      address owner,
      bytes32 info,
      uint256[] memory values
    )
  {
    info = s.getBytes32ByKeys(ProtoUtilV1.NS_COVER_INFO, key);
    owner = s.getAddressByKeys(ProtoUtilV1.NS_COVER_OWNER, key);

    values = new uint256[](5);

    values[0] = s.getUintByKeys(ProtoUtilV1.NS_COVER_FEE, key);
    values[1] = s.getUintByKeys(ProtoUtilV1.NS_COVER_STAKE, key);
    values[2] = s.getUintByKeys(ProtoUtilV1.NS_COVER_LIQUIDITY, key);
    values[3] = s.getUintByKeys(ProtoUtilV1.NS_COVER_PROVISION, key);

    values[4] = _getClaimable(s, key);
  }

  /**
   * @dev Sets the current status of a given cover
   *
   * 0 - normal
   * 1 - stopped, can not purchase covers or add liquidity
   * 2 - reporting, incident happened
   * 3 - reporting, false reporting
   * 4 - claimable, claims accepted for payout
   *
   */
  function setStatus(
    IStore s,
    bytes32 key,
    CoverStatus status
  ) external {
    s.setUintByKeys(ProtoUtilV1.NS_COVER_STATUS, key, uint256(status));
  }

  function _getClaimable(IStore s, bytes32 key) private view returns (uint256) {
    // Todo: deduct the expired cover amounts
    return s.getUintByKeys(ProtoUtilV1.NS_COVER_CLAIMABLE, key);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "../interfaces/IStore.sol";
import "../interfaces/IPolicy.sol";
import "../interfaces/ICoverStake.sol";
import "../interfaces/IPriceDiscovery.sol";
import "../interfaces/ICoverReassurance.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IVaultFactory.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./ProtoUtilV1.sol";
import "./StoreKeyUtil.sol";
import "./CoverUtilV1.sol";

library GovernanceUtilV1 {
  using CoverUtilV1 for IStore;
  using StoreKeyUtil for IStore;

  function getReportingPeriod(IStore s, bytes32 key) external view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_REPORTING_PERIOD, key);
  }

  function getReportingBurnRate(IStore s) public view returns (uint256) {
    return s.getUintByKey(ProtoUtilV1.NS_REPORTING_BURN_RATE);
  }

  function getReporterCommission(IStore s) public view returns (uint256) {
    return s.getUintByKey(ProtoUtilV1.NS_REPORTER_COMMISSION);
  }

  function getMinReportingStake(IStore s) external view returns (uint256) {
    return s.getUintByKey(ProtoUtilV1.NS_SETUP_FIRST_REPORTING_STAKE);
  }

  function getLatestIncidentDate(IStore s, bytes32 key) external view returns (uint256) {
    return _getLatestIncidentDate(s, key);
  }

  function getResolutionTimestamp(IStore s, bytes32 key) external view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_RESOLUTION_TS, key);
  }

  function getReporter(
    IStore s,
    bytes32 key,
    uint256 incidentDate
  ) external view returns (address) {
    (uint256 yes, uint256 no) = getStakes(s, key, incidentDate);

    bytes32 prefix = yes >= no ? ProtoUtilV1.NS_REPORTING_WITNESS_YES : ProtoUtilV1.NS_REPORTING_WITNESS_NO;
    return s.getAddressByKeys(prefix, key);
  }

  function getStakes(
    IStore s,
    bytes32 key,
    uint256 incidentDate
  ) public view returns (uint256 yes, uint256 no) {
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_WITNESS_YES, key, incidentDate));
    yes = s.getUintByKey(k);

    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_WITNESS_NO, key, incidentDate));
    no = s.getUintByKey(k);
  }

  function getResolutionInfoFor(
    IStore s,
    address account,
    bytes32 key,
    uint256 incidentDate
  )
    public
    view
    returns (
      uint256 totalStakeInWinningCamp,
      uint256 totalStakeInLosingCamp,
      uint256 myStakeInWinningCamp
    )
  {
    (uint256 yes, uint256 no) = getStakes(s, key, incidentDate);
    (uint256 myYes, uint256 myNo) = getStakesOf(s, account, key, incidentDate);

    totalStakeInWinningCamp = yes > no ? yes : no;
    totalStakeInLosingCamp = yes > no ? no : yes;
    myStakeInWinningCamp = yes > no ? myYes : myNo;
  }

  function getUnstakeInfoFor(
    IStore s,
    address account,
    bytes32 key,
    uint256 incidentDate
  )
    public
    view
    returns (
      uint256 totalStakeInWinningCamp,
      uint256 totalStakeInLosingCamp,
      uint256 myStakeInWinningCamp,
      uint256 toBurn,
      uint256 toReporter,
      uint256 myReward
    )
  {
    (totalStakeInWinningCamp, totalStakeInLosingCamp, myStakeInWinningCamp) = getResolutionInfoFor(s, account, key, incidentDate);

    require(myStakeInWinningCamp > 0, "Nothing to unstake");

    uint256 rewardRatio = (myStakeInWinningCamp * 1 ether) / totalStakeInWinningCamp;
    uint256 reward = (totalStakeInLosingCamp * rewardRatio) / 1 ether;

    toBurn = (reward * getReportingBurnRate(s)) / 1 ether;
    toReporter = (reward * getReporterCommission(s)) / 1 ether;
    myReward = reward - toBurn - toReporter;
  }

  function updateUnstakeDetails(
    IStore s,
    address account,
    bytes32 key,
    uint256 incidentDate,
    uint256 originalStake,
    uint256 reward,
    uint256 burned,
    uint256 reporterFee
  ) public {
    // Unstake timestamp of the account
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_UNSTAKE_TS, key, incidentDate, account));
    s.setUintByKey(k, block.timestamp); // solhint-disable-line

    // Last unstake timestamp
    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_UNSTAKE_TS, key, incidentDate));
    s.setUintByKey(k, block.timestamp); // solhint-disable-line

    // ---------------------------------------------------------------------

    // Amount unstaken by the account
    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_UNSTAKEN, key, incidentDate, account));
    s.setUintByKey(k, originalStake);

    // Amount unstaken by everyone
    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_UNSTAKEN, key, incidentDate));
    s.addUintByKey(k, originalStake);

    // ---------------------------------------------------------------------

    if (reward > 0) {
      // Reward received by the account
      k = keccak256(abi.encodePacked(ProtoUtilV1.NS_UNSTAKE_REWARD, key, incidentDate, account));
      s.setUintByKey(k, reward);

      // Total reward received
      k = keccak256(abi.encodePacked(ProtoUtilV1.NS_UNSTAKE_REWARD, key, incidentDate));
      s.addUintByKey(k, reward);
    }

    // ---------------------------------------------------------------------

    if (burned > 0) {
      // Total burned
      k = keccak256(abi.encodePacked(ProtoUtilV1.NS_UNSTAKE_BURNED, key, incidentDate));
      s.addUintByKey(k, burned);
    }

    if (reporterFee > 0) {
      // Total fee paid to the final reporter
      k = keccak256(abi.encodePacked(ProtoUtilV1.NS_UNSTAKE_REPORTER_FEE, key, incidentDate));
      s.addUintByKey(k, reporterFee);
    }
  }

  function getStakesOf(
    IStore s,
    address account,
    bytes32 key,
    uint256 incidentDate
  ) public view returns (uint256 yes, uint256 no) {
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_STAKE_OWNED_NO, key, incidentDate, account));
    no = s.getUintByKey(k);

    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_STAKE_OWNED_YES, key, incidentDate, account));
    yes = s.getUintByKey(k);
  }

  function updateCoverStatus(
    IStore s,
    bytes32 key,
    uint256 incidentDate
  ) public {
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_WITNESS_YES, key, incidentDate));
    uint256 yes = s.getUintByKey(k);

    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_WITNESS_NO, key, incidentDate));
    uint256 no = s.getUintByKey(k);

    if (no > yes) {
      s.setStatus(key, CoverUtilV1.CoverStatus.FalseReporting);
      return;
    }

    s.setStatus(key, CoverUtilV1.CoverStatus.IncidentHappened);
  }

  function addAttestation(
    IStore s,
    bytes32 key,
    address who,
    uint256 incidentDate,
    uint256 stake
  ) external {
    // Add individual stake of the reporter
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_STAKE_OWNED_YES, key, incidentDate, who));
    s.addUintByKey(k, stake);

    // All "incident happened" camp witnesses combined
    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_WITNESS_YES, key, incidentDate));
    uint256 currentStake = s.getUintByKey(k);

    // No has reported yet, this is the first report
    if (currentStake == 0) {
      s.setAddressByKeys(ProtoUtilV1.NS_REPORTING_WITNESS_YES, key, msg.sender);
    }

    s.addUintByKey(k, stake);
    updateCoverStatus(s, key, incidentDate);
  }

  function getAttestation(
    IStore s,
    bytes32 key,
    address who,
    uint256 incidentDate
  ) external view returns (uint256 myStake, uint256 totalStake) {
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_STAKE_OWNED_YES, key, incidentDate, who));
    myStake = s.getUintByKey(k);

    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_WITNESS_YES, key, incidentDate));
    totalStake = s.getUintByKey(k);
  }

  function addDispute(
    IStore s,
    bytes32 key,
    address who,
    uint256 incidentDate,
    uint256 stake
  ) external {
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_STAKE_OWNED_NO, key, incidentDate, who));
    s.addUintByKey(k, stake);

    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_WITNESS_NO, key, incidentDate));
    uint256 currentStake = s.getUintByKey(k);

    if (currentStake == 0) {
      // The first reporter who disputed
      s.setAddressByKeys(ProtoUtilV1.NS_REPORTING_WITNESS_NO, key, msg.sender);
    }

    s.addUintByKey(k, stake);

    updateCoverStatus(s, key, incidentDate);
  }

  function getDispute(
    IStore s,
    bytes32 key,
    address who,
    uint256 incidentDate
  ) external view returns (uint256 myStake, uint256 totalStake) {
    bytes32 k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_STAKE_OWNED_NO, key, incidentDate, who));
    myStake = s.getUintByKey(k);

    k = keccak256(abi.encodePacked(ProtoUtilV1.NS_REPORTING_WITNESS_NO, key, incidentDate));
    totalStake = s.getUintByKey(k);
  }

  function _getLatestIncidentDate(IStore s, bytes32 key) private view returns (uint256) {
    return s.getUintByKeys(ProtoUtilV1.NS_REPORTING_INCIDENT_DATE, key);
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;

interface IStore {
  function setAddress(bytes32 k, address v) external;

  function setAddressBoolean(
    bytes32 k,
    address a,
    bool v
  ) external;

  function setUint(bytes32 k, uint256 v) external;

  function addUint(bytes32 k, uint256 v) external;

  function subtractUint(bytes32 k, uint256 v) external;

  function setUints(bytes32 k, uint256[] memory v) external;

  function setString(bytes32 k, string calldata v) external;

  function setBytes(bytes32 k, bytes calldata v) external;

  function setBool(bytes32 k, bool v) external;

  function setInt(bytes32 k, int256 v) external;

  function setBytes32(bytes32 k, bytes32 v) external;

  function deleteAddress(bytes32 k) external;

  function deleteUint(bytes32 k) external;

  function deleteUints(bytes32 k) external;

  function deleteString(bytes32 k) external;

  function deleteBytes(bytes32 k) external;

  function deleteBool(bytes32 k) external;

  function deleteInt(bytes32 k) external;

  function deleteBytes32(bytes32 k) external;

  function getAddress(bytes32 k) external view returns (address);

  function getAddressBoolean(bytes32 k, address a) external view returns (bool);

  function getUint(bytes32 k) external view returns (uint256);

  function getUints(bytes32 k) external view returns (uint256[] memory);

  function getString(bytes32 k) external view returns (string memory);

  function getBytes(bytes32 k) external view returns (bytes memory);

  function getBool(bytes32 k) external view returns (bool);

  function getInt(bytes32 k) external view returns (int256);

  function getBytes32(bytes32 k) external view returns (bytes32);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;

interface IPausable {
  function paused() external view returns (bool);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

pragma solidity 0.8.0;

interface ICxToken is IERC20 {
  event Finalized(uint256 amount);

  function mint(
    bytes32 key,
    address to,
    uint256 amount
  ) external;

  function burn(uint256 amount) external;

  function expiresOn() external view returns (uint256);

  function coverKey() external view returns (bytes32);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./IMember.sol";

interface IProtocol is IMember {
  event ContractAdded(bytes32 namespace, address contractAddress);
  event ContractUpgraded(bytes32 namespace, address indexed previous, address indexed current);
  event MemberAdded(address member);
  event MemberRemoved(address member);
  event CoverFeeSet(uint256 previous, uint256 current);
  event MinStakeSet(uint256 previous, uint256 current);
  event MinReportingStakeSet(uint256 previous, uint256 current);
  event MinLiquidityPeriodSet(uint256 previous, uint256 current);
  event ReportingBurnRateSet(uint256 previous, uint256 current);
  event ReporterCommissionSet(uint256 previous, uint256 current);
  event ClaimPeriodSet(uint256 previous, uint256 current);

  function addContract(bytes32 namespace, address contractAddress) external;

  function upgradeContract(
    bytes32 namespace,
    address previous,
    address current
  ) external;

  function addMember(address member) external;

  function removeMember(address member) external;
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;

interface IMember {
  /**
   * @dev Version number of this contract
   */
  function version() external pure returns (bytes32);

  /**
   * @dev Name of this contract
   */
  function getName() external pure returns (bytes32);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "./IMember.sol";

interface IPolicy is IMember {
  event CoverPurchased(bytes32 key, address indexed account, address indexed cxToken, uint256 fee, uint256 amountToCover, uint256 expiresOn);

  /**
   * @dev Purchase cover for the specified amount. <br /> <br />
   * When you purchase covers, you recieve equal amount of cxTokens back.
   * You need the cxTokens to claim the cover when resolution occurs.
   * Each unit of cxTokens are fully redeemable at 1:1 ratio to the given
   * stablecoins (like wxDai, DAI, USDC, or BUSD) based on the chain.
   * @param key Enter the cover key you wish to purchase the policy for
   * @param coverDuration Enter the number of months to cover. Accepted values: 1-3.
   * @param amountToCover Enter the amount of the stablecoin `liquidityToken` to cover.
   */
  function purchaseCover(
    bytes32 key,
    uint256 coverDuration,
    uint256 amountToCover
  ) external returns (address);

  /**
   * @dev Gets the cover fee info for the given cover key, duration, and amount
   * @param key Enter the cover key
   * @param coverDuration Enter the number of months to cover. Accepted values: 1-3.
   * @param amountToCover Enter the amount of the stablecoin `liquidityToken` to cover.
   */
  function getCoverFee(
    bytes32 key,
    uint256 coverDuration,
    uint256 amountToCover
  )
    external
    view
    returns (
      uint256 fee,
      uint256 utilizationRatio,
      uint256 totalAvailableLiquidity,
      uint256 coverRatio,
      uint256 floor,
      uint256 ceiling,
      uint256 rate
    );

  /**
   * @dev Returns the values of the given cover key
   * @param _values[0] The total amount in the cover pool
   * @param _values[1] The total commitment amount
   * @param _values[2] The total amount of NPM provision
   * @param _values[3] NPM price
   * @param _values[4] The total amount of reassurance tokens
   * @param _values[5] Reassurance token price
   * @param _values[6] Reassurance pool weight
   */
  function getCoverPoolSummary(bytes32 key) external view returns (uint256[] memory _values);

  function getCxToken(bytes32 key, uint256 coverDuration) external view returns (address cxToken, uint256 expiryDate);

  function getCxTokenByExpiryDate(bytes32 key, uint256 expiryDate) external view returns (address cxToken);

  /**
   * Gets the sum total of cover commitment that haven't expired yet.
   */
  function getCommitment(bytes32 key) external view returns (uint256);

  /**
   * Gets the available liquidity in the pool.
   */
  function getCoverable(bytes32 key) external view returns (uint256);

  /**
   * @dev Gets the expiry date based on cover duration
   * @param today Enter the current timestamp
   * @param coverDuration Enter the number of months to cover. Accepted values: 1-3.
   */
  function getExpiryDate(uint256 today, uint256 coverDuration) external pure returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "./IMember.sol";

interface ICoverStake is IMember {
  event StakeAdded(bytes32 key, uint256 amount);
  event StakeRemoved(bytes32 key, uint256 amount);
  event FeeBurned(bytes32 key, uint256 amount);

  /**
   * @dev Increase the stake of the given cover pool
   * @param key Enter the cover key
   * @param account Enter the account from where the NPM tokens will be transferred
   * @param amount Enter the amount of stake
   * @param fee Enter the fee amount. Note: do not enter the fee if you are directly calling this function.
   */
  function increaseStake(
    bytes32 key,
    address account,
    uint256 amount,
    uint256 fee
  ) external;

  /**
   * @dev Decreases the stake from the given cover pool
   * @param key Enter the cover key
   * @param account Enter the account to decrease the stake of
   * @param amount Enter the amount of stake to decrease
   */
  function decreaseStake(
    bytes32 key,
    address account,
    uint256 amount
  ) external;

  /**
   * @dev Gets the stake of an account for the given cover key
   * @param key Enter the cover key
   * @param account Specify the account to obtain the stake of
   * @return Returns the total stake of the specified account on the given cover key
   */
  function stakeOf(bytes32 key, address account) external view returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "./IMember.sol";

interface IPriceDiscovery is IMember {
  function getTokenPriceInStableCoin(address token, uint256 multiplier) external view returns (uint256);

  function getTokenPriceInLiquidityToken(
    address token,
    address liquidityToken,
    uint256 multiplier
  ) external view returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "./IStore.sol";
import "./IMember.sol";

interface ICxTokenFactory is IMember {
  event CxTokenDeployed(bytes32 indexed key, address cxToken, uint256 expiryDate);

  function deploy(
    IStore s,
    bytes32 key,
    uint256 expiryDate
  ) external returns (address);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "./IMember.sol";

interface ICoverReassurance is IMember {
  event ReassuranceAdded(bytes32 key, uint256 amount);

  /**
   * @dev Adds reassurance to the specified cover contract
   * @param key Enter the cover key
   * @param amount Enter the amount you would like to supply
   */
  function addReassurance(
    bytes32 key,
    address account,
    uint256 amount
  ) external;

  function setWeight(bytes32 key, uint256 weight) external;

  /**
   * @dev Gets the reassurance amount of the specified cover contract
   * @param key Enter the cover key
   */
  function getReassurance(bytes32 key) external view returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "./IReporter.sol";
import "./IWitness.sol";
import "./IMember.sol";

interface IGovernance is IMember, IReporter, IWitness {}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "./IMember.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

interface IVault is IMember, IERC20 {
  event GovernanceTransfer(address indexed to, uint256 amount);
  event PodsIssued(address indexed account, uint256 issued, uint256 liquidityAdded);
  event PodsRedeemed(address indexed account, uint256 redeemed, uint256 liquidityReleased);

  /**
   * @dev Adds liquidity to the specified cover contract
   * @param coverKey Enter the cover key
   * @param account Specify the account on behalf of which the liquidity is being added.
   * @param amount Enter the amount of liquidity token to supply.
   */
  function addLiquidityInternal(
    bytes32 coverKey,
    address account,
    uint256 amount
  ) external;

  /**
   * @dev Adds liquidity to the specified cover contract
   * @param coverKey Enter the cover key
   * @param amount Enter the amount of liquidity token to supply.
   */
  function addLiquidity(bytes32 coverKey, uint256 amount) external;

  /**
   * @dev Removes liquidity from the specified cover contract
   * @param coverKey Enter the cover key
   * @param amount Enter the amount of liquidity token to remove.
   */
  function removeLiquidity(bytes32 coverKey, uint256 amount) external;

  /**
   * @dev Transfers liquidity to governance contract.
   * @param coverKey Enter the cover key
   * @param to Enter the destination account
   * @param amount Enter the amount of liquidity token to transfer.
   */
  function transferGovernance(
    bytes32 coverKey,
    address to,
    uint256 amount
  ) external;
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;
import "./IStore.sol";
import "./IMember.sol";

interface IVaultFactory is IMember {
  event VaultDeployed(bytes32 indexed key, address vault);

  function deploy(IStore s, bytes32 key) external returns (address);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;

interface IReporter {
  event Reported(bytes32 indexed key, address indexed reporter, uint256 incidentDate, bytes32 info, uint256 initialStake);
  event Disputed(bytes32 indexed key, address indexed reporter, uint256 incidentDate, bytes32 info, uint256 initialStake);

  function report(
    bytes32 key,
    bytes32 info,
    uint256 stake
  ) external;

  function dispute(
    bytes32 key,
    uint256 incidentDate,
    bytes32 info,
    uint256 stake
  ) external;

  function getMinStake() external view returns (uint256);

  function getActiveIncidentDate(bytes32 key) external view returns (uint256);

  function getReporter(bytes32 key, uint256 incidentDate) external view returns (address);

  function getResolutionDate(bytes32 key) external view returns (uint256);
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.0;

interface IWitness {
  event Attested(bytes32 indexed key, address indexed witness, uint256 incidentDate, uint256 stake);
  event Refuted(bytes32 indexed key, address indexed witness, uint256 incidentDate, uint256 stake);

  function attest(
    bytes32 key,
    uint256 incidentDate,
    uint256 stake
  ) external;

  function refute(
    bytes32 key,
    uint256 incidentDate,
    uint256 stake
  ) external;

  function getStatus(bytes32 key) external view returns (uint256);

  function getStakes(bytes32 key, uint256 incidentDate) external view returns (uint256, uint256);

  function getStakesOf(
    bytes32 key,
    uint256 incidentDate,
    address account
  ) external view returns (uint256, uint256);
}