// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

import "./libraries/SafeERC20.sol";
import "./libraries/SafeMath.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IDistributor.sol";

import "./types/AstralAccessControlled.sol";

contract Distributor is IDistributor, AstralAccessControlled {

	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	IERC20    private immutable strl;
	ITreasury private immutable treasury;
	address   private immutable staking;

	mapping(uint256 => Adjust) public adjustments;
	uint256 public override bounty;

	uint256 private immutable rateDenominator = 1_000_000;

	Info[] public info;

	constructor(
		address _treasury,
		address _strl,
		address _staking,
		address _authority
	) AstralAccessControlled(IAstralAuthority(_authority)) {
		require(_treasury != address(0), "Zero address: Treasury");
		require(_strl     != address(0), "Zero address: STRL");
		require(_staking  != address(0), "Zero address: Staking");

		treasury = ITreasury(_treasury);
		strl     = IERC20(_strl);
		staking  = _staking;
	}

	// send epoch reward to staking contract
	function distribute() external override {
		require(msg.sender == staking, "Only Staking");
		// distribute rewards to each recipient
		for (uint256 i = 0; i < info.length; i++) {
			if (info[i].rate > 0) {
				// mint and send tokens
				treasury.mint(info[i].recipient, nextRewardAt(info[i].rate));
				// check for adjustment
				adjust(i);
			}
		}
	}

	function retrieveBounty() external override returns (uint256) {
		require(msg.sender == staking, "Only Staking");
		// If the distributor bounty is > 0, mint it for the staking contract
		if (bounty > 0) {
			treasury.mint(address(staking), bounty);
		}

		return bounty;
	}

	// increment reward rate for collector
	function adjust(uint256 _index) internal {
		Adjust memory adjustment = adjustments[_index];
		if (adjustment.rate != 0) {
			if (adjustment.add) {
				// if rate should increase
				info[_index].rate = info[_index].rate.add(adjustment.rate); // raise rate
				if (info[_index].rate >= adjustment.target) {
					// if target met
					adjustments[_index].rate = 0; // turn off adjustment
					info[_index].rate = adjustment.target; // set to target
				}
			} else {
				// if rate should decrease
				if (info[_index].rate > adjustment.rate) {
					// protect from underflow
					info[_index].rate = info[_index].rate.sub(adjustment.rate); // lower rate
				} else {
					info[_index].rate = 0;
				}

				if (info[_index].rate <= adjustment.target) {
					// if target met
					adjustments[_index].rate = 0; // turn off adjustment
					info[_index].rate = adjustment.target; // set to target
				}
			}
		}
	}

	// view for next reward at given rate
	function nextRewardAt(uint256 _rate) public view override returns (uint256) {
		return strl.totalSupply().mul(_rate).div(rateDenominator);
	}

	// view for next reward for specified address
	function nextRewardFor(address _recipient) public view override returns (uint256) {
		uint256 reward;
		for (uint256 i = 0; i < info.length; i++) {
			if (info[i].recipient == _recipient) {
				reward = reward.add(nextRewardAt(info[i].rate));
			}
		}
		return reward;
	}

	// set bounty to incentivize keepers
	function setBounty(uint256 _bounty) external override onlyGovernor {
		require(_bounty <= 2e9, "Too much");
		bounty = _bounty;
	}

	// adds recipient for distributions
	function addRecipient(
		address _recipient, 
		uint256 _rewardRate
	) external override onlyGovernor {
		require(_recipient != address(0), "Zero address: Recipient");
		require(_rewardRate <= rateDenominator, "Rate cannot exceed denominator");
		info.push(Info({
			recipient: _recipient,
			rate: _rewardRate
		}));
	}

	// removes recipient for distributions
	function removeRecipient(uint256 _index) external override {
		require(
			msg.sender == authority.governor() || msg.sender == authority.guardian(),
			"Caller is not governor or guardian"
		);
		require(info[_index].recipient != address(0), "Recipient does not exists");
		info[_index].recipient = address(0);
		info[_index].rate = 0;
	}

	// set adjustment info for a collector reward rate
	function setAdjustment(
		uint256 _index,
		bool _add,
		uint256 _rate,
		uint256 _target
	) external override {
		require(
			msg.sender == authority.governor() || msg.sender == authority.guardian(),
			"Caller is not governor or guardian"
		);
		require(info[_index].recipient != address(0), "Recipient does not exists");

		if (msg.sender == authority.guardian()) {
			require(_rate <= info[_index].rate.mul(25).div(1000), "Limiter: cannot adjust by >2,5%");
		}

		if (!_add) {
			require(_rate <= info[_index].rate, "Cannot decrease rate by more than it already is");
		}

		adjustments[_index] = Adjust({
			add: _add,
			rate: _rate,
			target: _target
		});
	}
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.7.5;

import "../interfaces/IAstralAuthority.sol";

abstract contract AstralAccessControlled {

    event AuthorityUpdated(IAstralAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    IAstralAuthority public authority;

    constructor(IAstralAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    function setAuthority(IAstralAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

	function average(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(add((a & b), (a ^ b)), 2);
	}

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b != 0);
		return a % b;
	}
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.7.5;

import "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

interface ITreasury {
	event Deposit(address indexed token, uint256 amount, uint256 value);
    event Withdraw(address indexed token, uint256 amount, uint256 value);
    event CreateDebt(
        address indexed debtor,
        address indexed token,
        uint256 amount,
        uint256 value
    );
    event RepayDebt(
        address indexed debtor,
        address indexed token,
        uint256 amount,
        uint256 value
    );
    event Managed(address indexed token, uint256 amount);
    event ReservesAudited(uint256 indexed totalReserves);
    event Minted(address indexed caller, address indexed recipient, uint256 amount);
    event PermissionQueued(STATUS indexed status, address queued);
    event Permissioned(address addr, STATUS indexed status, bool result);

	enum STATUS {
        RESERVEDEPOSITOR,
        RESERVESPENDER,
        RESERVETOKEN,
        RESERVEMANAGER,
        LIQUIDITYDEPOSITOR,
        LIQUIDITYTOKEN,
        LIQUIDITYMANAGER,
        RESERVEDEBTOR,
        REWARDMANAGER,
        SSTRL,
        STRLDEBTOR
    }

    struct Queue {
        STATUS managing;
        address toPermit;
        address calculator;
        uint256 timelockEnd;
        bool nullify;
        bool executed;
    }

	function deposit(
		uint256 amount_,
		address token_,
		uint256 profit_
	) external returns (uint256);

	function withdraw(uint256 amount_, address token_) external;

	function tokenValue(address token_, uint256 amount_) external view returns (uint256 value_);

	function mint(address recipient, uint256 amount) external;

	function manage(address token_, uint256 amount_) external;

	function incurDebt(uint256 amount_, address token_) external;

	function repayDebtWithReserve(uint256 amount_, address token_) external;

	function excessReserves() external view returns (uint256);

	function baseSupply() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

interface IERC20 {
	/**
	 * @dev Returns the amount of tokens in existance.
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
	 * condition is to first reduce the spender's allowanceto 0 and set the 
	 * desired value afterwards:
	 * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
	 *
	 * Emits an {Approval} event.
	 */
	function approve(address spender, uint256 amount) external returns (bool);

	/**
	 * @dev Moves `amount` tokens from `spender` to `recipient` using the 
	 * allowance mechanism. `amount` is then deducated from the caller's 
	 * allowance.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */
	function transferFrom(address spender, address recipient, uint256 amount) external returns (bool);

	/**
	 * @dev Emitted when `value` tokens are moved from one account (`from`) to
	 * another (`to`).
	 *
	 * Note that `value` may be zero.
	 */
	event Transfer(address indexed, address indexed to, uint256 value);

	/**
	 * @dev Emitted when the allowance of `spender` for an `owner` is set by
	 * a call to {approve}. `value` is the allowance.
	 */
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

interface IDistributor {
	struct Info {
        uint256 rate; // in ten-thousands (5000 = 0.5%)
        address recipient;
    }

	struct Adjust {
        bool add;
        uint256 rate;
        uint256 target;
    }

    function distribute() external;

    function bounty() external view returns (uint256);

    function retrieveBounty() external returns (uint256);

    function nextRewardAt(uint256 _rate) external view returns (uint256);

    function nextRewardFor(address _recipient) external view returns (uint256);

    function setBounty(uint256 _bounty) external;

    function addRecipient(address _recipient, uint256 _rewardRate) external;

    function removeRecipient(uint256 _index) external;

    function setAdjustment(
        uint256 _index,
        bool _add,
        uint256 _rate,
        uint256 _target
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

interface IAstralAuthority {
    
	event GovernorPushed(
		address indexed from, 
		address indexed to, 
		bool _effectiveImmediately
	);
    
	event GuardianPushed(
		address indexed from, 
		address indexed to, 
		bool _effectiveImmediately
	);
    
	event PolicyPushed(
		address indexed from, 
		address indexed to, 
		bool _effectiveImmediately
	);
    
	event VaultPushed(
		address indexed from, 
		address indexed to, 
		bool _effectiveImmediately
	);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    function governor() external view returns (address);
    function guardian() external view returns (address);
    function policy() external view returns (address);
    function vault() external view returns (address);
}