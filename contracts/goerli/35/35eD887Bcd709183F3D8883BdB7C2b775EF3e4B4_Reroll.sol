/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


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



interface IStakeSeals  {
    function depositsOf(address person) external returns (uint256[] calldata stakedSeals);
}


interface ISappySeals  {
    function ownerOf(uint256 id) external returns (address sealOwner);
}



contract Reroll is Ownable {
          
    event RerollSeal(address person, uint256 sealId, string attribute);

        IStakeSeals public stakeSealsI;
        ISappySeals public stakeSeal2I;
        ISappySeals public sappySealI;
        uint256 public tokenCost;
        IERC20 public tokenAddress;

     constructor(
        address _stakeSealAddress,
        address _stakeSeal2Address,
        address _sappySealNFTAddress,
        IERC20 _tokenAddress,
        uint256 _tokenCost
    ) {
        stakeSealsI = IStakeSeals(_stakeSealAddress);
        stakeSeal2I = ISappySeals(_stakeSeal2Address);
        sappySealI = ISappySeals(_sappySealNFTAddress);
        tokenCost = _tokenCost;
        tokenAddress = _tokenAddress;
    }

    function isOwner(address person, uint256 sealId) public returns (bool owner) {
        if(sappySealI.ownerOf(sealId) == person || sappySealI.ownerOf(sealId) == person ) {
            return true;
        }
        uint256[] memory stakedSeals = stakeSealsI.depositsOf(person);
        for (uint i=0; i < stakedSeals.length; i++) {
            if(stakedSeals[i] == sealId) {
                return true;
            }
        }

        return false;
    }

    function rerollAttribute(uint256 sealId, string calldata attribute) external {
        require(isOwner(msg.sender, sealId), "Reroll: You are not the owner of this seal");
        tokenAddress.transfer(msg.sender, tokenCost);
        emit RerollSeal(msg.sender,sealId,attribute);
     }

     function testEmission(uint256 sealId, string calldata attribute) onlyOwner external {
        emit RerollSeal(msg.sender,sealId,attribute);
     }


}