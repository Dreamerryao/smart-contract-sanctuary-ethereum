// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

interface IAngelsAndDevils {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface INFTWorldsStaking {
    function unstake(uint[] calldata tokenIds, address unstakeTo) external;
    function claim(address to) external;
}

interface IWrldToken {
    function balanceOf(address owner) external view returns(uint256);
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
}

contract ADStaking is ERC721Holder, Ownable, ReentrancyGuard {
    IAngelsAndDevils private immutable _angelsAndDevils;
    INFTWorldsStaking private immutable _nftWorldsStaking;
    IWrldToken private immutable _wrldToken;

    address constant public COMMUNITY_WALLET = 0x25baE2C350b5C5C8760d20b10567b0B547154C1B;

    mapping(uint256 => address) public owners;
    mapping(address => uint256) public lastClaimTime;
    mapping(uint256 => mapping(address => uint256)) public accumulated;
    mapping(uint256 => mapping(address => uint256)) public whaleAccumulated;
    mapping(address => uint256[]) public staked;

    uint256 public lastWrldClaim;
    uint256 public distributionPeriod;
    uint256 public dailyReward;
    uint256 public whaleDailyReward;
    uint256 public claimableRewards;
    uint256 public whaleRewards;

    constructor (address angelsAndDevils_, address nftWorldsStaking_, address wrldToken_) {
        _angelsAndDevils = IAngelsAndDevils(angelsAndDevils_);
        _nftWorldsStaking = INFTWorldsStaking(nftWorldsStaking_);
        _wrldToken = IWrldToken(wrldToken_);
    }

    function _calculateReward(address for_) private view returns (uint256) {
        return ((min(block.timestamp, lastWrldClaim + (distributionPeriod * 1 days)) - max(lastWrldClaim, lastClaimTime[for_])) / 1 days) * dailyReward * staked[for_].length;
    }

    function _calculateWhaleReward(address for_) private view returns (uint256) {
        uint256 multiplier = staked[for_].length / 25;

        return ((min(block.timestamp, lastWrldClaim + (distributionPeriod * 1 days)) - max(lastWrldClaim, lastClaimTime[for_])) / 1 days) * whaleDailyReward * multiplier;
    }
    
    function claim() external nonReentrant {
        uint256 reward = _calculateReward(msg.sender) + accumulated[lastWrldClaim][msg.sender];
        uint256 whaleReward = _calculateWhaleReward(msg.sender) + whaleAccumulated[lastWrldClaim][msg.sender];

        claimableRewards -= reward;
        whaleRewards -= whaleReward;

        accumulated[lastWrldClaim][msg.sender] = 0;
        whaleAccumulated[lastWrldClaim][msg.sender] = 0;

        lastClaimTime[msg.sender] = block.timestamp;

        _wrldToken.transfer(msg.sender, reward + whaleReward);
    }

    function stake(uint256[] calldata ids_) external nonReentrant {
        _stake(ids_, msg.sender);
    }

    function stake(uint256[] calldata ids_, address to_) external nonReentrant {
        _stake(ids_, to_);
    }

    function _stake(uint256[] calldata ids_, address to_) private {
        accumulated[lastWrldClaim][to_] += _calculateReward(msg.sender);
        whaleAccumulated[lastWrldClaim][to_] += _calculateWhaleReward(msg.sender);

        for (uint256 i; i < ids_.length; i++) {
            uint256 id = ids_[i];
            address owner = _angelsAndDevils.ownerOf(id);

            require(owner == msg.sender, 'Not owned');

            _angelsAndDevils.safeTransferFrom(msg.sender, address(this), id);

            owners[id] = to_;
            staked[to_].push(id);
        }

        lastClaimTime[to_] = block.timestamp;
    }

    function unstake(uint256[] calldata ids_) external nonReentrant {
        _unstake(ids_, msg.sender);
    }

    function unstake(uint256[] calldata ids_, address to_) external nonReentrant {
        _unstake(ids_, to_);
    }

    function _unstake(uint256[] calldata ids_, address to_) private {
        accumulated[lastWrldClaim][msg.sender] += _calculateReward(msg.sender);
        whaleAccumulated[lastWrldClaim][msg.sender] += _calculateWhaleReward(msg.sender);

        for (uint256 i; i < ids_.length; i++) {
            uint256 id = ids_[i];
            address owner = owners[id];

            require(owner == msg.sender, 'Not owned');

            _angelsAndDevils.safeTransferFrom(address(this), to_, id);

            owners[id] = address(0);

            for (uint256 j; j < staked[msg.sender].length; j++) {
                if (staked[msg.sender][j] == id) {
                    uint256 last = staked[msg.sender].length - 1;

                    staked[msg.sender][j] = staked[msg.sender][last];

                    delete staked[msg.sender][last];

                    staked[msg.sender].pop();

                    break;
                }
            }
        }

        lastClaimTime[msg.sender] = block.timestamp;
    }

    function getCurrentBalance(address account_) external view returns (uint256) {
        return accumulated[lastWrldClaim][account_] + whaleAccumulated[lastWrldClaim][account_] + _calculateReward(account_) + _calculateWhaleReward(account_);
    }

    function getStaked(address account_) external view returns(uint256[] memory) {
        return staked[account_];
    }

    function unstakeNFTWorlds(uint256[] calldata ids_) external onlyOwner {
        _nftWorldsStaking.unstake(ids_, COMMUNITY_WALLET);
    }

    function claimNFTWorldsReward(uint256 distributionPeriod_) external onlyOwner {
        _nftWorldsStaking.claim(address(this));

        uint256 currentBalance = _wrldToken.balanceOf(address(this));
        uint256 gains = currentBalance - claimableRewards - whaleRewards;

        claimableRewards = (gains * 35 / 100) + claimableRewards;
        whaleRewards = (gains * 5 / 100) + whaleRewards;

        dailyReward = claimableRewards / (distributionPeriod_ * 10000);
        whaleDailyReward = whaleRewards / (distributionPeriod_ * 400);

        _wrldToken.transfer(owner(), currentBalance - claimableRewards - whaleRewards);

        distributionPeriod = distributionPeriod_;
        lastWrldClaim = block.timestamp;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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