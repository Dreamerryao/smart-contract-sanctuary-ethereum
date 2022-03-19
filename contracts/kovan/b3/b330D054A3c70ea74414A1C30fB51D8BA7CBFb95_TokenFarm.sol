/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;



// Part: OpenZeppelin/[email protected]/Context

/*
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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: smartcontractkit/[email protected]/AggregatorV3Interface

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// Part: OpenZeppelin/[email protected]/Ownable

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

// File: TokenFarm.sol

contract TokenFarm is Ownable {
    IERC20 public dappToken;   
    address[] public allowedTokens;
    address[] public stakers;    

    //Token address => Staker address => Amount
    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokensStaked;
    mapping(address => address) public tokenPriceFeed;

    constructor(address _dappTokenAddress) {
        dappToken = IERC20(_dappTokenAddress);
    }

    function setPriceFeed(address _token, address _priceFeed) onlyOwner public {
        tokenPriceFeed[_token] = _priceFeed;
    }

    function getPriceFeed(address _token) public view returns (address) {
        return tokenPriceFeed[_token];
    }

    function stakeTokens(uint256 _amount, address _token) public {
        require (_amount > 0, "Amount must be greater than zero!");
        require (isTokenAllowed(_token), "Token is currently not allowed!");

        //call transferFrom
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), "Transfer failed!");

        incrementUniqueTokensStaked(_token, msg.sender);                
        stakingBalance[_token][msg.sender] += _amount;

        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    function incrementUniqueTokensStaked(address _token, address _staker) internal {
        if (stakingBalance[_token][msg.sender] <= 0) {
            uniqueTokensStaked[_staker] += 1;
        }
    }

    function decrementUniqueTokensStaked(address _token, address _staker) internal {
        if (stakingBalance[_token][msg.sender] > 0) {
            uniqueTokensStaked[_staker] -= 1;
        }
    }    

    function isTokenAllowed(address _token) public view returns (bool) {
        for (uint256 cnt = 0; cnt < allowedTokens.length; cnt++) {
            if (allowedTokens[cnt] == _token) {
                return true;
            }
        }
        return false;
    }    

    function issueTokens() onlyOwner public {
        //Issue tokens to all stakers
        for (uint256 cnt = 0; cnt < stakers.length; cnt++) {
            address recipient = stakers[cnt];
            uint256 userTotalValue = getUserTotalValue(recipient);
            dappToken.transfer(recipient, userTotalValue);
        }
    }

    function getUserTotalValue(address _user) public view returns (uint256) {
        uint256 userTotal = 0;
        require(uniqueTokensStaked[_user] > 0, "No tokens staked by this user!");

        for (uint256 index = 0; index < allowedTokens.length; index++) {
            if (stakingBalance[allowedTokens[index]][_user] > 0) {
                userTotal += getUserSingleTokenValue(allowedTokens[index], _user);
            }
        }
        return userTotal;
    }

    function getUserSingleTokenValue(address _token, address _user) public view returns (uint256) {
        uint256 usrSingleTokenVal = 0;
        if (stakingBalance[_token][_user] <= 0) {
            return 0;
        }

        (uint256 tokenVal, uint256 decimals) = getTokenValue(_token);
        usrSingleTokenVal = (tokenVal * stakingBalance[_token][_user]) / (10 ** decimals);
        return usrSingleTokenVal;
    }

    function getTokenValue(address _token) public view returns (uint256, uint256) {
        address _tokenPriceFeed = getPriceFeed(_token);
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_tokenPriceFeed);
        (, int256 price, , ,) = priceFeed.latestRoundData();   
        uint256 decimals = uint256(priceFeed.decimals());     
        uint256 adjustedPrice = uint256(price);

        return (adjustedPrice, decimals);        
    }

    function getStakingBalance(address _token, address _user) public view returns (uint256) {
        return stakingBalance[_token][_user];
    }    

    function unstakeTokens(address _token) public {
        require (isTokenAllowed(_token), "Token is currently not allowed!");
        require(stakingBalance[_token][msg.sender] > 0, "Staking balance cannot be zero!");

        decrementUniqueTokensStaked(_token, msg.sender);

        //call transfer
        require(IERC20(_token).transfer(msg.sender, stakingBalance[_token][msg.sender]), "Transfer failed!");
        stakingBalance[_token][msg.sender] = 0;

        if (uniqueTokensStaked[msg.sender] == 0) {
            //Remove from stakers array
            for (uint256 cnt = 0; cnt < stakers.length; cnt++) {
                if (stakers[cnt] == msg.sender) {
                    for (uint256 index = cnt; index < (stakers.length-1); index++) {
                        stakers[index] = stakers[index+1];
                    }
                    stakers.pop();
                    break;
                }
            }
        }
    }

    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function stakerCount() public view returns (uint256) {
        return stakers.length;
    }

}