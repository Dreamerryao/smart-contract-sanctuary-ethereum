// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

contract OrderController is Ownable, ReentrancyGuard {
    struct Order {
        uint256 id;
        uint256 amountA;
        uint256 amountB;
        uint256 amountLeftToFill;
        uint256 fees;
        address tokenA;
        address tokenB;
        address user;
        bool isCancelled;
    }

    uint256 internal _nextOrderId; // next order id
    uint256 public feeRate; // fee rate
    mapping(uint256 => Order) internal _orders;
    mapping(address => uint256) internal _feeBalances;
    mapping(address => uint256[]) internal _userOrderIds;
    uint256[] internal _orderIds;

    uint256 private constant TEN_THOUSAND = 10000;

    event OrderCreated(
        uint256 id,
        uint256 amountA,
        uint256 amountB,
        address tokenA,
        address tokenB,
        address user,
        bool isMarket
    );

    event OrderMatched(
        uint256 id,
        uint256 matchedId, // 0 for initiator
        uint256 amountReceived, // received amount, need to deduct fee
        uint256 amountPaid, // paid amount, need to deduct fee
        uint256 amountLeftToFill,
        uint256 fee,
        uint256 feeRate // current fee rate, it can be changed
    );

    event FeeRateChanged(uint256 oldFeeRate, uint256 newFeeRate);

    event OrderCancelled(uint256 id);

    constructor(uint256 fee) {
        require(fee < TEN_THOUSAND, "OC:BAD_FEE");
        feeRate = fee;
        _nextOrderId = 0;
    }

    function getOrderIdLength() external view returns (uint256) {
        return _orderIds.length;
    }

    function getOrderId(uint256 index) external view returns (uint256) {
        return _orderIds[index];
    }

    function getUserOrderIdsLength() external view returns (uint256) {
        return _userOrderIds[_msgSender()].length;
    }

    function getUserOrderIds(uint256 from, uint256 length)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory userOrderIds = _userOrderIds[_msgSender()];
        if (_userOrderIds[_msgSender()].length > 1000) {
            uint256 cnt;
            uint256 limit = from + length >= userOrderIds.length
                ? userOrderIds.length
                : from + length;
            uint256[] memory paginatedArray = new uint256[](limit - from);
            for (uint256 i = from; i < limit; i++) {
                paginatedArray[cnt++] = userOrderIds[i];
            }
            return paginatedArray;
        }
        return userOrderIds;
    }

    function getOrderInfo(uint256 _id)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            address,
            address,
            bool
        )
    {
        Order memory order = _orders[_id];
        return (
            order.id,
            order.amountA,
            order.amountB,
            order.amountLeftToFill,
            order.fees,
            order.tokenA,
            order.tokenB,
            order.user,
            order.isCancelled
        );
    }

    function getAccumulatedFeeBalance(address token) external view onlyOwner returns (uint256) {
        return _feeBalances[token];
    }

    function cancelOrder(uint256 id) external {
        Order storage order = _orders[id];
        require(_msgSender() == order.user, "OC:NOT_AUTHORIZED");
        require(!order.isCancelled, "OC:ALREADY_CANCELED");
        order.isCancelled = true;
        uint256 transferAmount = (order.amountB * order.amountLeftToFill) / order.amountA;
        TransferHelper.safeTransfer(order.tokenB, order.user, transferAmount);
        emit OrderCancelled(order.id);
    }

    function setFee(uint256 newFeeRate) external onlyOwner {
        require(newFeeRate != feeRate, "OC:OLD_FEE_VALUE");
        emit FeeRateChanged(feeRate, newFeeRate);
        feeRate = newFeeRate;
    }

    function withdrawFee(address token) external onlyOwner {
        TransferHelper.safeTransfer(token, _msgSender(), _feeBalances[token]);
        _feeBalances[token] = 0;
    }

    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        return a < b ? a : b;
    }

    function matchOrders(
        uint256[] calldata matchedOrderIds,
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        bool isMarket
    ) external nonReentrant {
        uint256 totalPayout;
        uint256 totalPaid;
        uint256 id = _generateOrderId(tokenA, tokenB, amountA, amountB, _msgSender(), isMarket);
        Order storage newOrder = _orders[id];

        for (uint256 i = 0; i < matchedOrderIds.length; i++) {
            if (newOrder.amountLeftToFill == 0 || totalPaid >= amountB) {
                break;
            }

            Order storage matchedOrder = _orders[matchedOrderIds[i]];

            if (matchedOrder.id != matchedOrderIds[i]) {
                continue; // ignore incorrect ids
            }
            uint256 matchedOrderAmountB = matchedOrder.amountB;
            uint256 matchedOrderAmountA = matchedOrder.amountA;
            uint256 matchedOrderAmountLeftToFill = matchedOrder.amountLeftToFill;

            require(
                matchedOrder.tokenB == tokenA && matchedOrder.tokenA == tokenB,
                "OC:BAD_TOKEN_MATCH"
            );

            if (!isMarket) {
                require(
                    amountA * matchedOrderAmountA <= amountB * matchedOrderAmountB,
                    "OC:BAD_PRICE_MATCH"
                );
            }

            if (matchedOrderAmountLeftToFill == 0 || matchedOrder.isCancelled) {
                continue;
            }

            uint256 matchedReceived;

            if (
                newOrder.amountLeftToFill * matchedOrderAmountA >=
                matchedOrderAmountLeftToFill * matchedOrderAmountB
            ) {
                // Alf >= mAlf * mB/mA => we can take all mAlf and Alf will still not be filled
                // calculate delta B max
                matchedReceived = min(matchedOrderAmountLeftToFill, amountB - totalPaid);
                matchedOrder.fees += _getFee(matchedReceived);

                uint256 transferAmountA = (matchedReceived * matchedOrderAmountB) / matchedOrderAmountA;
                totalPayout += transferAmountA;

                newOrder.amountLeftToFill -= transferAmountA;
                matchedOrder.amountLeftToFill -= matchedReceived;
            } else {
                // we can take all Alf and matched order will still not be closed
                // calculate delta B max
                uint256 transferAmountB =
                min(
                    amountB - totalPaid,
                    (newOrder.amountLeftToFill * matchedOrderAmountA) / matchedOrderAmountB
                );
                uint256 amountFilled = transferAmountB * matchedOrderAmountB / matchedOrderAmountA;
                matchedOrder.fees += _getFee(transferAmountB);

                totalPayout += amountFilled;
                matchedReceived = transferAmountB;

                newOrder.amountLeftToFill -= amountFilled;
                matchedOrder.amountLeftToFill -= transferAmountB;
            }

            TransferHelper.safeTransferFrom(
                tokenB,
                _msgSender(),
                matchedOrder.user,
                _subFee(matchedReceived)
            );
            totalPaid += matchedReceived;

            emit OrderMatched(
                matchedOrder.id,
                id,
                matchedReceived,
                0, // amount was paid previously
                matchedOrder.amountLeftToFill,
                matchedOrder.fees,
                feeRate
            );
        }

        // TODO: try to enhance
        if (newOrder.amountLeftToFill > 0) {
            // consider adding threshold amount to config
            if (isMarket) {
                // effectively close the order
                newOrder.amountLeftToFill = 0;
            } else {
                // let order stay, transfer remaining amount to contract
                // thereby legitimating the order
                uint256 transferAmount = (newOrder.amountLeftToFill * amountB) / amountA;
                TransferHelper.safeTransferFrom(
                    tokenB,
                    _msgSender(),
                    address(this),
                    transferAmount
                );
            }
        }

        TransferHelper.safeTransfer(tokenA, _msgSender(), _subFee(totalPayout));
        uint256 totalFeeA = _getFee(totalPayout);
        uint256 totalFeeB = _getFee(totalPaid);
        TransferHelper.safeTransferFrom(tokenB, _msgSender(), address(this), totalFeeB);

        _feeBalances[tokenA] = _feeBalances[tokenA] + totalFeeA;
        _feeBalances[tokenB] = _feeBalances[tokenB] + totalFeeB;

        newOrder.fees = newOrder.fees + totalFeeA;

        emit OrderMatched(
            id,
            0, // order owner is initiator
            totalPayout, // received amount
            totalPaid, // paid amount
            newOrder.amountLeftToFill,
            newOrder.fees,
            feeRate
        );
    }

    function createOrder(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    ) external nonReentrant {
        _createOrder(tokenA, tokenB, amountA, amountB, _msgSender(), false);
    }

    function _getFee(uint256 amount) private view returns (uint256 retAmount) {
        retAmount = (amount * feeRate) / TEN_THOUSAND;
    }

    function _subFee(uint256 amount) private view returns (uint256 retAmount) {
        retAmount = amount - _getFee(amount);
    }

    function _generateOrderId(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        address user,
        bool isMarket
    ) private returns (uint256) {
        require(tokenA != address(0) && tokenB != address(0), "OC:ZERO_ADDRESS");
        require(tokenA != tokenB, "OC:BAD_PAIR");
        require(amountA > 0 && amountB > 0, "OC:BAD_AMOUNT");

        uint256 id = uint256(keccak256(abi.encodePacked(block.timestamp, user, _nextOrderId++)));
        _orders[id] = Order(id, amountA, amountB, amountA, 0, tokenA, tokenB, user, false);
        _orderIds.push(id);
        _userOrderIds[user].push(id);
        emit OrderCreated(id, amountA, amountB, tokenA, tokenB, user, isMarket);
        return id;
    }

    function _createOrder(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        address user,
        bool isMarket
    ) private {
        _generateOrderId(tokenA, tokenB, amountA, amountB, user, isMarket);
        TransferHelper.safeTransferFrom(tokenB, user, address(this), amountB);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
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