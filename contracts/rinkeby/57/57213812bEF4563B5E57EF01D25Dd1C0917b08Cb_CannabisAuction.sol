// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC20 {
    function mint(address to, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
    function balanceOf(address account) external returns(uint256);
    function approve(address spender, uint256 amount) external returns(bool);
    function allowance(address owner, address spender) external returns(uint256);
}
interface IERC721 {
    function balanceOf(address owner) external returns(uint256);
    function ownerOf(uint256 tokenId) external returns(address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function isApprovedForAll(address account, address operator) external returns(bool);
    function supportsInterface(bytes4 interfaceId) external returns(bool);
}
contract CannabisAuction is AccessControl {
    using Counters for Counters.Counter;

    Counters.Counter private _auctionIdCounter;
    IERC20 ERC20;
    address public _wallet;
    address public _setterAddress;
    bytes4 public constant ERC721InterfaceId = 0x80ac58cd;
    enum STATUS_TYPE {
        BIDDING,
        WAIT_WINNER,
        WINNER_ACCEPT,
        WINNER_CANCEL,
        CLOSE_AUCTION,
        SOLD
    }
    bytes32 public constant ACTIVE_SETTER_ROLE = keccak256("ACTIVE_SETTER_ROLE");
    uint256 public fee;
    uint256 public rateFee;
    struct Item {
        address _item;
        address _owner;
        address _lockedBuyer;
        address _buyer;
        uint256 _tokenId;
        uint256 _price;
        uint256 _expiration;
        uint256 _acceptTime;
        uint256 _auctionId;
        uint256 _terminatePrice;
        bool _available;
        STATUS_TYPE _status;
    }
    struct Bid {
        address _buyer;
        uint256 _price;
        uint256 _time;
        uint256 bidId;
        bool _isAccept;
        bool _active;
        bool _cancel;
    }
    Item[] items;
    mapping (uint256 => Bid[]) bidders;
    modifier onlyExistItem(uint256 auctionId) {
        (bool found, Item memory itemData) = _getItemInfo(auctionId);
        require(found, "Item is not exist");
        require(itemData._available, "Item is not available");
        require(itemData._expiration >= block.timestamp, "This item has expired");
        _;
    }
    modifier onlyItemOwner(uint256 auctionId) {
        (bool found, Item memory itemData) = _getItemInfo(auctionId);
        require(found, "Not found token");
        bool isERC721 = IERC721(itemData._item).supportsInterface(ERC721InterfaceId);
        require(
            isERC721 && IERC721(itemData._item).ownerOf(itemData._tokenId) == itemData._owner
            , "You are not owned this token."
        );
        _;
    }
    modifier uniqueItem(address item, uint256 tokenId) {
        for(uint256 i = 0; i < items.length; i++){
            if(
                items[i]._item == item &&
                items[i]._tokenId == tokenId &&
                items[i]._available &&
                items[i]._owner == msg.sender && 
                items[i]._status == STATUS_TYPE.BIDDING
            ) revert("This item is already created");
        }
        _;
    }
    function _getItemInfo(uint256 auctionId) public view returns(bool, Item memory) {
        if(auctionId > items.length) return (false, Item(address(0), address(0), address(0), address(0), 0, 0, 0, 0, 0, 0, false, STATUS_TYPE.CLOSE_AUCTION));
        return (true, items[auctionId]);
    }
    constructor(address token){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ACTIVE_SETTER_ROLE, msg.sender);
        fee = 1000000 wei;
        rateFee = 5;
        _wallet = msg.sender;
        _setterAddress = msg.sender;
        ERC20 = IERC20(token);
    }
    function placeAuction(
        address item,
        uint256 tokenId,
        uint256 startPrice,
        uint256 expiration,
        uint256 terminatePrice
    ) public uniqueItem(item, tokenId){
        require(IERC721(item).ownerOf(tokenId) == msg.sender, "You didn't own this item (ERC721)");
        require(IERC721(item).isApprovedForAll(msg.sender, address(this)), "Items is not approve");
        require(startPrice > 0, "Price must greater than zero");
        require(expiration > block.timestamp, "Incorrect expiraion");
        uint256 auctionId = _auctionIdCounter.current();
        _auctionIdCounter.increment();
        items.push(
            Item(
                item,
                msg.sender,
                address(0),
                address(0),
                tokenId,
                startPrice,
                expiration,
                0,
                auctionId,
                terminatePrice,
                true,
                STATUS_TYPE.BIDDING
            )
        );
        bidders[auctionId].push(
            Bid(
                msg.sender,
                startPrice,
                block.timestamp,
                bidders[auctionId].length,
                false,
                true,
                false
            )
        );
    }
    function buyAuction(uint256 auctionId) public onlyExistItem(auctionId) returns (bool, Item memory){
        (, Item memory itemData) = _getItemInfo(auctionId);
        require(msg.sender != itemData._owner, "You already owned this item");
        require(itemData._lockedBuyer == address(0), "This item is not available for buy");
        require(itemData._terminatePrice > 0, "This item available for bidding");
        require(itemData._terminatePrice <= ERC20.balanceOf(msg.sender), "Balance is not enough");
        // tranfer ERC20 to seller
        ERC20.transferFrom(msg.sender, itemData._owner, itemData._terminatePrice - itemData._terminatePrice * rateFee / 100);
        // tranfer fee to admin
        ERC20.transferFrom(msg.sender, _wallet, itemData._terminatePrice * rateFee / 100);
        IERC721(itemData._item).safeTransferFrom(
            itemData._owner, 
            msg.sender, 
            itemData._tokenId
        );
        items[auctionId]._available = false;
        items[auctionId]._lockedBuyer = msg.sender;
        items[auctionId]._buyer = msg.sender;
        items[auctionId]._acceptTime = block.timestamp;
        items[auctionId]._status = STATUS_TYPE.SOLD;
        return (true, itemData);
    }
    function getAllAuction() public view returns(Item[] memory){
        return items;
    }
    function _getBidWinner(uint256 auctionId) internal view returns(Bid memory) {
        for(uint256 i = bidders[auctionId].length - 1; i >= 0; i--){
            if(bidders[auctionId][i]._active && bidders[auctionId][i]._cancel == false) return bidders[auctionId][i];
        }
        return Bid(address(0), 0, 0, 0, false, false, false);
    }
    function getAllBids(uint256 auctionId) public view returns (Bid[] memory){
        return bidders[auctionId];
    }
    function cancelAuction(uint256 auctionId) public onlyItemOwner(auctionId){
        (, Item memory itemData)= _getItemInfo(auctionId);
        require(ERC20.balanceOf(msg.sender) >= fee, "Balance is not enough to cancel");
        require(msg.sender == itemData._owner, "You can't cancel this auction");
        ERC20.transferFrom(msg.sender, _wallet, fee);
        items[auctionId]._available = false;
        items[auctionId]._status = STATUS_TYPE.CLOSE_AUCTION;
    }
    function cancelBid(uint256 auctionId, uint256 offerId) public onlyExistItem(auctionId){
        require(bidders[auctionId][offerId]._buyer == msg.sender, "You can't cancle this bid");
        require(ERC20.balanceOf(msg.sender) >= fee, "Balance is not enough to pay fee");
        ERC20.transferFrom(msg.sender, _wallet, fee);
        bidders[auctionId][offerId]._active = false;
        bidders[auctionId][offerId]._cancel = true;
    }
    function closeBid(uint256 auctionId) public onlyItemOwner(auctionId) onlyExistItem(auctionId){
        (, Item memory itemData) = _getItemInfo(auctionId);
        require(itemData._lockedBuyer == address(0), "The auction has been closed");
        require(bidders[auctionId].length > 0, "No winner found");
        require(msg.sender == itemData._owner || msg.sender == _setterAddress, "You can't close this auction");
         Bid memory winner = _getBidWinner(auctionId);
        require(winner._buyer != address(0), "Not found winner");
        require(items[auctionId]._status == STATUS_TYPE.BIDDING, "Can't close this bid");
        require(winner._buyer != itemData._owner, "You already owned this item");
        items[auctionId]._acceptTime = items[auctionId]._expiration + 1 days;
        items[auctionId]._lockedBuyer = winner._buyer;
        if(bidders[auctionId].length == 1){
            items[auctionId]._status = STATUS_TYPE.CLOSE_AUCTION;
        } else {
            items[auctionId]._status = STATUS_TYPE.WAIT_WINNER;
        }
    }
    function winnnerAcceptBid(uint256 auctionId) public returns(bool, uint256){
        uint bidIndex = bidders[auctionId].length - 1;
        require(items.length > auctionId, "Item not found");
        require(items[auctionId]._acceptTime >= block.timestamp, "Out of accept time");
        require(bidders[auctionId][bidIndex]._buyer == msg.sender, "You can't accept this bid");
        require(ERC20.balanceOf(msg.sender) >= bidders[auctionId][bidIndex]._price, "Balance winnner is not enough");
        require(items[auctionId]._status == STATUS_TYPE.WAIT_WINNER, "Auction status must be wait winner accept, You can't accept this bid");
        (, Item memory itemData) = _getItemInfo(auctionId);
        require(IERC721(itemData._item).ownerOf(itemData._tokenId) == itemData._owner, "Item is not available");
        IERC721(itemData._item).safeTransferFrom(itemData._owner, msg.sender, itemData._tokenId);

        ERC20.transferFrom(msg.sender, itemData._owner, itemData._price - itemData._price * rateFee / 100);
        ERC20.transferFrom(msg.sender, itemData._owner, itemData._price * rateFee / 100);
        bidders[auctionId][bidIndex]._isAccept = true;
        bidders[auctionId][bidIndex]._active = false;
        items[auctionId]._available = false;
        items[auctionId]._lockedBuyer = msg.sender;
        items[auctionId]._status = STATUS_TYPE.WINNER_ACCEPT;
        return (true, itemData._auctionId);
    }
    function winnerCancelBid(uint256 auctionId) public onlyExistItem(auctionId) returns(bool){
        (, Item memory itemData) = _getItemInfo(auctionId);
        require(itemData._lockedBuyer == msg.sender, "You are not winner");
        require(items[auctionId]._status == STATUS_TYPE.WAIT_WINNER, "Auction status must be wait winner");
        require(items[auctionId]._available, "Item is not available");
        for(uint256 i = 0; i < bidders[auctionId].length; i++){
            if(bidders[auctionId][i]._active) {
                bidders[auctionId][i]._cancel = true;
                bidders[auctionId][i]._active = false;
                items[auctionId]._acceptTime = items[auctionId]._acceptTime + 1 hours;
                items[auctionId]._status = STATUS_TYPE.WINNER_CANCEL;
                items[auctionId]._available = false;
                return true;
            }
        }
        return false;
    }
    function bidItem(uint256 auctionId, uint256 bidPrice) public onlyExistItem(auctionId){
        (, Item memory itemData) = _getItemInfo(auctionId);
        require(itemData._lockedBuyer == address(0), "This item is not available for auction");
        require(bidders[auctionId][bidders[auctionId].length - 1]._price < bidPrice, "The auction price must be greater than the latest price");
        require(msg.sender != itemData._owner, "You can't bid this auction");
        require(items[auctionId]._available, "Auction is not available");
        require(items[auctionId]._status == STATUS_TYPE.BIDDING, "Can't bid this auction");
        items[auctionId]._price = bidPrice;
        bidders[auctionId].push(
            Bid(
                msg.sender,
                bidPrice,
                block.timestamp,
                bidders[auctionId].length,
                false,
                true,
                false
            )
        );
    }
    function setAdminWallet(address wallet) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _wallet = wallet;
    }
    function getMarketId(address item, address owner, uint256 tokenId, bool isAvailable) public view returns(bool, uint256){
        for(uint i = 0; i < items.length; i++){
            if(
                items[i]._available == isAvailable && 
                items[i]._owner == owner && 
                items[i]._tokenId == tokenId && 
                items[i]._item == item
            ){
                return (true, items[i]._auctionId);
            }
        }
        return (false, 0);
    }
    function setAvailable(uint256 auctionId) public onlyExistItem(auctionId) onlyRole(ACTIVE_SETTER_ROLE){
        items[auctionId]._available = false;
        items[auctionId]._status = STATUS_TYPE.CLOSE_AUCTION;
    }
    function setFee(uint256 _fee, uint256 _rateFee) public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool){
        require(_rateFee < 100, "Rate fee is incorrect");
        fee = _fee;
        rateFee =  _rateFee;
        return true;
    }
    function setSetterAddress(address setter) public onlyRole(DEFAULT_ADMIN_ROLE){
        _setterAddress = setter;
    }
    function setActiveRole(address adds) public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool){
        _grantRole(ACTIVE_SETTER_ROLE, adds);
        return true;
    }
    function isWinnerAccept(uint256 auctionId) public view returns(bool, address winner){
        uint256 bidIndex = bidders[auctionId].length - 1 ;
        return (bidders[auctionId][bidIndex]._isAccept, bidders[auctionId][bidIndex]._buyer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}