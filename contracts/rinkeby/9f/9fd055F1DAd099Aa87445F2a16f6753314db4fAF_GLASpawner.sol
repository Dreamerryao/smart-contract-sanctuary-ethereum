/**
 *Submitted for verification at Etherscan.io on 2021-09-11
*/

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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

// File: contracts/spawner.sol


pragma solidity ^0.8.0;



contract GLASpawner is Ownable{
    // xac suat ra cac rare khi mo hop
    uint private rarity1 = 7500;
    uint private rarity2 = 9375;
    
    uint256 newHeroPrice = 7e21;
    uint256 chestPrice = 1e22;
    
    address public manageContract;
    
    event OpenChest(address user, uint heroType, uint8 rarity);
    event SetPrice(uint256 newHeroPrice_, uint256 chestPrice_);

  //open chest, random a number 0-10000, number < 7500 => rarity1, 7500 <= number <9375 => rarity2, else r3
    function openChest() public {
        require(tx.origin == msg.sender,"don't try to cheat");
        address ftContract = IManageContract(manageContract).getContract("GLAToken");
        address devWallet = IManageContract(manageContract).getDevWallet();
        require(IFTContract(ftContract).transferFrom(msg.sender, devWallet, chestPrice) == true,"Purchase error");
        uint256 rnd = _random(10000);
        uint8 rarity;
        uint heroType = rnd % 3;
        if (rnd < rarity1) 
            rarity = 1;
        else if (rnd < rarity2)
            rarity = 2;
        else
            rarity = 3;
        _mint(msg.sender, heroType, rarity);
        
        emit OpenChest(msg.sender, heroType, rarity);
    }
    
    //user mua 1 character moi rarity1, sau khi user thanh toan, market contract goi den ham mint cua
    //charactercontract
    function buyNewHero(uint heroType) public {
        require(heroType < 3, "Unavailable type hero");
        require(tx.origin == msg.sender,"don't try to cheat");
        address devWallet = IManageContract(manageContract).getDevWallet();
        address ftContract = IManageContract(manageContract).getContract("GLAToken");
        address heroContract = IManageContract(manageContract).getContract("GLAHeroNFT");
        IFTContract(ftContract).transferFrom(msg.sender, devWallet, newHeroPrice);
        IHeroContract(heroContract).mint(msg.sender, heroType, 1);
    }

    function setPrice(uint256 newHeroPrice_, uint256 chestPrice_) external onlyOwner {
        newHeroPrice = newHeroPrice_;
        chestPrice = chestPrice_;
        emit SetPrice(newHeroPrice_, chestPrice_);
    }
    function _random(uint256 range) internal view returns (uint256)  {
        return uint256(keccak256(abi.encodePacked(msg.sender, block.gaslimit, block.coinbase, block.timestamp , gasleft())))%range;      
    }
    function _mint(address owner, uint heroType, uint8 rarity) internal {
        
        address heroContract = IManageContract(manageContract).getContract("GLAHeroNFT");
        IHeroContract(heroContract).mint(owner, heroType, rarity);
    }
    //set dia chia game manage contract
    function setManageContract(address manageContract_) public onlyOwner{
        manageContract = manageContract_;
    }
}

interface IManageContract{
        function getContract(string memory contract_) external view returns (address);
        function getDevWallet() external view returns (address);
    }
interface IHeroContract{
        function mint (address owner,
                 uint heroType, 
                 uint8 rarity 
                 ) external ;
    }
interface IFTContract{
        function transferFrom(
                address sender,
                address recipient,
                uint256 amount
                ) external returns (bool);
    }