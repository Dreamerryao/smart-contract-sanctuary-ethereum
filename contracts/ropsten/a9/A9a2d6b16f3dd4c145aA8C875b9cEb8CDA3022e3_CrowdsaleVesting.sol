// SPDX-License-Identifier: MIT
/* ========================================================== DEFI HUNTERS DAO ========================================================================
                                                        https://defihuntersdao.club/
--------------------------------------------------------------- February 2021 -------------------------------------------------------------------------
 #######       #######         #####         ####              #####                                           ####                     ###
##########    ##########       #####      ##########         ########                                          ####                     ###
###########   ###########     #######    ############      ##########                                          ####                     ###
####    ####  ####    ####    #######    ####    ####      ####       ###  ##   ######   ###   ###   ###  #########   ######  #######   ###    ######
####    ####  ####    ####    ### ###   ####      ####    ####        ####### #########  #### ####  #### ##########  #######  ########  ###   ########
####     ###  ####     ###   #### ####  ####      ####    ####        ####### ####  #### #### ##### #### ####  #### ####           ###  ###  ####  ####
####     ###  ####     ###   #########  ####      ####    ####        ####   ####    ###  ### ##### ### ####   ####  ######   ########  ###  ##########
####    ####  ####    ####  ########### ####      ####    ####        ####   ####    ###  ###### ###### ####   ####   ###### #########  ###  ##########
####   #####  ####   #####  ###########  ####    ####      #####      ####   ####   ####   ##### #####  ####   ####     #### ###   ###  ###  ####
###########   ###########  ####     ###  ###########        ######### ####    ##########   ####  #####   ########## ######## #########  ###   ########
#########     #########    ####     ####   ########          ######## ####     ########    ####   ###     ######### #######   ########  ###    #######
                                                                       ##
                                            ####     ####                           ###
                                            ####     ####                      #    ###
                                             ####   ####                     ###    ###
                                             ####   ####   ######    ############## ###  ### #####     ########
                                             ####  ####   ########  ############### ###  ##########   #########
                                              #### ####  ####  ########     ######  ###  ##### ####  ####  ####
                                              #### ###   ########## ######   ###    ###  ####   ###  ###    ###
                                               #######   ##########  ######  ###    ###  ####   ###  ###    ###
                                               ######    ####          ####  ###    ###  ####   ###  ####  ####
                                                #####     ######## ########  ###### ###  ####   ###   #########
                                                ####       ####### #######   ###### ###  ####   ###    ########
                                                                                                          ####
                                                                                                      #########
                                                                                                      ####*/
pragma solidity 0.8.11;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Participants.sol";

/**
 * @notice Allows each token to be associated with a creator.
 */
contract CrowdsaleVesting is Ownable, Participants, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // https://polygonscan.com/token/0x90F3edc7D5298918F7BB51694134b07356F7d0C7 
    IERC20 public ddao = IERC20(0x90F3edc7D5298918F7BB51694134b07356F7d0C7);

    // https://polygonscan.com/token/0xca1931c970ca8c225a3401bb472b52c46bba8382
    IERC20 public addao = IERC20(0xCA1931C970CA8C225A3401Bb472b52C46bBa8382);

    mapping(uint8 => mapping(address => uint256)) public tokensClaimed;
    mapping(address => bool) public blacklist;

    uint256 constant public ROUND_SEED = 0;
    uint256 constant public ROUND_PRIVATE_1 = 1;
    uint256 constant public ROUND_PRIVATE_2 = 2;

    uint48 constant public START_DATE = 1646092800; // 1 MAR.

    // Vesting periods are set in months
    uint256 constant public VESTING_PERIOD_SEED = 24;
    uint256 constant public VESTING_PERIOD_PRIVATE_1 = 18;
    uint256 constant public VESTING_PERIOD_PRIVATE_2 = 12;

    uint256 public oneMonth = 30 days;

    struct ClaimedInfo {
        uint48 timestamp;
        uint256 ddaoTokenAmount;
        uint256 claimNumber;
        uint256 blockNumber;
    }
    mapping(uint8 => mapping(address => uint256)) public claimAddressNumber;
    mapping(uint8 => mapping(address => mapping(uint256 => ClaimedInfo))) public claimByAddress; // Should know about round

    function claim(uint8 _round) public nonReentrant {
        require(_round == ROUND_SEED || _round == ROUND_PRIVATE_1 || _round == ROUND_PRIVATE_2, "CrowdsaleVesting: This round has not supported");

        uint256 vestedAmount = addao.balanceOf(msg.sender);
        
        uint256 tokensToSend;
        if (vestedAmount != 0) {
            tokensToSend = getTokensToSend(msg.sender, _round);
        } 

        require(seed[msg.sender] != 0 || private1[msg.sender] != 0 || private2[msg.sender] != 0, "CrowdsaleVesting: This wallet address is not in whitelist");
        require(tokensToSend > 0, "CrowdsaleVesting: Nothing to claim");
        require(!blacklist[msg.sender], "CrowdsaleVesting: This wallet address has been blocked");

        tokensClaimed[_round][msg.sender] += tokensToSend;

        addao.safeTransferFrom(msg.sender, address(this), tokensToSend);

        ddao.safeTransfer(msg.sender, tokensToSend);

        uint256 nextNumber = claimAddressNumber[_round][msg.sender] + 1;
        claimAddressNumber[_round][msg.sender] = nextNumber;

        claimByAddress[_round][msg.sender][nextNumber] = ClaimedInfo(uint48(block.timestamp), tokensToSend, nextNumber, block.number);
    }

    function getTokensToSend(address _address, uint8 _round) view public returns (uint256) {
        uint256 calc = calculateUnlockedTokens(_address, _round, 0);
        if (calc > 0) {
            return calc - tokensClaimed[_round][_address];
        }
        return 0;
    }

    function calculateUnlockedTokens(address _address, uint8 _round, uint48 _date) public view returns (uint256) {
        require(_round == ROUND_SEED || _round == ROUND_PRIVATE_1 || _round == ROUND_PRIVATE_2, "CrowdsaleVesting: This round has not supported");

        uint48 timestamp;
        if (_date != 0) {
            timestamp = _date;
        } else {
            timestamp = uint48(block.timestamp);
        }

        uint256 result;
        if (timestamp <= START_DATE) {
            return result;
        }

        if (_round == ROUND_SEED) {
            result += availableTokenByRound(seed[_address], VESTING_PERIOD_SEED, timestamp);
        }
        if (_round == ROUND_PRIVATE_1) {
            result += availableTokenByRound(private1[_address], VESTING_PERIOD_PRIVATE_1, timestamp);
        }
        if (_round == ROUND_PRIVATE_2) {
            result += availableTokenByRound(private2[_address], VESTING_PERIOD_PRIVATE_2, timestamp);
        }
	return result;
    }

    function availableTokenByRound(uint256 _availableAmount, uint256 _vestingPeriod, uint48 _timestamp) internal view returns (uint256) {
        uint256 secondsPassed = _timestamp - START_DATE;
        secondsPassed = secondsPassed > _vestingPeriod * oneMonth ? (_vestingPeriod * oneMonth) : secondsPassed;

        return (_availableAmount * secondsPassed) / (_vestingPeriod * oneMonth);
    }

    function lockAddress(address _address) public onlyOwner {
        blacklist[_address] = true;
    }

    function unlockAddress(address _address) public onlyOwner {
        blacklist[_address] = false;
    }

    function adminGetCoin(uint256 _amount) public onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    function adminGetToken(address _tokenAddress, uint256 _amount) public onlyOwner {
        IERC20(_tokenAddress).safeTransfer(msg.sender, _amount);
    }

    function balanceOf(address _address) public view returns (uint256 result) {
        result += seed[_address] - tokensClaimed[0][_address];
        result += private1[_address] - tokensClaimed[1][_address];
        result += private2[_address] - tokensClaimed[2][_address];
    }
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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Allows each token to be associated with a creator.
 */
contract Participants is Ownable {
    mapping(address => uint256) public seed;
    mapping(address => uint256) public private1;
    mapping(address => uint256) public private2;

    constructor() {
        // ****** For tests only - Should be comment in deploy ******
        // seed[0x70997970C51812dc3A010C7d01b50e0d17dc79C8] = 625000000000000000000000; //           625000 DDAO | $ 100000
        // private1[0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC] = 31250000000000000000000; //            31250 DDAO | $ 10000
        // private2[0x90F79bf6EB2c4f870365E785982E1f101E93b906] = 2170212765957400000000; //  2170.2127659574 DDAO | $ 1020
        // ****** For tests only ^^^ ******

        seed[0xECCFbC5B04Da35D611EF8b51099fA5Bc6639d73b] = 625000000000000000000000; //           625000 DDAO | $ 100000
        seed[0x7777420DD0E5f0E13D51C831f77495a057aaBBBB] = 332500000000000000000000; //           332500 DDAO | $ 53200
        seed[0xEB2d2F1b8c558a40207669291Fda468E50c8A0bB] = 312500000000000000000000; //           312500 DDAO | $ 50000
        seed[0x8595f8141E90fcf6Ee17C85142Fd03d3138A6198] = 312500000000000000000000; //           312500 DDAO | $ 50000
        seed[0xCf57A3b1C076838116731FDe404492D9d168747A] = 312500000000000000000000; //           312500 DDAO | $ 50000
        seed[0x07587c046d4d4BD97C2d64EDBfAB1c1fE28A10E5] = 312500000000000000000000; //           312500 DDAO | $ 50000
        seed[0x5555DADcb41fB48934b02A0DBF793b97541F7777] = 312500000000000000000000; //           312500 DDAO | $ 50000

        private1[0x0026Ec57900Be57503Efda250328507156dAC982] = 93750000000000000000000; //            93750 DDAO | $ 30000
        private1[0xd53b873683Df491553eea6a069770144Ad30F3A9] = 93750000000000000000000; //            93750 DDAO | $ 30000
        private1[0x7701E5Bf2D8aE221f23F460FE73420eeE86d2872] = 78125000000000000000000; //            78125 DDAO | $ 25000
        private1[0x1A72CCE42499361FFF103855F845B8cFc1c25b67] = 62500000000000000000000; //            62500 DDAO | $ 20000
        private1[0x1b9E791f3259dcEF7D1e366b33F644841c2461a5] = 62500000000000000000000; //            62500 DDAO | $ 20000
        private1[0x4E560A3ecfe9E5386E727c76f6e2690aE7a1Bc82] = 58437500000000000000000; //          58437.5 DDAO | $ 18700
        private1[0xCeeA2d354c6357ed7e10e629bd2734119A5B3c21] = 48351171684062000000000; //  48351.171684062 DDAO | $ 15472.3749389
        private1[0x98BCE99aa50CB33eca0dDcb2a04404B80dEd3F3E] = 46875000000000000000000; //            46875 DDAO | $ 15000
        private1[0xeE74a1e81B6C55e3D02D05D7CaE9FD6BCee0E651] = 39062500000000000000000; //          39062.5 DDAO | $ 12500
        private1[0x9f8eF2849133286860A8216cA11359381706Fa4a] = 37500000000000000000000; //            37500 DDAO | $ 12000
        private1[0x8D88F01D183DDfD30782E565fdBcD85c14413cAF] = 34375000000000000000000; //            34375 DDAO | $ 11000
        private1[0xB862D5e30DE97368801bDC24A53aD90F56a9C068] = 33021339193750000000000; //   33021.33919375 DDAO | $ 10566.828542
        private1[0x4F9ef189F387e0a91d46812cFB2ecE0d558a471C] = 31562500000000000000000; //          31562.5 DDAO | $ 10100
        private1[0x79e5c907b9d4Af5840C687e6975a1C530895454a] = 31318750000000000000000; //         31318.75 DDAO | $ 10022
        private1[0xFB81414570E338E28C98417c38A3A5c9C6503516] = 31253125000000000000000; //        31253.125 DDAO | $ 10001
        private1[0x35e55F287EFA64dAb88A289a32F9e5942Ab28b18] = 31250000000000000000000; //            31250 DDAO | $ 10000
        private1[0xda7B5C50874a82C0262b4eA6e6001E2b002829E9] = 31250000000000000000000; //            31250 DDAO | $ 10000
        private1[0x7Ed273A361D6bb16833f0E563C313e205738112f] = 31250000000000000000000; //            31250 DDAO | $ 10000
        private1[0x3cB704A5FB4428796b728DF7e4CbC67BCA1497Ae] = 31250000000000000000000; //            31250 DDAO | $ 10000
        private1[0xEc8c50223E785C3Ff21fd9F9ABafAcfB1e2215FC] = 31250000000000000000000; //            31250 DDAO | $ 10000
        private1[0x871cAEF9d39e05f76A3F6A3Bb7690168f0188925] = 31250000000000000000000; //            31250 DDAO | $ 10000
        private1[0xbE20DFb456b7E81f691A8445d073e56602E3cefa] = 31250000000000000000000; //            31250 DDAO | $ 10000
        private1[0x710A169B822Bf51b8F8E6538c63deD200932BB29] = 31250000000000000000000; //            31250 DDAO | $ 10000
        private1[0x6Fa98A4254c7E9Ec681cCeb3Cb8D64a70Dbea256] = 31250000000000000000000; //            31250 DDAO | $ 10000
        private1[0x524b7c9B4cA33ba72445DFd2d6404C81d8D1F2E3] = 31250000000000000000000; //            31250 DDAO | $ 10000
        private1[0x92fc7C69AD976e188b004Cd60Cbd0C8448c770bA] = 31250000000000000000000; //            31250 DDAO | $ 10000
        private1[0x32f8E5d3F4039d1DF89B6A1e544288289A500Fd1] = 31250000000000000000000; //            31250 DDAO | $ 10000
        private1[0x256b09f7Ae7d5fec8C8ac77184CA09F867BbBf4c] = 31250000000000000000000; //            31250 DDAO | $ 10000
        private1[0xC9D15F4E6f1b37CbF0E8068Ff84B5282edEF9707] = 31250000000000000000000; //            31250 DDAO | $ 10000
        private1[0x8ad686fB89b2944B083C900ec5dDCd2bB02af1D0] = 31250000000000000000000; //            31250 DDAO | $ 10000
        private1[0xe1C69F432f2Ba9eEb33ab4bDd23BD417cb89886a] = 31250000000000000000000; //            31250 DDAO | $ 10000
        private1[0x355e03d40211cc6b6D18ce52278e91566fF29839] = 31250000000000000000000; //            31250 DDAO | $ 10000

        private2[0x4F80d10339CdA1EDc936e15E7066C1DBbd8Eb01F] = 15782000000000000000000; //            15782 DDAO | $ 7417.54
        private2[0x4959769500C751f32FEa39012b5244C722c643Dd] = 10667532039798000000000; //  10667.532039798 DDAO | $ 5013.7400587051
        private2[0x89BFc312583bE9a9E518928F24eBdc03270C7375] = 10648936170213000000000; //  10648.936170213 DDAO | $ 5005
        private2[0x4d35B59A3C1F59D5fF94dD7B2b3A1198378c4678] = 10639598053191000000000; //  10639.598053191 DDAO | $ 5000.611085
        private2[0xa73eAf66656270Cc2b27304a170a3ACbd666B54B] = 10638297872340000000000; //   10638.29787234 DDAO | $ 5000
        private2[0xb647f84d4DC1C9bD9Bf42BfFe0FEA69C9F2bb843] = 10638297872340000000000; //   10638.29787234 DDAO | $ 5000
        private2[0x33Ad49856da25b8E2E2D762c411AEda0D1727918] = 10638297872340000000000; //   10638.29787234 DDAO | $ 5000
        private2[0x420ACe7D85821A887891A43CC8a2aFE0D84433a9] = 10638297872340000000000; //   10638.29787234 DDAO | $ 5000
        private2[0x3A484fc4E7873Bd79D0B9B05ED6067A549eC9f49] = 10638297872340000000000; //   10638.29787234 DDAO | $ 5000
        private2[0x7AE29F334D7cb67b58df5aE2A19F360F1Fd3bE75] = 10638297872340000000000; //   10638.29787234 DDAO | $ 5000
        private2[0xd09153823Cf2f29ed6B7E959739bca97C1D273B8] = 10638297872340000000000; //   10638.29787234 DDAO | $ 5000
        private2[0xDE92728804683EC03EFAF6C293e428fc72C2ec95] = 10638297872340000000000; //   10638.29787234 DDAO | $ 5000
        private2[0x3A79caC51e770a84E8Cb5155AAafAA9CaC83F429] = 10638297872340000000000; //   10638.29787234 DDAO | $ 5000
        private2[0x5A20ab4F35Dba889D1f6244c0D53A153DCd28766] = 9444461942553200000000; //  9444.4619425532 DDAO | $ 4438.897113
        private2[0x79440849d5BA6Df5fb1F45Ff36BE3979F4271fa4] = 7518148665957400000000; //  7518.1486659574 DDAO | $ 3533.529873
        private2[0xbD0Ad704f38AfebbCb4BA891389938D4177A8A92] = 7446808510638300000000; //  7446.8085106383 DDAO | $ 3500
        private2[0x21130c9b9D00BcB6cDAF24d0E85809cf96251F35] = 6489361702127700000000; //  6489.3617021277 DDAO | $ 3050
        private2[0x42A6396437eBA7bFD6B5195B7134BE64443521ed] = 6412765957446800000000; //  6412.7659574468 DDAO | $ 3014
        private2[0xC3aB2C2Eb604F159C842D9cAdaBBa2d6254c43d5] = 6389361702127700000000; //  6389.3617021277 DDAO | $ 3003
        private2[0x5D10100d130467cf8DBE2B904100141F1a63318F] = 6382978723404300000000; //  6382.9787234043 DDAO | $ 3000
        private2[0x585a003aA0b446C0F9baD7b3b0BAc5A809988588] = 6382978723404300000000; //  6382.9787234043 DDAO | $ 3000
        private2[0x125EaE40D9898610C926bb5fcEE9529D9ac885aF] = 6382978723404300000000; //  6382.9787234043 DDAO | $ 3000
        private2[0x24f39151D6d8A9574D1DAC49a44F1263999D0dda] = 5319148936170200000000; //  5319.1489361702 DDAO | $ 2500
        private2[0xe6BB1bEBF6829ca5240A80F7076E4CFD6Ee540ae] = 5276595744680900000000; //  5276.5957446809 DDAO | $ 2480
        private2[0xf3143D244F33eb40252464d3b692FA519847B7a9] = 4851063829787200000000; //  4851.0638297872 DDAO | $ 2280
        private2[0x764108BAcf10e30F6f249d17E7612fB9008923F0] = 4851063829787200000000; //  4851.0638297872 DDAO | $ 2280
        private2[0xF6d670C5C0B206f44E93dE811054F8C0b6e15905] = 4289361702127700000000; //  4289.3617021277 DDAO | $ 2016
        private2[0x73073A915f8a582B061091368486fECA640552BA] = 4274680851063800000000; //  4274.6808510638 DDAO | $ 2009.1
        private2[0xa66a4b8461e4786C265B7AbD1F5dfdb6e487f809] = 4256595744680900000000; //  4256.5957446809 DDAO | $ 2000.6
        private2[0x07b449319D200b1189406c58967348c5bA0D4083] = 4256457456721200000000; //  4256.4574567212 DDAO | $ 2000.5350046589
        private2[0x15c5F3a14d4492b1a26f4c6557251a6F247a2Dd5] = 4255319148936200000000; //  4255.3191489362 DDAO | $ 2000
        private2[0x7eE33a8939C6e08cfE207519e220456CB770b982] = 4255319148936200000000; //  4255.3191489362 DDAO | $ 2000
        private2[0x2aE024C5EE8dA720b9A51F50D53a291aca37dEb1] = 4255319148936200000000; //  4255.3191489362 DDAO | $ 2000
        private2[0x0f5A11bEc9B124e73F51186042f4516F924353e0] = 4255319148936200000000; //  4255.3191489362 DDAO | $ 2000
        private2[0x2230A3fa220B0234E468a52389272d239CEB809d] = 4255319148936200000000; //  4255.3191489362 DDAO | $ 2000
        private2[0x65028EEE0F81E76A8Ffc39721eD4c18643cB9A4C] = 4255319148936200000000; //  4255.3191489362 DDAO | $ 2000
        private2[0x931ddC55Ea7074a190ded7429E82dfAdFeDC0269] = 4255319148936200000000; //  4255.3191489362 DDAO | $ 2000
        private2[0xB6a95916221Abef28339594161cd154Bc650c515] = 3765957446808500000000; //  3765.9574468085 DDAO | $ 1770
        private2[0x093E088901909dEecC1b4a1479fBcCE1FBEd31E7] = 3617021276595700000000; //  3617.0212765957 DDAO | $ 1700
        private2[0xb521154e8f8978f64567FE0FA7359Ab47f7363fA] = 3287234042553200000000; //  3287.2340425532 DDAO | $ 1545
        private2[0x9867EBde73BD54d2D7e55E28057A5Fe3bd2027b6] = 3272787242553200000000; //  3272.7872425532 DDAO | $ 1538.210004
        private2[0x4D3c3E7F5EBae3aCBac78EfF2457a842Ab86577e] = 3251063829787200000000; //  3251.0638297872 DDAO | $ 1528
        private2[0x522b76c8f7764009178B3Fd89bBB0134ADEC44a8] = 3202645110425500000000; //  3202.6451104255 DDAO | $ 1505.2432019
        private2[0x882bBB07991c5c2f65988fd077CdDF405FE5b56f] = 3192340425531900000000; //  3192.3404255319 DDAO | $ 1500.4
        private2[0x0c2262b636d91Ec5582f4F95b40988a56496B8f1] = 3191489361702100000000; //  3191.4893617021 DDAO | $ 1500
        private2[0x57dA448673AfB7a06150Ab7a92c7572e7c75D2E5] = 3191489361702100000000; //  3191.4893617021 DDAO | $ 1500
        private2[0x68cf193fFE134aD92C1DB0267d2062D01FEFDD06] = 3191489361702100000000; //  3191.4893617021 DDAO | $ 1500
        private2[0x35205135F0883e6a59aF9cb64310c53003433122] = 3191489361702100000000; //  3191.4893617021 DDAO | $ 1500
        private2[0xA368bae3df1107cF22Daf0a79761EF94656D789A] = 3159574468085100000000; //  3159.5744680851 DDAO | $ 1485
        private2[0xA31B0BE89D0bcDF35B39682b652bEb8390A8F2Dc] = 2913791265957400000000; //  2913.7912659574 DDAO | $ 1369.481895
        private2[0x9F74e07D01c8eE7D1b4B0e9739c8c75E8c23Ef4b] = 2872340425531900000000; //  2872.3404255319 DDAO | $ 1350
        private2[0xA7a9544D86066BF583be602195536918497b1fFf] = 2765957446808500000000; //  2765.9574468085 DDAO | $ 1300
        private2[0x64F8eF34aC5Dc26410f2A1A0e2b4641189040231] = 2600000000000000000000; //             2600 DDAO | $ 1222
        private2[0xE088efbff6aA52f679F76F33924C61F2D79FF8E2] = 2553191489361700000000; //  2553.1914893617 DDAO | $ 1200
        private2[0xD0929C7f44AB8cda86502baaf9961527fC856DDC] = 2515989780989700000000; //  2515.9897809897 DDAO | $ 1182.5151970652
        private2[0x6592aB22faD2d91c01cCB4429F11022E2595C401] = 2511826170212800000000; //  2511.8261702128 DDAO | $ 1180.5583
        private2[0x07E8cd40Be6DD430a8B70E990D6aF7Cd2c5fD52c] = 2476687060085100000000; //  2476.6870600851 DDAO | $ 1164.04291824
        private2[0x875Bf94C16000710f721Cf453B948f23B7394ec2] = 2345194139228500000000; //  2345.1941392285 DDAO | $ 1102.2412454374
        private2[0x1bdaA24527F033ABBe9Bc51b63C0F2a3e913485b] = 2340425531914900000000; //  2340.4255319149 DDAO | $ 1100
        private2[0x687922176D1BbcBcdC295E121BcCaA45A1f40fCd] = 2340425531914900000000; //  2340.4255319149 DDAO | $ 1100
        private2[0x2CE83785eD44961959bf5251e85af897Ba9ddAC7] = 2319702504255300000000; //  2319.7025042553 DDAO | $ 1090.260177
        private2[0xCDCaDF2195c1376f59808028eA21630B361Ba9b8] = 2310638297872300000000; //  2310.6382978723 DDAO | $ 1086
        private2[0x7Ff698e124d1D14E6d836aF4dA0Ae448c8FfFa6F] = 2302934836170200000000; //  2302.9348361702 DDAO | $ 1082.379373
        private2[0x11f53fdAb3054a5cA63778659263aF0838b642b1] = 2234042553191500000000; //  2234.0425531915 DDAO | $ 1050
        private2[0x9f8eF2849133286860A8216cA11359381706Fa4a] = 2234042553191500000000; //  2234.0425531915 DDAO | $ 1050
        private2[0x826121D2a47c9D6e71Fd4FED082CECCc8A5381b1] = 2202127659574500000000; //  2202.1276595745 DDAO | $ 1035
        private2[0x674901AdeB413C126a069402E751ba80F2e2152e] = 2201778444129100000000; //  2201.7784441291 DDAO | $ 1034.8358687407
        private2[0x228Bb6C83e8d0767eD342dd333DDbD55Ad217a3D] = 2191489361702100000000; //  2191.4893617021 DDAO | $ 1030
        private2[0xB248B3309e31Ca924449fd2dbe21862E9f1accf5] = 2172669850608700000000; //  2172.6698506087 DDAO | $ 1021.1548297861
        private2[0xb14ae50038abBd0F5B38b93F4384e4aFE83b9350] = 2170212765957400000000; //  2170.2127659574 DDAO | $ 1020
        private2[0x795e43E9e2423620dA9107F2a5088e039F9A0112] = 2167234042553200000000; //  2167.2340425532 DDAO | $ 1018.6
        private2[0x86649d0a9cAf37b51E33b04d89d4BF63dd696fE6] = 2159574468085100000000; //  2159.5744680851 DDAO | $ 1015
        private2[0x8a382bb6BF2008492268DEdC549B6Cf189a067B5] = 2143092963829800000000; //  2143.0929638298 DDAO | $ 1007.253693
        private2[0x687cEE1e9B4E2a33A63C5319fe6D5DbBaa8d5E91] = 2142553191489400000000; //  2142.5531914894 DDAO | $ 1007
        private2[0x390b07DC402DcFD54D5113C8f85d90329A0141ef] = 2129787234042600000000; //  2129.7872340426 DDAO | $ 1001
        private2[0x0aa05378529F2D1707a0B196B846d7963d677d37] = 2129787234042600000000; //  2129.7872340426 DDAO | $ 1001
        private2[0x8c1203dfC78068b0Fa5d7a2dD2a2fF9cFA89fFcE] = 2127659574468100000000; //  2127.6595744681 DDAO | $ 1000
        private2[0xee86f2BAFC7e33EFDD5cf3970e33C361Cb7aDeD9] = 2127659574468100000000; //  2127.6595744681 DDAO | $ 1000
        private2[0x0be82Fe1422d6D5cA74fd73A37a6C89636235B25] = 2127659574468100000000; //  2127.6595744681 DDAO | $ 1000
        private2[0xF33782f1384a931A3e66650c3741FCC279a838fC] = 2127659574468100000000; //  2127.6595744681 DDAO | $ 1000
        private2[0xD878a0a545dCC7751Caf6d796c0267C202A957Db] = 2127659574468100000000; //  2127.6595744681 DDAO | $ 1000
        private2[0x7A4Ad79C4EACe6db85a86a9Fa71EEBD9bbA17Af2] = 2127659574468100000000; //  2127.6595744681 DDAO | $ 1000
        private2[0x32527CA6ec2B85AbaCA0fb2dd3878e5b7Bb5b370] = 2127659574468100000000; //  2127.6595744681 DDAO | $ 1000
        private2[0x35E3c412286d59Af71ba5836cE6017E416ACf8BC] = 2127659574468100000000; //  2127.6595744681 DDAO | $ 1000
        private2[0xDc6c3d081691f7ef4ae25f488098aD0350052D43] = 2127659574468100000000; //  2127.6595744681 DDAO | $ 1000
        private2[0xfA79F7c2601a4C2A40C80eC10cE0667988B0FC36] = 2127659574468100000000; //  2127.6595744681 DDAO | $ 1000
        private2[0xD24596a11337129A939ba11034912B7D55262b46] = 2127659574468100000000; //  2127.6595744681 DDAO | $ 1000
        private2[0x5748c8EE8F7Fe23D14096E51Ca0fb3Cb63223643] = 2127659574468100000000; //  2127.6595744681 DDAO | $ 1000
        private2[0xe2D18861c892f4eFbaB6b2749e2eDe16aF458A94] = 2127659574468100000000; //  2127.6595744681 DDAO | $ 1000
        private2[0x7F052861bf21f5208e7C0e30C9056a79E8314bA9] = 2127659574468100000000; //  2127.6595744681 DDAO | $ 1000
        private2[0xA9786dA5d3ABb6C404b79DF28b7f402E58eF7c5B] = 2127659574468100000000; //  2127.6595744681 DDAO | $ 1000
        private2[0xaF997affb94c5Ca556b28b024E162AA3164f4A43] = 2127659574468100000000; //  2127.6595744681 DDAO | $ 1000
        private2[0x55fb5D5ae4A4F8369209fEf691587d40227166F6] = 2127659574468100000000; //  2127.6595744681 DDAO | $ 1000
        private2[0xf98de1A22d715A88C2A33821917e8ce2e5583D5A] = 2127659574468100000000; //  2127.6595744681 DDAO | $ 1000
        private2[0x6F15FA9582FdCF84f9F12D32F1C850775fD033eE] = 2127659574468100000000; //  2127.6595744681 DDAO | $ 1000
        private2[0x6F255406306D6D78e97a29F7f249f6d2d85d9801] = 2127659574468100000000; //  2127.6595744681 DDAO | $ 1000
        private2[0x2fb0d4F09e5F7E399354D8DbF602c871b84c081F] = 2127659574468100000000; //  2127.6595744681 DDAO | $ 1000
        private2[0x6B745dEfEE931Ee790DFe5333446eF454c45D8Cf] = 2127659574468100000000; //  2127.6595744681 DDAO | $ 1000
        private2[0x94d3B13745c23fB57a9634Db0b6e4f0d8b5a1053] = 2127659574468100000000; //  2127.6595744681 DDAO | $ 1000
        private2[0x498E96c727700a6B7aC2c4EfBd3E9a5DA4F0d137] = 2127659574468100000000; //  2127.6595744681 DDAO | $ 1000
        private2[0xB7c3A0928c06A80DC4A4CDc9dC0aec33E047A4c8] = 1063829787234000000000; //   1063.829787234 DDAO | $ 500

        private2[0x627C125475d70bbB7eb138bd243851824c0865a1] = 53191000000000000000000; //   53.191 DDAO
        // Team https://polygonscan.com/address/0x2E7bEC36f8642Cc3df83C19470bE089A5FAF98Fa#code
        private2[0x2E7bEC36f8642Cc3df83C19470bE089A5FAF98Fa] = 1680000000000000000000000; // 1680000 DDAO

    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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