/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;


struct ERC1155Listing {
    uint256 listingId;
    address seller;
    address erc1155TokenAddress;
    uint256 erc1155TypeId;
    uint256 category; // 0 is wearable, 1 is badge, 2 is consumable, 3 is tickets
    uint256 quantity;
    uint256 priceInWei;
    uint256 timeCreated;
    uint256 timeLastPurchased;
    uint256 sourceListingId;
    bool sold;
    bool cancelled;
}

interface IERC1155 {

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes memory _data
    ) external;
}

interface Erc1155MarketplaceFacet {

    function executeERC1155Listing(
        uint256 _listingId,
        uint256 _quantity,
        uint256 _priceInWei
    ) external;
    
    function getERC1155Listing(uint256 _listingId) external view returns (ERC1155Listing memory listing_);
}

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract BuyProxy {
    // MATIC
    // address private diamondAddy = 0x86935F11C86623deC8a25696E1C19a8659CbF95d;
    // address private ghstAddy = 0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7;
    // KOVAN
    address private diamondAddy = 0x07543dB60F19b9B48A69a7435B5648b46d4Bb58E;
    address private ghstAddy = 0xeDaA788Ee96a0749a2De48738f5dF0AA88E99ab5;
    IERC1155 private diamondERC1155 = IERC1155(diamondAddy);
    Erc1155MarketplaceFacet private diamondMarketplaceERC1155 = Erc1155MarketplaceFacet(diamondAddy);
    IERC20 private ghstErc20 = IERC20(ghstAddy);

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    function approveGhst() public onlyOwner {
        ghstErc20.approve(diamondAddy, 1e29);
    }

    function withdrawItems(uint256[] memory ids, uint256[] memory values) public onlyOwner {
        diamondERC1155.safeBatchTransferFrom(address(this), owner, ids, values, new bytes(0));
    }
    
    function execute1155Listing(uint256 listingId, uint256 quantity,
                                uint256 priceInWei,
                                uint256 erc1155TypeId, uint256 category) public onlyOwner {
        ERC1155Listing memory listing = diamondMarketplaceERC1155.getERC1155Listing(listingId);
        
        require(listing.sold == false, "listing already sold");
        require(listing.cancelled == false, "listing already cancelled");
        
        require(listing.listingId == listingId, "listingId does not match");
        require(listing.erc1155TypeId == erc1155TypeId, "erc1155TypeId does not match");
        require(listing.quantity == quantity, "quantity does not match");
        require(listing.priceInWei == priceInWei, "priceInWei does not match");
        require(listing.category == category, "priceInWei does not match");
        
        diamondMarketplaceERC1155.executeERC1155Listing(listingId, quantity, priceInWei);
    }
}