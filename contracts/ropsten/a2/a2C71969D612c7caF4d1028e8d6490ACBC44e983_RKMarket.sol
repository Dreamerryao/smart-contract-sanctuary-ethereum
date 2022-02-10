// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./ISplitterContract.sol";

contract RKMarket is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Lot structure
    struct Lot {
        address nft;
        uint256 tokenId;
        uint256 price;
        address seller;
        bool isPrimary;
        bool isSold;
        bool isDelisted;
    }

    /// @notice Offer structure
    struct Offer {
        address nft;
        uint256 tokenId;
        uint256 price;
        address buyer;
        bool isAccepted;
        bool isCancelled;
        uint256 expireAt;
    }

    /// @notice Array of lots
    Lot[] public lots;

    /// @notice Array of offers
    Offer[] public offers;

    /// @notice Contract admin (not owner)
    address payable public admin;

    /// @notice Address of the Splitter Contract
    address public splitter;

    /// @notice Address of the wrapped Ethereum on the Matic mainnet
    address public weth;

    /// @notice Amount to pay for secondary listing
    uint256 public listingPrice;

    /// @notice Get artist address by NFT address and token ID
    mapping(address => mapping(uint256 => address)) public artists;

    /// @notice Get artist address by NFT address
    mapping(address => address) public artistOfCollection;

    /**
     * @notice Events
     */
    event AdminChanged(address oldAdmin, address newAdmin);
    event WethChanged(address oldWeth, address newWeth);
    event SplitterChanged(address oldSplitter, address newSplitter);
    event ListingPriceChanged(uint256 oldPrice, uint256 newPrice);
    event NewLot(
        uint256 lotId,
        address nft,
        uint256 tokenId,
        uint256 price,
        address seller,
        bool isPrimary,
        bool isSold,
        bool isDelisted
    );
    event NewOffer(
        uint256 offerId,
        address nft,
        uint256 tokenId,
        uint256 price,
        address buyer,
        bool isAccepted,
        bool isCancelled,
        uint256 expireAt
    );
    event Delisted(uint256 lotId);
    event OfferCanceled(uint256 offerId);
    event Sold(
        address nft,
        uint256 tokenId,
        uint256 price,
        address seller,
        address artist,
        bool isPrimarySale
    );

    /**
     * @notice Restrict access for admin address only
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    /**
     * @notice Restrict if splitter address is not set yet
     */
    modifier splitterExist() {
        require(splitter != address(0), "set splitter contract first");
        _;
    }

    /// @notice Acts like constructor() for upgradeable contracts
    function initialize(address payable _admin, address _weth)
        public
        initializer
    {
        __Ownable_init();
        __ReentrancyGuard_init();
        require(_admin != address(0), "zero address");
        require(_weth != address(0), "zero address");
        admin = _admin;
        weth = _weth;
        listingPrice = 1 ether;
    }

    /**
     * @notice Set admin address
     * @param newAdmin - Address of new admin
     */
    function setAdmin(address payable newAdmin) external onlyOwner {
        require(newAdmin != address(0), "zero address");
        require(newAdmin != admin, "same address");
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    /**
     * @notice Set splitter address
     * @param newSplitter - Address of the Splitter Contract
     */
    function setSplitter(address newSplitter) external onlyOwner {
        require(newSplitter != address(0), "zero address");
        require(newSplitter != splitter, "same address");
        emit SplitterChanged(splitter, newSplitter);
        splitter = newSplitter;
    }

    /**
     * @notice Set weth address
     * @param _weth - Address of the weth Contract
     */
    function setWeth(address _weth) external onlyOwner {
        require(_weth != address(0), "zero address");
        require(_weth != weth, "same address");
        emit WethChanged(weth, _weth);
        weth = _weth;
    }

    /**
     * @notice Set price for the listing
     * @param newListingPrice - Amount to spend for listing
     */
    function setListingPrice(uint256 newListingPrice) external onlyOwner {
        require(newListingPrice > 0, "zero amount");
        require(newListingPrice != listingPrice, "same amount");
        emit ListingPriceChanged(listingPrice, newListingPrice);
        listingPrice = newListingPrice;
    }

    /**
     * @notice Set artist address for secondary sale (only for external NFT's)
     * @param artist - Address of artist to distribute funds
     * @param nft - Address of related to artist NFT token
     * @param tokenId - ID of the token
     */
    function setArtist(
        address artist,
        address nft,
        uint256 tokenId
    ) external onlyAdmin {
        require(nft != address(0), "zero address");
        artists[nft][tokenId] = artist;
    }

    /**
     * @notice Set artist address for entire collection (only for external NFT's)
     * @param artist - Address of artist to distribute funds
     * @param nft - Address of related to artist NFT token
     */
    function setArtistForCollection(address artist, address nft)
        external
        onlyAdmin
    {
        require(nft != address(0), "zero address");
        artistOfCollection[nft] = artist;
    }

    /**
     * @notice Set batch of artist addresses for secondary sale (only for external NFT's)
     * @param artist - Address of artist to distribute funds
     * @param nft - Address of related to artist NFT token
     * @param tokenIds - Array of token IDs
     */
    function setArtistBatches(
        address artist,
        address nft,
        uint256[] memory tokenIds
    ) external onlyAdmin {
        require(nft != address(0), "zero address");
        require(tokenIds.length > 0, "empty array");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            artists[nft][tokenIds[i]] = artist;
        }
    }

    /**
     * @notice Returns array of active users lots
     * @param seller - Address of NFT seller
     */
    function lotsOfSeller(address seller)
        external
        view
        returns (uint256[] memory ids)
    {
        uint256 sellerLotsCount = 0;
        for (uint256 i = 0; i < lots.length; i++) {
            if (
                lots[i].seller == seller &&
                !lots[i].isSold &&
                !lots[i].isDelisted
            ) {
                sellerLotsCount++;
            }
        }
        ids = new uint256[](sellerLotsCount);
        uint256 j = 0;
        for (uint256 i = 0; i < lots.length; i++) {
            if (
                lots[i].seller == seller &&
                !lots[i].isSold &&
                !lots[i].isDelisted
            ) {
                ids[j] = i;
                j++;
            }
        }
    }

    /**
     * @notice Returns array of active lots
     */
    function allActiveLots()
        external
        view
        returns (uint256[] memory ids)
    {
        uint256 lotsCount = 0;
        for (uint256 i = 0; i < lots.length; i++) {
            if (
                !lots[i].isSold &&
                !lots[i].isDelisted
            ) {
                lotsCount++;
            }
        }
        ids = new uint256[](lotsCount);
        uint256 j = 0;
        for (uint256 i = 0; i < lots.length; i++) {
            if (
                !lots[i].isSold &&
                !lots[i].isDelisted
            ) {
                ids[j] = i;
                j++;
            }
        }
    }


    /**
     * @notice Admin function for primary sale listing
     * @param nft NFT address
     * @param tokenId Token id
     * @param price NFT price in wei
     * @param artist Address of the artist (for the royalties)
     */
    function primarySale(
        address nft,
        uint256 tokenId,
        uint256 price,
        address artist
    ) external onlyAdmin splitterExist {
        artists[nft][tokenId] = artist;
        _createSale(nft, tokenId, price, true);
    }

    /**
     * @notice Admin function for primary sale batches listing
     */
    function primarySaleBatches(
        address nft,
        uint256[] memory tokenIds,
        uint256[] memory prices,
        address[] memory _artists
    ) external onlyAdmin splitterExist {
        require(tokenIds.length == prices.length, "should be the same length");
        require(tokenIds.length > 0, "nothing to sale");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            artists[nft][tokenIds[i]] = _artists[i];
            _createSale(nft, tokenIds[i], prices[i], true);
        }
    }

    /**
     * @notice Function for secondary sale listing
     * @param nft NFT address
     * @param tokenId Token id
     * @param price NFT price in wei
     */
    function secondarySale(
        address nft,
        uint256 tokenId,
        uint256 price
    ) external payable splitterExist nonReentrant {
        require(
            artists[nft][tokenId] != address(0) ||
                artistOfCollection[nft] != address(0),
            "add artist first"
        );
        require(msg.value == listingPrice, "wrong amount");
        (bool success, ) = admin.call{value: listingPrice}("");
        require(success, "payment error");
        _createSale(nft, tokenId, price, false);
    }

    function _createSale(
        address nft,
        uint256 tokenId,
        uint256 price,
        bool isPrimary
    ) internal {
        require(nft != address(0), "zero address");
        require(price > 0, "zero amount");
        IERC721Upgradeable(nft).transferFrom(
            msg.sender,
            address(this),
            tokenId
        );
        Lot memory _lot = Lot(
            nft,
            tokenId,
            price,
            msg.sender,
            isPrimary,
            false,
            false
        );
        lots.push(_lot);
        uint256 _id = lots.length - 1;
        emit NewLot(
            _id,
            nft,
            tokenId,
            price,
            msg.sender,
            isPrimary,
            false,
            false
        );
    }

    /**
     * @notice Function for primary sale delisting
     * @param lotId ID of lot (possition in lots array)
     */
    function delist(uint256 lotId) external onlyAdmin {
        _delist(lotId);
    }

    /**
     * @notice Function for primary sale batches delisting
     * @param lotIds ID of lot (possition in lots array)
     */
    function delistBatches(uint256[] memory lotIds) external onlyAdmin {
        require(lotIds.length > 0, "no ids provided");
        for (uint256 i = 0; i < lotIds.length; i++) {
            _delist(i);
        }
    }

    /**
     * @notice Function for secondary sale delisting
     * @param lotId ID of lot (possition in lots array)
     */
    function delistSecondary(uint256 lotId) external {
        Lot memory _lot = lots[lotId];
        require(!_lot.isPrimary, "only for aftermarket lots");
        require(
            msg.sender == _lot.seller || msg.sender == admin,
            "only admin and seller can delist"
        );
        _delist(lotId);
    }

    function _delist(uint256 lotId) internal {
        Lot storage _lot = lots[lotId];
        _lot.isDelisted = true;
        IERC721Upgradeable(_lot.nft).transferFrom(
            address(this),
            _lot.seller,
            _lot.tokenId
        );
        emit Delisted(lotId);
    }

    /**
     * @notice Buy NFT using specified lot ID
     * @param lotId ID of lot (possition in lots array)
     */
    function buy(uint256 lotId) external splitterExist nonReentrant {
        Lot storage _lot = lots[lotId];
        require(!_lot.isSold, "already sold");
        require(!_lot.isDelisted, "lot delisted");
        require(
            artists[_lot.nft][_lot.tokenId] != address(0) ||
                artistOfCollection[_lot.nft] != address(0),
            "add artist first"
        );
        address _artist;
        if (artists[_lot.nft][_lot.tokenId] != address(0)) {
            _artist = artists[_lot.nft][_lot.tokenId];
        } else {
            _artist = artistOfCollection[_lot.nft];
        }
        if (_lot.isPrimary) {
            (
                address[] memory addresses,
                uint256[] memory shares
            ) = ISplitterContract(splitter).getPrimaryDistribution(_artist);
            require(addresses.length == shares.length, "arrays not equal");
            require(addresses.length > 0, "arrays are empty");
        } else {
            (
                address[] memory addresses,
                uint256[] memory shares
            ) = ISplitterContract(splitter).getSecondaryDistribution(_artist);
            require(addresses.length == shares.length, "arrays not equal");
            require(addresses.length > 0, "arrays are empty");
        }
        IERC20Upgradeable(weth).safeTransferFrom(
            msg.sender,
            splitter,
            _lot.price
        );
        if (_lot.isPrimary) {
            ISplitterContract(splitter).primaryDistribution(
                _artist,
                _lot.price
            );
        } else {
            ISplitterContract(splitter).secondaryDistribution(
                _artist,
                _lot.seller,
                _lot.price
            );
        }
        _lot.isSold = true;
        IERC721Upgradeable(_lot.nft).transferFrom(
            address(this),
            msg.sender,
            _lot.tokenId
        );
        emit Sold(
            _lot.nft,
            _lot.tokenId,
            _lot.price,
            _lot.seller,
            _artist,
            _lot.isPrimary
        );
    }

    /**
     * @notice Create offer instance
     */
    function makeOffer(
        address nft,
        uint256 tokenId,
        uint256 price,
        uint256 duration
    ) external returns (uint256 id) {
        Offer memory offer = Offer(
            nft,
            tokenId,
            price,
            msg.sender,
            false,
            false,
            block.timestamp + duration
        );
        offers.push(offer);
        id = offers.length - 1;
        emit NewOffer(
            id,
            nft,
            tokenId,
            price,
            msg.sender,
            false,
            false,
            block.timestamp + duration
        );
    }

    function cancelOffer(uint256 offerId) external {
        Offer storage _offer = offers[offerId];
        _offer.isCancelled = true;
        emit OfferCanceled(offerId);
    }

    function acceptOffer(uint256 offerId) external {
        Offer storage _offer = offers[offerId];
        require(!_offer.isAccepted, "Offer already accepted!");
        require(!_offer.isCancelled, "Offer already canceled!");
        require(block.timestamp < _offer.expireAt, "Offer was expired!");
        address _artist;
        if (artists[_offer.nft][_offer.tokenId] != address(0)) {
            _artist = artists[_offer.nft][_offer.tokenId];
        } else {
            _artist = artistOfCollection[_offer.nft];
        }
        // Unlisted NFT
        if (
            IERC721Upgradeable(_offer.nft).ownerOf(_offer.tokenId) == msg.sender
        ) {
            //approve required
            _executeOffer(
                msg.sender,
                _offer.buyer,
                _offer.nft,
                _offer.tokenId,
                _offer.price,
                _artist
            );
        }
        // Listed NFT
        if (
            IERC721Upgradeable(_offer.nft).ownerOf(_offer.tokenId) ==
            address(this)
        ) {
            _executeOffer(
                address(this),
                _offer.buyer,
                _offer.nft,
                _offer.tokenId,
                _offer.price,
                _artist
            );
            uint256 lotId = lotIdOfItem(_offer.nft, _offer.tokenId);
            lots[lotId].isSold = true;
        }

        _offer.isAccepted = true;

        emit Sold(
            _offer.nft,
            _offer.tokenId,
            _offer.price,
            msg.sender,
            _artist,
            false
        );
    }

    function _executeOffer(
        address _holder,
        address _buyer,
        address _nft,
        uint256 _tokenId,
        uint256 _price,
        address _artist
    ) internal {
        IERC721Upgradeable(_nft).safeTransferFrom(_holder, _buyer, _tokenId);
        IERC20Upgradeable(weth).safeTransferFrom(_buyer, splitter, _price);
        ISplitterContract(splitter).secondaryDistribution(
            _artist,
            msg.sender,
            _price
        );
    }

    /**
     * @notice Returns array of buyer offers
     * @param buyer - Address of NFT buyer
     */
    function offersOfBuyer(address buyer)
        external
        view
        returns (uint256[] memory ids)
    {
        uint256 buyerOffersCount = 0;
        for (uint256 i = 0; i < offers.length; i++) {
            if (offers[i].buyer == buyer && isActiveOffer(i)) {
                buyerOffersCount++;
            }
        }
        ids = new uint256[](buyerOffersCount);
        uint256 j = 0;
        for (uint256 i = 0; i < offers.length; i++) {
            if (offers[i].buyer == buyer && isActiveOffer(i)) {
                ids[j] = i;
                j++;
            }
        }
    }

    /**
     * @notice Returns array of irrelevant buyer offers (accepted, expired or canceled)
     * @param buyer - Address of NFT buyer
     */
    function irrelevantOffersOfBuyer(address buyer)
        external
        view
        returns (uint256[] memory ids)
    {
        uint256 buyerOffersCount = 0;
        for (uint256 i = 0; i < offers.length; i++) {
            if (offers[i].buyer == buyer && !isActiveOffer(i)) {
                buyerOffersCount++;
            }
        }
        ids = new uint256[](buyerOffersCount);
        uint256 j = 0;
        for (uint256 i = 0; i < offers.length; i++) {
            if (offers[i].buyer == buyer && !isActiveOffer(i)) {
                ids[j] = i;
                j++;
            }
        }
    }

    /**
     * @notice Returns array of seller offers
     * @param seller - Address of NFT seller
     */
    function offersOfSeller(address seller)
        external
        view
        returns (uint256[] memory ids)
    {
        uint256 totalOffers = 0;
        for (uint256 i = 0; i < offers.length; i++) {
            if (isActiveOffer(i)) {
                if (
                    sellerOfItem(offers[i].nft, offers[i].tokenId) == seller ||
                    IERC721Upgradeable(offers[i].nft).ownerOf(
                        offers[i].tokenId
                    ) ==
                    seller
                ) {
                    totalOffers++;
                }
            }
        }

        ids = new uint256[](totalOffers);
        uint256 j = 0;
        for (uint256 i = 0; i < offers.length; i++) {
            if (isActiveOffer(i)) {
                if (
                    sellerOfItem(offers[i].nft, offers[i].tokenId) == seller ||
                    IERC721Upgradeable(offers[i].nft).ownerOf(
                        offers[i].tokenId
                    ) ==
                    seller
                ) {
                    ids[j] = i;
                    j++;
                }
            }
        }
    }

    /**
     * @notice Returns array of irrelevant seller offers
     * @param seller - Address of NFT seller
     */
    function irrelevantOffersOfSeller(address seller)
        external
        view
        returns (uint256[] memory ids)
    {
        uint256 totalOffers = 0;
        for (uint256 i = 0; i < offers.length; i++) {
            if (!isActiveOffer(i)) {
                if (
                    sellerOfItem(offers[i].nft, offers[i].tokenId) == seller ||
                    IERC721Upgradeable(offers[i].nft).ownerOf(
                        offers[i].tokenId
                    ) ==
                    seller
                ) {
                    totalOffers++;
                }
            }
        }

        ids = new uint256[](totalOffers);
        uint256 j = 0;
        for (uint256 i = 0; i < offers.length; i++) {
            if (!isActiveOffer(i)) {
                if (
                    sellerOfItem(offers[i].nft, offers[i].tokenId) == seller ||
                    IERC721Upgradeable(offers[i].nft).ownerOf(
                        offers[i].tokenId
                    ) ==
                    seller
                ) {
                    ids[j] = i;
                    j++;
                }
            }
        }
    }

    /**
     * @notice Returns seller of token from the market by token info
     */
    function sellerOfItem(address nft, uint256 id)
        public
        view
        returns (address)
    {
        for (uint256 i = 0; i < lots.length; i++) {
            if (
                lots[i].nft == nft &&
                lots[i].tokenId == id &&
                !lots[i].isPrimary &&
                !lots[i].isSold &&
                !lots[i].isDelisted
            ) {
                return lots[i].seller;
            }
        }
    }

    /**
     * @notice Returns lot ID by token info
     */
    function lotIdOfItem(address nft, uint256 id)
        public
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < lots.length; i++) {
            if (
                lots[i].nft == nft &&
                lots[i].tokenId == id &&
                !lots[i].isSold &&
                !lots[i].isDelisted
            ) {
                return i;
            }
        }
    }

    /**
     * @dev Return true if offer is active
     */
    function isActiveOffer(uint256 id) public view returns (bool) {
        if (
            !offers[id].isAccepted &&
            !offers[id].isCancelled &&
            block.timestamp < offers[id].expireAt
        ) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice For stuck tokens rescue only
     */
    function rescueTokens(address _token) external onlyOwner {
        uint256 balance = IERC20Upgradeable(_token).balanceOf(address(this));
        IERC20Upgradeable(_token).safeTransfer(msg.sender, balance);
    }

    /**
     * @notice For stuck NFT tokens rescue only
     */
    function rescueNFTTokens(address token, uint256 tokenId)
        external
        onlyOwner
    {
        IERC721Upgradeable(token).transferFrom(
            address(this),
            msg.sender,
            tokenId
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISplitterContract {
    function rkMarket() external view returns (address);

    function SELLER_SHARE() external view returns (uint256);

    function addMarket(address newMarket) external;

    function admin() external view returns (address);

    function getPrimaryDistribution(address artist)
        external
        view
        returns (address[] memory addresses, uint256[] memory shares);

    function getSecondaryDistribution(address artist)
        external
        view
        returns (address[] memory addresses, uint256[] memory shares);

    function initialize(
        address _admin,
        address _rkMarket,
        address _router,
        address[] memory _path
    ) external;

    function otherMarkets(address) external view returns (bool);

    function owner() external view returns (address);

    function path(uint256) external view returns (address);

    function primaryDistribution(address artist, uint256 amount) external;

    function renounceOwnership() external;

    function rescueTokens(address _token) external;

    function router() external view returns (address);

    function secondaryDistribution(
        address artist,
        address seller,
        uint256 amount
    ) external;

    function setAdmin(address newAdmin) external;

    function setDistribution(
        address artist,
        address[] calldata primary_addresses,
        uint256[] calldata primary_shares,
        address[] calldata secondary_addresses,
        uint256[] calldata secondary_shares
    ) external;

    function setFeeDecimals(uint256 _decimals) external;

    function setPath(address[] calldata _path) external;

    function setPrimaryDistribution(
        address artist,
        address[] calldata addresses,
        uint256[] calldata shares
    ) external;

    function setRKMarket(address newMarket) external;

    function setRouter(address _router) external;

    function setSecondaryDistribution(
        address artist,
        address[] calldata addresses,
        uint256[] calldata shares
    ) external;

    function setUSDC(address _usdc) external;

    function setWETH(address _weth) external;

    function shareDecimals() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function usdc() external view returns (address);

    function weth() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
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
interface IERC165Upgradeable {
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