// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract ApesMarket is ReentrancyGuard, Pausable, Ownable {

    IERC721 apesContract;     // instance of the Apes contract

    struct Offer {
        bool isForSale;
        uint id;
        address seller;
        uint minValue;          // in ether
        address onlySellTo;
    }

    struct Bid {
        uint id;
        address bidder;
        uint value;
    }

    // Admin Fee
    uint public adminPercent = 2;
    uint public adminPending;

    // A record of apess that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping (uint => Offer) public offers;

    // A record of the highest apes bid
    mapping (uint => Bid) public bids;

    event Offered(uint indexed id, uint minValue, address indexed toAddress);
    event BidEntered(uint indexed id, uint value, address indexed fromAddress);
    event BidWithdrawn(uint indexed id, uint value);
    event Bought(uint indexed id, uint value, address indexed fromAddress, address indexed toAddress, bool isInstant);
    event Cancelled(uint indexed id);

    /* Initializes contract with an instance of 0xApes contract, and sets deployer as owner */
    constructor(address initialAddress) {
        IERC721(initialAddress).balanceOf(address(this));
        apesContract = IERC721(initialAddress);
    }

    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    /* Returns the 0xApes contract address currently being used */
    function apessAddress() external view returns (address) {
        return address(apesContract);
    }

    /* Allows the owner of the contract to set a new 0xApes contract address */
    function setApesContract(address newAddress) external onlyOwner {
        require(newAddress != address(0x0), "zero address");
        apesContract = IERC721(newAddress);
    }

    /* Allows the owner of the contract to set a new Admin Fee Percentage */
    function setAdminPercent(uint _percent) external onlyOwner {
        require(_percent >= 0 && _percent < 50, "invalid percent");
        adminPercent = _percent;
    }

    /*Allows the owner of the contract to withdraw pending ETH */
    function withdraw() external onlyOwner nonReentrant() {
        uint amount = adminPending;
        adminPending = 0;
        _safeTransferETH(msg.sender, amount);
    }

    /* Allows the owner of a 0xApes to stop offering it for sale */
    function cancelForSale(uint id) external onlyApesOwner(id) {
        offers[id] = Offer(false, id, msg.sender, 0, address(0x0));
        emit Cancelled(id);
    }

    /* Allows a 0xApes owner to offer it for sale */
    function offerForSale(uint id, uint minSalePrice) external onlyApesOwner(id) whenNotPaused {
        offers[id] = Offer(true, id, msg.sender, minSalePrice, address(0x0));
        emit Offered(id, minSalePrice, address(0x0));
    }

    /* Allows a 0xApes owner to offer it for sale to a specific address */
    function offerForSaleToAddress(uint id, uint minSalePrice, address toAddress) external onlyApesOwner(id) whenNotPaused {
        offers[id] = Offer(true, id, msg.sender, minSalePrice, toAddress);
        emit Offered(id, minSalePrice, toAddress);
    }
    

    /* Allows users to buy a 0xApes offered for sale */
    function buyApes(uint id) payable external whenNotPaused nonReentrant() {
        Offer memory offer = offers[id];
        uint amount = msg.value;
        require (offer.isForSale, 'ape is not for sale'); 
        require (offer.onlySellTo == address(0x0) || offer.onlySellTo != msg.sender, "this offer is not for you");                
        require (amount == offer.minValue, 'not enough ether'); 
        address seller = offer.seller;
        require (seller != msg.sender, 'seller == msg.sender');
        require (seller == apesContract.ownerOf(id), 'seller no longer owner of apes');

        offers[id] = Offer(false, id, msg.sender, 0, address(0x0));
        
        // Transfer 0xApes to msg.sender from seller.
        apesContract.safeTransferFrom(seller, msg.sender, id);
        
        // Transfer ETH to seller!
        uint commission = 0;
        if(adminPercent > 0) {
            commission = amount * adminPercent / 100;
            adminPending += commission;
        }

        _safeTransferETH(seller, amount - commission);
        
        emit Bought(id, amount, seller, msg.sender, true);

        // refund bid if new owner is buyer!
        Bid memory bid = bids[id];
        if (bid.bidder == msg.sender) {
            _safeTransferETH(bid.bidder, bid.value); 
            bids[id] = Bid(id, address(0x0), 0);
        }
    }

    /* Allows users to enter bids for any 0xApes */
    function placeBid(uint id) payable external whenNotPaused nonReentrant() {
        require (apesContract.ownerOf(id) != msg.sender, 'you already own this apes');
        require (msg.value != 0, 'cannot enter bid of zero');
        Bid memory existing = bids[id];
        require (msg.value > existing.value, 'your bid is too low');
        if (existing.value > 0) {
            // Refund existing bid
            _safeTransferETH(existing.bidder, existing.value); 
        }
        bids[id] = Bid(id, msg.sender, msg.value);
        emit BidEntered(id, msg.value, msg.sender);
    }

    /* Allows 0xApes owners to accept bids for their Apes */
    function acceptBid(uint id, uint minPrice) external onlyApesOwner(id) whenNotPaused nonReentrant() {
        address seller = msg.sender;
        Bid memory bid = bids[id];
        uint amount = bid.value;
        require (amount != 0, 'cannot enter bid of zero');
        require (amount >= minPrice, 'your bid is too low');

        address bidder = bid.bidder;
        require (seller != bidder, 'you already own this token');
        offers[id] = Offer(false, id, bidder, 0, address(0x0));
        bids[id] = Bid(id, address(0x0), 0);
 
        // Transfer 0xApe to  Bidder
        apesContract.safeTransferFrom(msg.sender, bidder, id);

        // Transfer ETH to seller!
        uint commission = 0;
        if(adminPercent > 0) {
            commission = amount * adminPercent / 100;
            adminPending += commission;
        }

        _safeTransferETH(seller, amount - commission);
       
        emit Bought(id, bid.value, seller, bidder, false);
    }

    /* Allows bidders to withdraw their bids */
    function withdrawBid(uint id) external nonReentrant() {
        Bid memory bid = bids[id];
        require(bid.bidder == msg.sender, 'the bidder is not msg sender');
        uint amount = bid.value;
        emit BidWithdrawn(id, amount);
        bids[id] = Bid(id, address(0x0), 0);
        _safeTransferETH(msg.sender, amount);
    }

    receive() external payable {}

    function _safeTransferETH(address to, uint256 value) internal returns(bool) {
		(bool success, ) = to.call{value: value}(new bytes(0));
		return success;
    }

    modifier onlyApesOwner(uint256 tokenId) {
        require(apesContract.ownerOf(tokenId) == msg.sender, "only for apes owner");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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