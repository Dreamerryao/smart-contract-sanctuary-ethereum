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
pragma solidity ^0.8.2;

interface IMint {
    function mint(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ICurveCrvCvxCrvPool {
  function add_liquidity(
    uint256[2] memory _amounts,
    uint256 _min_mint_amount
  ) external returns(uint256);

  function coins(
    uint256 index
  ) external view returns(address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IMint.sol";
import "../interfaces/curve/ICurveCrvCvxCrvPool.sol";

contract MockCurvePoolCvxCrvCrv is ICurveCrvCvxCrvPool {

    address[2] private _coins;
    address public lpToken;

    constructor(
        address _crv,
        address _cvxCrv,
        address _lpToken
    ) {
        lpToken = _lpToken;
        _coins[0] = _crv;
        _coins[1] = _cvxCrv;
    }

    function add_liquidity(
    uint256[2] memory _amounts,
    uint256 _min_mint_amount
  ) external override returns(uint256) {
    if (_amounts[0] > 0) IERC20(_coins[0]).transferFrom(msg.sender, address(this), _amounts[0]);
    if (_amounts[1] > 0) IERC20(_coins[1]).transferFrom(msg.sender, address(this), _amounts[1]);
    IMint(lpToken).mint(msg.sender, _amounts[0] + _amounts[1]);
  }

  function coins(
    uint256 index
  ) external view returns(address) {
    return _coins[index];
  }

}