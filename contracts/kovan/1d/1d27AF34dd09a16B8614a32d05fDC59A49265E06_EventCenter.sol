// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface AccountIndexInterface {
    function isAccount(address _address) external view returns (bool _isAccount);
    function getEOA(address _address) external view returns (address _eoa);
    
}

contract EventCenter is Ownable {
    mapping(address => uint256) public weight; // token wieght

    uint256 public epochStart;
    uint256 public epochEnd;
    uint256 public epochInterval = 14 days;

    event CreateAccount(address EOA, address account);

    event UseFlashLoanForLeverage(
        address EOA,
        address account,
        address token,
        uint256 amount
    );

    event OpenLongLeverage(
        address EOA,
        address account,
        address collateralToken,
        address targetToken,
        uint256 amountTargetToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode
    );

    event OpenShortLeverage(
        address EOA,
        address account,
        address depositToken,
        uint256 depositAmount,
        address targetToken,
        uint256 targetAmount,
        uint256 flashLoanAmount
    );

    event CloseLongLeverage(
        address EOA,
        address account,
        address depositToken,
        uint256 depositAmount,
        address targetToken,
        uint256 targetAmount,
        uint256 flashLoanAmount
    );

    event CloseShortLeverage(
        address EOA,
        address account,
        address depositToken,
        uint256 depositAmount,
        address targetToken,
        uint256 targetAmount,
        uint256 flashLoanAmount
    );

    event AddMargin(
        address EOA,
        address account,
        address depositToken,
        uint256 depositAmount
    );

    event AddScore(
        address EOA,
        address account,
        address token,
        uint256 amount,
        uint256 tokenWeight,
        uint256 score,
        string reason
    );

    event SubScore(
        address EOA,
        address account,
        address token,
        uint256 amount,
        uint256 tokenWeight,
        uint256 score,
        string reason
    );

    address internal accountIndex;

    modifier onlyAccount() {
        require(accountIndex != address(0), "CHFRY: accountIndex not setup");
        require(
            AccountIndexInterface(accountIndex).isAccount(msg.sender),
            "CHFRY: only SmartAccount could emit Event in EventCenter"
        );
        _;
    }

    constructor(address _accountIndex) {
        accountIndex = _accountIndex;
    }

    function setEpochInterval(uint256 _epochInterval) external onlyOwner {
        epochInterval = _epochInterval;
    }

    function startEpoch() external onlyOwner {
        epochStart = block.timestamp;
        epochEnd = epochStart + epochInterval;
    }

    function setWeight(address _token, uint256 _weight) external onlyOwner {
        require(_token != address(0), "CHFRY: address shoud not be 0");
        require(_weight >= 0, "CHFRY: _weight shoud not < 0 ");
        weight[_token] = _weight;
    }

    function emitCreateAccountEvent(address EOA, address account)
        external
        onlyAccount
    {
        emit CreateAccount(EOA, account);
    }

    function emitUseFlashLoanForLeverageEvent(address token, uint256 amount)
        external
        onlyAccount
    {
        address EOA = AccountIndexInterface(accountIndex).getEOA(msg.sender);
        address account = msg.sender;
        emit UseFlashLoanForLeverage(EOA, account, token, amount);
    }

    function emitOpenLongLeverageEvent(
        address collateralToken,
        address targetToken,
        uint256 amountTargetToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode
    ) external  onlyAccount {
        address EOA;
        address account;
        EOA = AccountIndexInterface(accountIndex).getEOA(msg.sender);
        account = msg.sender;
        addScore(EOA, account, targetToken, amountTargetToken, "OpenLongLeverage");
        emit OpenLongLeverage(
            EOA,
            account,
            collateralToken,
            targetToken,
            amountTargetToken,
            amountFlashLoan,
            unitAmt,
            rateMode
        );
    }

    function emitOpenShortLeverageEvent(
        address depositToken,
        uint256 depositAmount,
        address targetToken,
        uint256 targetAmount,
        uint256 flashLoanAmount
    ) external onlyAccount {
        address EOA;
        address account;
        EOA = AccountIndexInterface(accountIndex).getEOA(msg.sender);
        account = msg.sender;
        addScore(EOA, account, targetToken, targetAmount, "OpenShortLeverage");
        emit OpenShortLeverage(
            EOA,
            account,
            depositToken,
            depositAmount,
            targetToken,
            targetAmount,
            flashLoanAmount
        );
    }

    function emitCloseLongLeverageEvent(
        address depositToken,
        uint256 depositAmount,
        address targetToken,
        uint256 targetAmount,
        uint256 flashLoanAmount
    ) external onlyAccount {
        address EOA = AccountIndexInterface(accountIndex).getEOA(msg.sender);
        address account = msg.sender;
        subScore(EOA, account, targetToken, targetAmount, "CloseLongLeverage");
        emit CloseLongLeverage(
            EOA,
            account,
            depositToken,
            depositAmount,
            targetToken,
            targetAmount,
            flashLoanAmount
        );
    }

    function emitCloseShortLeverageEvent(
        address depositToken,
        uint256 depositAmount,
        address targetToken,
        uint256 targetAmount,
        uint256 flashLoanAmount
    ) external onlyAccount {
        address EOA = AccountIndexInterface(accountIndex).getEOA(msg.sender);
        address account = msg.sender;
        subScore(EOA, account, targetToken, targetAmount, "CloseShortLeverage");
        emit CloseShortLeverage(
            EOA,
            account,
            depositToken,
            depositAmount,
            targetToken,
            targetAmount,
            flashLoanAmount
        );
    }

    function emitAddMarginEvent(address depositToken, uint256 depositAmount)
        external
        onlyAccount
    {
        address EOA = AccountIndexInterface(accountIndex).getEOA(msg.sender);
        address account = msg.sender;
        emit AddMargin(EOA, account, depositToken, depositAmount);
    }

    function addScore(
        address EOA,
        address account,
        address _token,
        uint256 _amount,
        string memory _reason
    ) internal {
        uint256 timeToEpochEnd;
        uint256 tokenWeight;
        uint256 postionScore;
        bool overflow;

        (overflow, timeToEpochEnd) = SafeMath.trySub(epochEnd, block.timestamp);
        if(overflow == true){
            timeToEpochEnd = 0;
        }
        // tokenWeight = weight[_token];
        // (overflow, postionScore) = SafeMath.tryMul(timeToEpochEnd, _amount);
        // require(overflow == false, "CHFRY: You are so rich!");
        // (overflow, postionScore) = SafeMath.tryMul(postionScore, tokenWeight);
        // require(overflow == false, "CHFRY: You are so rich!");

        emit AddScore(
            EOA,
            account,
            _token,
            _amount,
            tokenWeight,
            timeToEpochEnd,
            _reason
        );
    }

    function subScore(
        address EOA,
        address account,
        address _token,
        uint256 _amount,
        string memory _reason
    ) internal {
        uint256 timeToEpochEnd;
        uint256 tokenWeight;
        uint256 postionScore;
        bool overflow;

        (overflow, timeToEpochEnd) = SafeMath.trySub(epochEnd, block.timestamp);
        if(overflow == true){
            timeToEpochEnd = 0;
        }
        tokenWeight = weight[_token];
        (overflow, postionScore) = SafeMath.tryMul(timeToEpochEnd, _amount);
        require(overflow == false, "CHFRY: You are so rich!");
        (overflow, postionScore) = SafeMath.tryMul(postionScore, tokenWeight);
        require(overflow == false, "CHFRY: You are so rich!");

        emit SubScore(
            EOA,
            account,
            _token,
            _amount,
            tokenWeight,
            postionScore,
            _reason
        );
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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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