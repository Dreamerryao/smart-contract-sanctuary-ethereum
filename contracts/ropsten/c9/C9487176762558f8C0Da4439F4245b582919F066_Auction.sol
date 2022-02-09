pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';

import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '@openzeppelin/contracts/access/Ownable.sol';

contract Auction is ERC1155Holder, Ownable {
    IERC20 public erc20;

    uint256 public constant ONE_TOKEN_IN_WEI = 1e18;
    bytes public constant DEF_DATA = '';

    enum Tier {
        TIER1,
        TIER2,
        TIER3
    }

    enum Protocol {
        ERC1155,
        ERC721
    }

    uint256 public lotsCounter = 0;
    uint256 public betsCounter = 0;

    // TODO do we need to change fee percentage after the deployment?
    uint256 public feeNuminator = 145;
    uint256 public feeDenuminator = 1000;

    address public addressToSendFee;

    Project[] private projects;

    struct Project {
        Protocol protocol;
        uint256[] lotIds;
        address contractAddr;
    }

    struct Bet {
        uint256 lotId;
        uint256 bet;
        uint256 time;
        address better;
    }

    struct Lot {
        uint256 lotId;
        uint256 tokenId;
        uint256 amount;
        uint256 minBet;
        uint256 maxBet;
        uint256 currentMaxBetId;
        uint256 step;
        uint256 start;
        uint256 period;
        Tier[] allowedTiers;
        uint256[] betsIds;
        address owner;
        address contractAddr;
        bool status;
    }

    mapping(address => Tier) public tiers;

    mapping(uint256 => Lot) public lots;
    mapping(address => uint256[]) lotsOnProject;

    mapping(uint256 => Bet) public bets;
    mapping(address => uint256[]) private betsOfAUser;

    event BetCreation(uint256 indexed lotId);

    event Claim(uint256 indexed lotId, uint256 indexed betId);

    constructor(address TOKEN20, address wallet) {
        erc20 = IERC20(TOKEN20);
        addressToSendFee = wallet;

        transferOwnership(msg.sender);
    }

    function placeALot(
        uint256 tokenId,
        uint256 amount,
        uint256 minBet,
        uint256 maxBet,
        uint256 step,
        uint256 period,
        Tier[] calldata allowedTiers,
        address contractAddr
    ) external onlyOwner {
        IERC1155 erc1155 = IERC1155(contractAddr);

        require(
            erc1155.balanceOf(msg.sender, tokenId) >= amount,
            "You don't have enough tokens"
        );
        require(amount > 0, 'Amount must be greater than zero');

        erc1155.safeTransferFrom(msg.sender, address(this), tokenId, amount, DEF_DATA);

        _createLot(
            tokenId,
            amount,
            minBet,
            maxBet,
            step,
            period,
            allowedTiers,
            contractAddr
        );

        lotsOnProject[contractAddr].push(lotsCounter);
    }

    function createProject(Protocol protocol, address contractAddr) external onlyOwner {
        uint256[] memory lotIds;

        Project memory project = Project({
            protocol: protocol,
            lotIds: lotIds,
            contractAddr: contractAddr
        });

        projects.push(project);
    }

    function makeABet(uint256 lotId, uint256 betValue) external {
        require(
            erc20.balanceOf(msg.sender) >= bets[lots[lotId].currentMaxBetId].bet,
            "You don't have enough money to make a lot"
        );
        require(
            betValue - bets[lots[lotId].currentMaxBetId].bet > lots[lotId].step,
            'Your bet is lower than the last bet + minimal step'
        );
        require(
            block.timestamp - lots[lotId].start <= lots[lotId].period,
            'The Lot has been selled'
        );
        require(
            bets[lots[lotId].currentMaxBetId].bet < betValue,
            'Current higest Bet is higher than yours'
        );
        require(
            lots[lotId].maxBet >= betValue,
            'You are trying to make a Bet higher than max Bet'
        );
        require(
            tiers[msg.sender] == lots[lotId].allowedTiers[0] ||
                tiers[msg.sender] == lots[lotId].allowedTiers[1] ||
                tiers[msg.sender] == lots[lotId].allowedTiers[2],
            "You're not in the required tier"
        );

        erc20.transferFrom(msg.sender, address(this), betValue);

        if (betValue < lots[lotId].maxBet && lots[lotId].betsIds.length > 1) {
            erc20.transfer(
                bets[lots[lotId].currentMaxBetId].better,
                bets[lots[lotId].currentMaxBetId].bet
            );
        } else if (betValue == lots[lotId].maxBet) {
            erc20.transfer(
                msg.sender,
                (lots[lotId].maxBet - _calculateFee(lots[lotId].maxBet))
            );

            IERC1155 erc1155 = IERC1155(lots[lotId].contractAddr);

            erc20.transfer(addressToSendFee, _calculateFee(lots[lotId].maxBet));
            erc1155.safeTransferFrom(
                address(this),
                msg.sender,
                lots[lotId].tokenId,
                lots[lotId].amount,
                DEF_DATA
            );
        }

        betsCounter += 1;
        lots[lotId].currentMaxBetId = betsCounter;
        lots[lotId].betsIds.push(betsCounter);

        bets[betsCounter] = Bet({
            lotId: lotId,
            bet: betValue,
            time: block.timestamp,
            better: msg.sender
        });

        betsOfAUser[msg.sender].push(betsCounter);

        emit BetCreation(lotId);
    }

    function claim(uint256 lotId, uint256 betId) external {
        require(
            block.timestamp - lots[lotId].start > lots[lotId].period,
            'Auction not finished yet'
        );
        require(
            bets[lots[lotId].currentMaxBetId].bet == bets[betId].bet,
            "Your Bet isn't last"
        );
        require(bets[betId].better == msg.sender, 'You are not the owner of the Bet');

        require(lots[lotId].status, "You've already claimed the tokens");

        IERC1155 erc1155 = IERC1155(lots[lotId].contractAddr);

        if (bets[betId].better == lots[lotId].owner) {
            erc1155.safeTransferFrom(
                address(this),
                msg.sender,
                lots[lotId].tokenId,
                lots[lotId].amount,
                DEF_DATA
            );
        } else {
            //TODO Needs logic update?
            erc1155.safeTransferFrom(
                address(this),
                msg.sender,
                lots[lotId].tokenId,
                lots[lotId].amount,
                DEF_DATA
            );
            erc20.transfer(
                lots[lotId].owner,
                bets[lots[lotId].currentMaxBetId].bet - _calculateFee(bets[betId].bet)
            );
            erc20.transfer(addressToSendFee, _calculateFee(bets[betId].bet));
        }

        lots[lotId].status = false;

        emit Claim(lotId, betId);
    }

    function addUserToTier(address user, Tier tier) external onlyOwner {
        tiers[user] = tier;
    }

    function _createLot(
        uint256 tokenId,
        uint256 amount,
        uint256 minBet,
        uint256 maxBet,
        uint256 step,
        uint256 period,
        Tier[] calldata allowedTiers,
        address contractAddr
    ) internal {
        lotsCounter += 1;
        betsCounter += 1;

        uint256[] memory betsIds;

        lots[lotsCounter] = Lot({
            lotId: lotsCounter,
            tokenId: tokenId,
            amount: amount,
            minBet: minBet,
            maxBet: maxBet,
            currentMaxBetId: betsCounter,
            start: block.timestamp,
            step: step,
            period: period,
            allowedTiers: allowedTiers,
            betsIds: betsIds,
            owner: msg.sender,
            contractAddr: contractAddr,
            status: true
        });

        lots[lotsCounter].betsIds.push(betsCounter);

        bets[betsCounter] = Bet({
            lotId: lotsCounter,
            bet: minBet,
            time: block.timestamp,
            better: msg.sender
        });
    }

    function _calculateFee(uint256 bet) internal view returns (uint256 fee) {
        fee = (bet * feeNuminator) / feeDenuminator;
    }

    function getAllProjects() external view returns (Project[] memory projects_) {
        projects_ = new Project[](projects.length);

        for (uint256 i = 0; i < projects.length; i++) {
            projects_[i] = projects[i];
        }
    }

    function getAllLots() external view returns (Lot[] memory lots_) {
        lots_ = new Lot[](lotsCounter);

        for (uint256 i = 0; i < lotsCounter; i++) {
            lots_[i] = lots[i];
        }
    }

    function getAllBetsForALot(uint256 lotId)
        external
        view
        returns (Bet[] memory bets_, uint256[] memory ids)
    {
        ids = lots[lotId].betsIds;
        bets_ = new Bet[]((lots[lotId].betsIds).length);

        for (uint256 i = 0; i < (lots[lotId].betsIds).length; i++) {
            bets_[i] = bets[i];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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