// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SignatureVerification {
    function recover(bytes32 hash, bytes memory signature)
        public
        pure
        returns (address)
    {}
}

interface NFT {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function setApprovalForAll(address operator, bool _approved) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function mint(address to, uint256 id) external;

    function burn(uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract ExtendedContract is Ownable{
    mapping(address => bool) private whitelistedAddress;

    mapping(bytes => bool) private signatures;
    modifier onlyWhitelisted() {
        require(
            whitelistedAddress[msg.sender] == true ||  msg.sender == owner(),
            "Caller not whitelisted!"
        );
        _;
    }
    SignatureVerification sigVerify;

    constructor() {
        sigVerify = SignatureVerification(
            0x50e0C6CBA35b1fa1dD3e9d05B3eaFB1b01318717
        );

    }

    function checkIfWhitelisted(address _address) public view returns (bool) {
        return whitelistedAddress[_address];
    }

    function addWhitelistAddress(address _address) public onlyOwner {
        require(
            whitelistedAddress[_address] == false,
            "Address already whitelisted!"
        );

        whitelistedAddress[_address] = true;
    }

    function removeWhitelistAddresses(address _address) public onlyOwner {
        require(
            whitelistedAddress[_address] == true,
            "Address Not Exists!"
        );

        whitelistedAddress[_address] = false;
    }

    function mintBatch(
        address contractAddress,
        address _to,
        uint256[] memory ids
    ) public onlyWhitelisted {
        NFT nft = NFT(contractAddress);

        for (uint256 index = 0; index < ids.length; index++) {
            nft.mint(_to, ids[index]);
        }
    }

    function mintMultiBatch(
        address contractAddress,
        address[] memory _to,
        uint256[] memory ids
    ) public onlyWhitelisted {
        NFT nft = NFT(contractAddress);
        require(_to.length == ids.length, "Id and addresses length not equal!");

        for (uint256 index = 0; index < ids.length; index++) {
            nft.mint(_to[index], ids[index]);
        }
    }

    function burnBatch(address contractAddress, uint256[] memory ids) public onlyWhitelisted{
        NFT nft = NFT(contractAddress);
        for (uint256 index = 0; index < ids.length; index++) {
            nft.burn(ids[index]);
        }
    }

    function transferBatch(
        address contractAddress,
        address from,
        address to,
        uint256[] memory ids
    ) public onlyWhitelisted {
        NFT nft = NFT(contractAddress);
        for (uint256 index = 0; index < ids.length; index++) {
            nft.safeTransferFrom(from, to, ids[index]);
        }
    }

    function transferMultiBatch(
        address contractAddress,
        address[] memory from,
        address[] memory to,
        uint256[] memory ids
    ) public onlyWhitelisted {
        NFT nft = NFT(contractAddress);
        require(
            from.length == to.length && to.length == ids.length,
            "Id and addresses length not equal!"
        );

        for (uint256 index = 0; index < ids.length; index++) {
            nft.safeTransferFrom(from[index], to[index], ids[index]);
        }
    }

    function transferApprovalBatch(
        address contractAddress,
        address[] memory from,
        address[] memory to,
        uint256[] memory tokenIds,
        bytes32[] memory msgHash,
        bytes[] memory hashSig
    ) public onlyWhitelisted{
        NFT nft = NFT(contractAddress);
        // require(hasRole(SECONDARY_WHITELISTED_ROLE, _msgSender()), "User not allowed to access");
        require(
            from.length == to.length &&
                to.length == tokenIds.length &&
                tokenIds.length == msgHash.length &&
                msgHash.length == hashSig.length,
            "Ids length exceeding the limit"
        );
        for (uint256 index = 0; index < tokenIds.length; index++) {
            require(
                signatures[hashSig[index]] != true,
                "signature already used"
            );
            require(
                sigVerify.recover(msgHash[index], hashSig[index]) ==
                    nft.ownerOf(tokenIds[index]),
                "Approval denied"
            );
            nft.safeTransferFrom(from[index], to[index], tokenIds[index]);
            signatures[hashSig[index]] = true;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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