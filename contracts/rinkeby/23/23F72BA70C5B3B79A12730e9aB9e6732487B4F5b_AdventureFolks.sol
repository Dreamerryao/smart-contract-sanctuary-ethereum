/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT




interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {

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


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


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


abstract contract ReentrancyGuard {
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


interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}


library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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


abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}


interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}


contract AdventureFolks is ERC721Enumerable, ReentrancyGuard, Ownable {

    string[] private adjectives = [
        "adventurous",
        "aggressive",
        "ambitious",
        "angry",
        "annoyed",
        "annoying",
        "arrogant",
        "articulate",
        "athletic",
        "awkward",
        "beautiful",
        "bored",
        "bossy",
        "brainy",
        "brave",
        "bumbling",
        "busy",
        "calm",
        "careless",
        "caring",
        "cautious",
        "cheerful",
        "clumsy",
        "compassionate",
        "conceited",
        "confident",
        "confused",
        "considerate",
        "crazy",
        "curious",
        "cursed",
        "cute",
        "cynical",
        "dainty",
        "daring",
        "defiant",
        "demanding",
        "depressed",
        "determined",
        "devout",
        "disagreeable",
        "disappointed",
        "disbelieving",
        "disgruntled",
        "disgusted",
        "eager",
        "ecstatic",
        "embarrassed",
        "energetic",
        "enraged",
        "evil",
        "excited",
        "exhausted",
        "expert",
        "faithful",
        "fancy",
        "friendly",
        "frightened",
        "frustrated",
        "fun-loving",
        "funny",
        "geeky",
        "generous",
        "gentle",
        "giving",
        "gorgeous",
        "grieving",
        "grouchy",
        "guilty",
        "handsome",
        "happy",
        "helpful",
        "heroic",
        "honest",
        "hopeful",
        "horrified",
        "humble",
        "hungover",
        "hurt",
        "idiotic",
        "impulsive",
        "indifferent",
        "innocent",
        "intelligent",
        "inventive",
        "jealous",
        "joyful",
        "judgmental",
        "kind",
        "knowledgeable",
        "lazy",
        "light-hearted",
        "likeable",
        "lively",
        "lonely",
        "lovable",
        "lovesick",
        "loving",
        "loyal",
        "mad",
        "manipulative",
        "materialistic",
        "mediative",
        "melancholy",
        "merry",
        "messy",
        "mighty",
        "mischievous",
        "miserable",
        "mysterious",
        "naive",
        "nasty",
        "neat",
        "nervous",
        "neurotic",
        "nice",
        "noisy",
        "obnoxious",
        "opinionated",
        "optimistic",
        "ordinary",
        "organized",
        "outgoing",
        "paranoid",
        "patriotic",
        "persecuted",
        "personable",
        "pitiful",
        "pleasant",
        "poor",
        "popular",
        "pretty",
        "prim",
        "proud",
        "punctual",
        "puzzled",
        "questioning",
        "quiet",
        "radical",
        "realistic",
        "rebellious",
        "relaxed",
        "reliable",
        "religious",
        "reserved",
        "respectful",
        "responsible",
        "rich",
        "rude",
        "sad",
        "sarcastic",
        "self-conscious",
        "selfish",
        "sensitive",
        "serious",
        "sheepish",
        "shocked",
        "short",
        "shy",
        "silly",
        "simple-minded",
        "sinister",
        "smart",
        "smug",
        "spooky",
        "strange",
        "strong",
        "stubborn",
        "stupid",
        "successful",
        "surprised",
        "suspicious",
        "talkative",
        "tall",
        "thoughtful",
        "timid",
        "tiny",
        "tolerant",
        "tough",
        "tricky",
        "trusting",
        "ugly",
        "understanding",
        "unhappy",
        "unlucky",
        "untamed",
        "vain",
        "warm",
        "wild",
        "willing",
        "wise",
        "witty",
        "wonderful"
    ];

    string[] private job = [
        "academic",
        "accountant",
        "acrobat",
        "actor",
        "adventurer",
        "aerialist",
        "alchemist",
        "animal trainer",
        "anthropologist",
        "apothecary",
        "arborist",
        "archaeologist",
        "archer",
        "architect",
        "archivist",
        "archmage",
        "aristocrat",
        "armorer",
        "assassin",
        "astrologer",
        "astronomer",
        "athlete",
        "baker",
        "bandit",
        "banker",
        "barber",
        "bard",
        "barmaid",
        "bartender",
        "beekeeper",
        "beggar",
        "birdcatcher",
        "blacksmith",
        "bodyguard",
        "bookbinder",
        "bookkeeper",
        "botanist",
        "bottle maker",
        "bouncer",
        "bounty hunter",
        "brewer",
        "burglar",
        "butcher",
        "butler",
        "candlemaker",
        "carpenter",
        "cartographer",
        "cavalryman",
        "celebrity",
        "charioteer",
        "charlatan",
        "chemist",
        "chimney sweep",
        "clerk",
        "clown",
        "cobbler",
        "coinsmith",
        "collector",
        "comedian",
        "con artist",
        "conductor",
        "constable",
        "contortionist",
        "contractor",
        "cook",
        "cooper",
        "courier",
        "crime boss",
        "cult leader",
        "cultist",
        "cutler",
        "cutpurse",
        "dairymaid",
        "dancer",
        "debt collector",
        "detective",
        "diplomat",
        "disgraced noble",
        "distiller",
        "doctor",
        "drug dealer",
        "drug lord",
        "drummer",
        "drunkard",
        "duelist",
        "dungeon delver",
        "embroiderer",
        "engineer",
        "engraver",
        "executioner",
        "exorcist",
        "explorer",
        "exterminator",
        "falconer",
        "farmer",
        "fashion designer",
        "ferryman",
        "firefighter",
        "first mate",
        "fisher",
        "fishmonger",
        "fletcher",
        "florist",
        "forger",
        "fortune teller",
        "fugitive",
        "furrier",
        "gambler",
        "gardener",
        "gladiator",
        "goldsmith",
        "grave robber",
        "gravedigger",
        "grocer",
        "groundskeeper",
        "guard",
        "guide",
        "guild master",
        "healer",
        "herbalist",
        "hermit",
        "high priest",
        "historian",
        "horse trainer",
        "housemaid",
        "housewife",
        "hunter",
        "illuminator",
        "illusionist",
        "innkeeper",
        "inquisitor",
        "instrument maker",
        "jailer",
        "jester",
        "jeweler",
        "judge",
        "juggler",
        "kidnapper",
        "kitchen drudge",
        "knight",
        "laborer",
        "lamplighter",
        "landlord",
        "landscaper",
        "laundry worker",
        "lawman",
        "leatherworker",
        "librarian",
        "lieutenant",
        "loan shark",
        "locksmith",
        "longshoreman",
        "lookout",
        "lumberjack",
        "maid",
        "mason",
        "master-of-hounds",
        "mathematician",
        "medic",
        "mercenary",
        "merchant",
        "messenger",
        "miner",
        "minister",
        "model",
        "moneylender",
        "monk",
        "monster hunter",
        "mortician",
        "musician",
        "nanny",
        "navigator",
        "necromancer",
        "noble",
        "nun",
        "nurse",
        "oracle",
        "outlaw",
        "painter",
        "paladin",
        "peddler",
        "philosopher",
        "pimp",
        "piper",
        "pirate",
        "playwright",
        "plumber",
        "poacher",
        "poet",
        "potter",
        "priest",
        "prince",
        "princess",
        "printer",
        "prisoner",
        "professor",
        "prophet",
        "prospector",
        "prostitute",
        "ranger",
        "rat catcher",
        "refugee",
        "ringmaster",
        "roofer",
        "rope-maker",
        "ropewalker",
        "royal guard",
        "rugmaker",
        "runaway slave",
        "sailor",
        "scholar",
        "scout",
        "scribe",
        "sculptor",
        "sea captain",
        "sergeant",
        "servant",
        "shaman",
        "shepherd",
        "sheriff",
        "shipwright",
        "singer",
        "slave",
        "slave driver",
        "smuggler",
        "soapmaker",
        "soldier",
        "spy",
        "spymaster",
        "squatter",
        "squire",
        "stable hand",
        "stage magician",
        "street musician",
        "street vendor",
        "student",
        "tailor",
        "tattooist",
        "tavern worker",
        "tax collector",
        "taxidermist",
        "teacher",
        "thatcher",
        "thief",
        "thug",
        "torturer",
        "town crier",
        "town guard",
        "toymaker",
        "trader",
        "trapper",
        "treasure hunter",
        "tutor",
        "vagabond",
        "vendor",
        "veterinarian",
        "vintner",
        "wanderer",
        "warden",
        "washerwoman",
        "watchmaker",
        "weaver",
        "wet nurse",
        "wheelwright",
        "witch",
        "witchdoctor",
        "writer"
    ];
    
    string[] private motivation = [
        "assassinate",
        "atone",
        "avenge",
        "be admired",
        "be adored",
        "be entertained",
        "be famous",
        "be noticed",
        "be popular",
        "be powerful",
        "be recognized",
        "be remembered",
        "be respected",
        "be reunited",
        "be rich",
        "become immortal",
        "become the ruler",
        "befriend someone",
        "belong",
        "blackmail someone",
        "break an addiction",
        "challenge you to a duel",
        "change their life",
        "clear their name",
        "cook you dinner",
        "cure a disease",
        "defeat someone",
        "destroy something",
        "discover",
        "eliminate corruption",
        "entertain",
        "escape",
        "explore the world",
        "fall in love",
        "find a home",
        "find a job",
        "find a person",
        "find a purpose",
        "find an item",
        "find inspiration",
        "find the killer",
        "find treasure",
        "fit in",
        "frame someone",
        "get a pet",
        "get away",
        "get married",
        "get vengeance",
        "have children",
        "have sex",
        "hide",
        "humiliate someone",
        "hunt for dinner",
        "hunt for mushrooms",
        "invent",
        "join",
        "keep their family safe",
        "kidnap someone",
        "kill",
        "kiss you",
        "lear how to fight",
        "learn",
        "learn magic",
        "lift a curse",
        "make art",
        "make money",
        "make others happy",
        "offer you a mission",
        "open a business",
        "protect someone",
        "protect the innocent",
        "protect their business",
        "protect their home",
        "prove a theory",
        "raise a family",
        "reconcile",
        "retrieve a stolen item",
        "rob you",
        "sail around the world",
        "save someone",
        "seduce someone",
        "sell you a treasure map",
        "set a building on fire",
        "solve a mystery",
        "spread an ideology",
        "steal",
        "stop criminals",
        "teach",
        "tell you a secret",
        "tell you a story",
        "travel",
        "win a contest",
        "win a game",
        "win approval",
        "write"
    ];

    string[] private suffixes = ["a", "b"];
    
    string[] private namePrefixes = ["a", "b"];
    
    string[] private nameSuffixes = ["a", "b"];
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function getAdj1(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ADJ1", adjectives);
    }

    function getAdj2(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ADJ2", adjectives);
    }

    function getAdj3(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ADJ3", adjectives);
    }
    
    function getAdj4(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ADJ4", adjectives);
    }
    
    function getAdj5(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "ADJ5", adjectives);
    }
    
    function getJob1(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "JOB1", job);
    }
    
    function getJob2(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "JOB2", job);
    }
    
    function getJob3(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "JOB3", job);
    }
    
    function getJob4(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "JOB4", job);
    }
    
    function getJob5(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "JOB5", job);
    }
    
    function getMot1(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "MOT1", motivation);
    }
    
    function getMot2(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "MOT2", motivation);
    }
    
    function getMot3(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "MOT3", motivation);
    }
    
    function getMot4(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "MOT4", motivation);
    }
    
    function getMot5(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "MOT5", motivation);
    }
    
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal pure returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[7] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 400 400"><style>.base { fill: white; font-family: serif; font-size: 13px; }</style><rect width="100%" height="100%" fill="black" />';
        parts[1] = string(abi.encodePacked('<text x="10" y="30" class="base">The ',getAdj1(tokenId),' ',getJob1(tokenId),' wants to ',getMot1(tokenId),'</text>'));
        parts[2] = string(abi.encodePacked('<text x="10" y="60" class="base">The ',getAdj2(tokenId),' ',getJob2(tokenId),' wants to ',getMot2(tokenId),'</text>'));
        parts[3] = string(abi.encodePacked('<text x="10" y="90" class="base">The ',getAdj3(tokenId),' ',getJob3(tokenId),' wants to ',getMot3(tokenId),'</text>'));
        parts[4] = string(abi.encodePacked('<text x="10" y="120" class="base">The ',getAdj4(tokenId),' ',getJob4(tokenId),' wants to ',getMot4(tokenId),'</text>'));
        parts[5] = string(abi.encodePacked('<text x="10" y="150" class="base">The ',getAdj5(tokenId),' ',getJob5(tokenId),' wants to ',getMot5(tokenId),'</text>'));
        parts[6] = '</svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Adventure Folks:', toString(tokenId), '", "description": "Adventure Folks are the random people you might meet on an adventure. Use them any way you like.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

//    function claim(uint256 tokenId) public nonReentrant {
//        require(tokenId > 0 && tokenId < 10001, "Token ID invalid");
//        _safeMint(_msgSender(), tokenId);
//    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function mint(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( num < 26,                     "You can mint a maximum of 25 Folks" );
        require( supply + num < 10001,         "Exceeds maximum supply" );
        require( msg.value >= 0.01 ether * num, "Money sent is not correct" );

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 10000 && tokenId < 11001, "Token ID invalid");
        _safeMint(owner(), tokenId);
    }
    
    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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
    
    constructor() ERC721("Adventure Folks", "ADVENTUREFOLKS") Ownable() {}
}


library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}