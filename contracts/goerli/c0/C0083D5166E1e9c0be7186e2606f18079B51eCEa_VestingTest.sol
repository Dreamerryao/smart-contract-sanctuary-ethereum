// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VestingTest is Ownable {
    event Vest(
        address indexed to,
        uint256 amount,
        uint256 start,
        uint256 cliff,
        uint256 vesting
    );
    event Claim(address indexed claimer, uint256 index, uint256 amount);

    struct Schedule {
        // total amount locked
        uint256 amount;
        // total claimed
        uint256 claimed;
        // timestamp when this schedule was created
        uint256 start;
        // timestamp when cliff ends
        uint256 cliff;
        // timestamp when vesting ends
        uint256 end;
    }

    // Interval before claimable amount increases
    uint256 private constant INTERVAL = 600;

    // TODO: finalize max duration
    // Maximum duration (start + vest)
    uint256 private MAX_DURATION = 5 * 365 days;

    IERC20 public immutable breeder;

    // user => Schedule[]
    mapping(address => Schedule[]) public schedules;
    // total amount locked in this contract
    uint256 public totalLocked;

    constructor(address _breeder) {
        require(_breeder != address(0), "invalid breeder address");
        breeder = IERC20(_breeder);
    }

    function _vest(
        address account,
        uint256 amount,
        uint256 start,
        uint256 cliff,
        uint256 vesting
    ) private {
        require(account != address(0), "account = zero address");
        require(amount > 0, "amount = 0");
        require(start >= block.timestamp, "start < timestamp");
        require(vesting > 0 && vesting >= cliff, "invalid vesting");
        // NOTE: start + cliff <= start + vesting
        require(
            start + vesting <= block.timestamp + MAX_DURATION,
            "duration > max"
        );

        totalLocked += amount;
        require(
            breeder.balanceOf(address(this)) >= totalLocked,
            "balance < locked + amount"
        );

        schedules[account].push(
            Schedule({
                amount: amount,
                claimed: 0,
                start: start,
                cliff: start + cliff,
                end: start + vesting
            })
        );

        emit Vest(account, amount, start, cliff, vesting);
    }

    /**
     * @notice Sets up a vesting schedule for a set user.
     * @param account account that a vesting schedule is being set up for.
     *        Will be able to claim tokens after the cliff period.
     * @param amount amount of tokens being vested for the user.
     * @param start timestamp for when this vesting should have started
     * @param cliff seconds that the cliff will be present for.
     * @param vesting seconds the tokens will vest over (linearly)
     */
    function vest(
        address account,
        uint256 amount,
        uint256 start,
        uint256 cliff,
        uint256 vesting
    ) external onlyOwner {
        _vest(account, amount, start, cliff, vesting);
    }

    /**
     * @notice Returns schedule count
     * @param account account
     */
    function getScheduleCount(address account) external view returns (uint256) {
        return schedules[account].length;
    }

    /**
     * @notice Sets up vesting schedules for multiple users within 1 transaction.
     * @param accounts an array of the accounts that the vesting schedules are being set up for.
     *                 Will be able to claim tokens after the cliff period.
     * @param amounts an array of the amount of tokens being vested for each user.
     * @param start the timestamp for when this vesting should have started
     * @param cliff the number of seconds that the cliff will be present at.
     * @param vesting the number of seconds the tokens will vest over (linearly)
     */
    function multiVest(
        address[] calldata accounts,
        uint256[] calldata amounts,
        uint256 start,
        uint256 cliff,
        uint256 vesting
    ) external onlyOwner {
        require(accounts.length == amounts.length, "array length");

        for (uint256 i; i < accounts.length; i++) {
            _vest(accounts[i], amounts[i], start, cliff, vesting);
        }
    }

    /**
     * @return Calculates the amount of tokens to distribute to an account at
     *         any instance in time.
     * @param amount amount vested
     * @param claimed amount claimed
     * @param start timestamp
     * @param cliff timestamp
     * @param end timestamp
     * @param timestamp current timestamp
     */
    function calculateClaimableAmount(
        uint256 amount,
        uint256 claimed,
        uint256 start,
        uint256 cliff,
        uint256 end,
        uint256 timestamp
    ) public pure returns (uint256) {
        // return 0 if not vested
        if (amount == 0) {
            return 0;
        }

        // time < cliff
        if (timestamp < cliff) {
            return 0;
        }

        // time >= end
        if (timestamp >= end) {
            return amount - claimed;
        }

        // claimed >= amount
        if (claimed >= amount) {
            return 0;
        }

        // cliff <= time < end
        /*
        y = amount claimable, assuming claimed amount = 0
        t = block.timestamp
        y0 = claimable at cliff
           = amount * (cliff - start) / (end - start)
        s = step function for each month after cliff
           = floor((t - cliff) / interval)
        dy for each month
           = amount * interval / (end - start)
        y1 = claimable each month after cliff
           = dy * s
        y = y0 + y1
          = amount * ((cliff - start) + interval * floor((t - cliff) / interval)) / (end - start)
        */
        uint256 y = (amount *
            ((cliff - start) + INTERVAL * ((timestamp - cliff) / INTERVAL))) /
            (end - start);
        return y - claimed;
    }

    /**
     * @notice allows users to claim vested tokens if the cliff time has passed.
     * @param index which schedule the user is claiming against
     */
    function claim(uint256 index) external {
        Schedule storage schedule = schedules[msg.sender][index];

        uint256 amount = calculateClaimableAmount(
            schedule.amount,
            schedule.claimed,
            schedule.start,
            schedule.cliff,
            schedule.end,
            block.timestamp
        );
        require(amount > 0, "claimable amount = 0");

        schedule.claimed += amount;

        totalLocked -= amount;
        breeder.transfer(msg.sender, amount);

        emit Claim(msg.sender, index, amount);
    }

    /**
     * @notice get total currently claimable with inputs address and index
     * @param  claimer address of vester
     * @param index which schedule the user is claiming against
     */
    function getClaimableAmount(address claimer, uint256 index)
        external
        view
        returns (uint256)
    {
        Schedule memory schedule = schedules[claimer][index];

        return
            calculateClaimableAmount(
                schedule.amount,
                schedule.claimed,
                schedule.start,
                schedule.cliff,
                schedule.end,
                block.timestamp
            );
    }

    /**
     * @notice get total claimable at given timestamp with inputs address and index
     * @param  claimer address of vester
     * @param index which schedule the user is claiming against
     * @param timestamp timestamp
     */
    function getClaimableAmountByTimestamp(
        address claimer,
        uint256 index,
        uint256 timestamp
    ) external view returns (uint256) {
        Schedule memory schedule = schedules[claimer][index];

        return
            calculateClaimableAmount(
                schedule.amount,
                schedule.claimed,
                schedule.start,
                schedule.cliff,
                schedule.end,
                timestamp
            );
    }

    /**
     * @notice Withdraws excess BREED tokens from the contract.
     * @param amount Amount of excess Breed to withdraw
     */
    function withdraw(uint256 amount) external onlyOwner {
        require(
            breeder.balanceOf(address(this)) - totalLocked >= amount,
            "amount > excess"
        );
        breeder.transfer(owner(), amount);
    }

    /**
     * @notice Withdraw accidentally sent token
     * @param  token address of token
     * @param  amount amount to withdraw
     */
    function recover(address token, uint256 amount) external onlyOwner {
        require(token != address(breeder), "protected");
        IERC20(token).transfer(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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