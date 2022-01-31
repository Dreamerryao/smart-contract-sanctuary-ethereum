// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { Whitelist } from "./Whitelist.sol";

contract Launchpad is Pausable, Ownable, Whitelist {
  using SafeMath for uint256;
  uint256 public increment = 0;

  mapping(uint256 => Purchase) public purchases;
  address[] public investors;
  uint256[] public purchaseIndexes;
  mapping(address => uint256[]) public investorPurchases;

  ERC20 public token;
  uint256 public tokenDecimals;

  bool public isSaleFunded; // contract is funded for sale
  bool public unsoldTokensRedeemed = false;

  uint256 public saleTokenInitialRate;
  uint256 public startDate;
  uint256 public endDate;

  uint256 public firstUnlockDate;
  uint256 public secondUnlockDate;

  uint256 public investorMinimumAmount = 0;
  uint256 public investorMaximumAmount = 0;

  uint256 public minimumRaise = 0;
  uint256 public tokensAllocated = 0;
  uint256 public totalTokensForSale = 0;

  struct Purchase {
    uint256 amount;
    uint256 remainingAmount;
    address investor;
    uint256 avaxAmount;
    uint256 timestamp;
    bool isRedeemed;
    string tier;
  }

  event onPurchase(
    uint256 _amount,
    address indexed _investor,
    uint256 timestamp
  );

  constructor(
    address _token,
    uint256 _saleTokenInitialRate,
    uint256 _totalTokensForSale,
    uint256 _startDate,
    uint256 _endDate,
    uint256 _investorMinimumAmount,
    uint256 _investorMaximumAmount,
    uint256 _minimumRaise,
    bool _hasWhitelisting
  ) public Whitelist(_hasWhitelisting, _token) {
    require(_startDate < _endDate, "End Date higher than Start Date");
    require(_totalTokensForSale > 0, "Tokens for Sale should be > 0");
    require(
      _totalTokensForSale > _investorMinimumAmount,
      "Tokens for Sale should be > Investor minimum Amount"
    );
    require(
      _investorMaximumAmount >= _investorMinimumAmount,
      "Investor maximim amount should be > Investor minimum Amount"
    );
    require(
      _minimumRaise <= _totalTokensForSale,
      "Minimum Raise should be < Tokens For Sale"
    );

    startDate = _startDate;
    endDate = _endDate;
    totalTokensForSale = _totalTokensForSale;
    saleTokenInitialRate = _saleTokenInitialRate;

    investorMaximumAmount = _investorMaximumAmount;
    investorMinimumAmount = _investorMinimumAmount;

    minimumRaise = _minimumRaise;
    token = ERC20(_token);
  }

  /**
   * Modifiers
   */

  modifier isSaleEnded() {
    require(hasEnded(), "Has to be ended");
    _;
  }

  modifier isSaleOpen() {
    require(isOpen(), "Has to be open");
    _;
  }

  modifier isSalePreStarted() {
    require(isPreStart(), "Has to be pre-started");
    _;
  }

  modifier isFunded() {
    require(isSaleFunded, "Has to be funded");
    _;
  }

  /**
   * Getters
   */

  function isBuyer(uint256 purchaseIndex) public view returns (bool) {
    return (msg.sender == purchases[purchaseIndex].investor);
  }

  /* Get Functions */
  function totalRaiseCost() public view returns (uint256) {
    return (cost(totalTokensForSale));
  }

  function availableTokens() public view returns (uint256) {
    return token.balanceOf(address(this));
  }

  function tokensLeft() public view returns (uint256) {
    return totalTokensForSale - tokensAllocated;
  }

  function hasMinimumRaise() public view returns (bool) {
    return (minimumRaise != 0);
  }

  /* Verify if minimum raise was not achieved */
  function minimumRaiseNotAchieved() public view returns (bool) {
    require(
      cost(tokensAllocated) < cost(minimumRaise),
      "TotalRaise is bigger than minimum raise amount"
    );
    return true;
  }

  /* Verify if minimum raise was achieved */
  function minimumRaiseAchieved() public view returns (bool) {
    if (hasMinimumRaise()) {
      require(
        cost(tokensAllocated) >= cost(minimumRaise),
        "TotalRaise is less than minimum raise amount"
      );
    }
    return true;
  }

  function hasEnded() public view returns (bool) {
    return block.timestamp > endDate;
  }

  function hasStarted() public view returns (bool) {
    return block.timestamp >= startDate;
  }

  function isPreStart() public view returns (bool) {
    return block.timestamp < startDate;
  }

  function isOpen() public view returns (bool) {
    return hasStarted() && !hasEnded();
  }

  function hasMinimumAmount() public view returns (bool) {
    return (investorMinimumAmount != 0);
  }

  function cost(uint256 _amount) public view returns (uint256) {
    return _amount.mul(saleTokenInitialRate).div(10**tokenDecimals);
  }

  function getPurchase(uint256 _purchaseIndex)
    external
    view
    returns (
      uint256,
      address,
      uint256,
      uint256,
      bool,
      string memory
    )
  {
    Purchase memory purchase = purchases[_purchaseIndex];
    return (
      purchase.amount,
      purchase.investor,
      purchase.remainingAmount,
      purchase.timestamp,
      purchase.isRedeemed,
      purchase.tier
    );
  }

  function getPurchaseIndexes() public view returns (uint256[] memory) {
    return purchaseIndexes;
  }

  function getInvestors() public view returns (address[] memory) {
    return investors;
  }

  function getMyPurchases(address _address)
    public
    view
    returns (uint256[] memory)
  {
    return investorPurchases[_address];
  }

  function fund(uint256 _amount) public onlyOwner isSalePreStarted {
    /* Confirm transfered tokens is no more than needed */
    require(
      availableTokens().add(_amount) <= totalTokensForSale,
      "Transfered tokens have to be equal or less than proposed"
    );

    /* Transfer Funds */
    require(
      token.transferFrom(msg.sender, address(this), _amount),
      "Failed ERC20 token transfer"
    );

    /* If Amount is equal to needed - sale is ready */
    if (availableTokens() == totalTokensForSale) {
      isSaleFunded = true;
    }
  }

  function getLocked(uint256 purchaseIndex) public view returns (uint256) {
    if (block.timestamp > secondUnlockDate) {
      return 0;
    }

    if (block.timestamp > firstUnlockDate) {
      return (purchases[purchaseIndex].amount * 3) / 10;
    }

    if (block.timestamp > endDate) {
      return (purchases[purchaseIndex].amount * 6) / 10;
    }

    return purchases[purchaseIndex].amount;
  }

  function invest(uint256 _amount)
    external
    payable
    whenNotPaused
    isFunded
    isSaleOpen
  {
    /* Confirm Amount is positive */
    require(_amount > 0, "Amount has to be positive");

    /* Confirm Amount is less than tokens available */
    require(_amount <= tokensLeft(), "Amount is less than tokens available");

    /* Confirm the user has funds for the transfer, confirm the value is equal */
    require(
      msg.value == cost(_amount),
      "User has to cover the cost of the swap in ETH, use the cost function to determine"
    );

    /* Confirm Amount is bigger than minimum Amount */
    require(
      _amount >= investorMinimumAmount,
      "Amount is bigger than minimum amount"
    );

    /* Confirm Amount is smaller than maximum Amount */
    require(
      _amount <= investorMaximumAmount,
      "Amount is smaller than maximum amount"
    );

    uint256 totalAmount = calculateAmount(msg.sender, totalTokensForSale);

    WhitelistStruct memory _whitelist = whitelistedParticipants[msg.sender];
    /* Verify all user purchases, loop thru them */
    uint256[] memory _purchases = getMyPurchases(msg.sender);
    uint256 purchaserTotalAmountPurchased = 0;
    for (uint256 i = 0; i < _purchases.length; i++) {
      Purchase memory _purchase = purchases[_purchases[i]];
      purchaserTotalAmountPurchased = purchaserTotalAmountPurchased.add(
        _purchase.amount
      );
    }
    require(
      purchaserTotalAmountPurchased.add(totalAmount) <= investorMaximumAmount,
      "Address has already passed the max amount of swap"
    );

    /* Confirm transfer */
    require(
      token.transfer(msg.sender, totalAmount),
      "ERC20 transfer didn´t work"
    );

    uint256 _purchaseIndex = increment;
    increment = increment.add(1);

    /* Create new purchase */
    Purchase memory purchase = Purchase(
      totalAmount,
      totalAmount,
      msg.sender,
      msg.value,
      block.timestamp,
      false,
      _whitelist.tier
    );
    purchases[_purchaseIndex] = purchase;
    purchaseIndexes.push(_purchaseIndex);
    investorPurchases[msg.sender].push(_purchaseIndex);
    investors.push(msg.sender);
    tokensAllocated = tokensAllocated.add(totalAmount);
    emit onPurchase(totalAmount, msg.sender, block.timestamp);
  }

  function redeemTokens(uint256 _purchaseIndex)
    external
    isSaleEnded
    whenNotPaused
  {
    /* Confirm it exists and was not finalized */
    require(
      (purchases[_purchaseIndex].amount != 0) &&
        !purchases[_purchaseIndex].isRedeemed,
      "Purchase is either 0 or redeemed"
    );
    require(isBuyer(_purchaseIndex), "Address is not buyer");

    uint256 unlockedAmount = purchases[_purchaseIndex].amount.sub(
      getLocked(_purchaseIndex)
    );
    uint256 claimed = purchases[_purchaseIndex].amount.sub(
      purchases[_purchaseIndex].remainingAmount
    );
    uint256 claimable = unlockedAmount - claimed;

    require(claimable > 0, "To claim must be more than 0");

    purchases[_purchaseIndex].remainingAmount =
      purchases[_purchaseIndex].remainingAmount -
      claimable;
    if (purchases[_purchaseIndex].remainingAmount == 0) {
      purchases[_purchaseIndex].isRedeemed = true;
    }
    require(token.transfer(msg.sender, claimable), "ERC20 transfer failed");
  }

  /**
   * Admin functions
   */

  function setUnlockDates(
    uint256 _startDate,
    uint256 _endDate,
    uint256 _firstUnlockDate,
    uint256 _secondUnlockDate
  ) public onlyOwner {
    require(firstUnlockDate == 0, "already set");

    require(
      _startDate < _endDate &&
        _endDate < _firstUnlockDate &&
        _firstUnlockDate < _secondUnlockDate,
      "invalid input"
    );
    firstUnlockDate = _firstUnlockDate;
    secondUnlockDate = _secondUnlockDate;
    startDate = _startDate;
    endDate = _endDate;
  }

  function withdrawFunds() external onlyOwner whenNotPaused isSaleEnded {
    require(minimumRaiseAchieved(), "Minimum raise has to be reached");
    // FEE_ADDRESS.transfer(address(this).balance.mul(feePercentage).div(100)); /* Fee Address */
    msg.sender.transfer(address(this).balance);
  }

  function withdrawUnsoldTokens() external onlyOwner isSaleEnded {
    require(!unsoldTokensRedeemed);
    uint256 unsoldTokens;
    if (hasMinimumRaise() && (cost(tokensAllocated) < cost(minimumRaise))) {
      /* Minimum Raise not reached */
      unsoldTokens = totalTokensForSale;
    } else {
      /* If minimum Raise Achieved Redeem All Tokens minus the ones */
      unsoldTokens = totalTokensForSale.sub(tokensAllocated);
    }

    if (unsoldTokens > 0) {
      unsoldTokensRedeemed = true;
      require(
        token.transfer(msg.sender, unsoldTokens),
        "ERC20 transfer failed"
      );
    }
  }

  function safePull() external payable onlyOwner whenPaused {
    msg.sender.transfer(address(this).balance);
    token.transfer(msg.sender, token.balanceOf(address(this)));
  }

  function removeToken(address _tokenAddress, address _to)
    external
    onlyOwner
    isSaleEnded
  {
    require(
      _tokenAddress != address(token),
      "Token Address has to be diff than the erc20 subject to sale"
    ); // Confirm tokens addresses are different from main sale one
    ERC20 _token = ERC20(_tokenAddress);
    require(
      _token.transfer(_to, _token.balanceOf(address(this))),
      "ERC20 Token transfer failed"
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.6.12;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

contract Whitelist {
  using SafeMath for uint256;

  address public _token;

  uint256 public BRONZE_THRESHOLD;
  uint256 public SILVER_THRESHOLD;
  uint256 public GOLD_THRESHOLD;

  uint256 public GOLD_WEIGHT;
  uint256 public SILVER_WEIGHT;
  uint256 public BRONZE_WEIGHT;

  uint256 public goldParticipants = 0;
  uint256 public silverParticipants = 0;
  uint256 public bronzeParticipants = 0;
  uint256 public publicParticipants = 0;

  struct WhitelistStruct {
    address wallet;
    string tier;
    bool whitelist;
    bool redeemed;
  }

  mapping(address => WhitelistStruct) public whitelistedParticipants;
  address[] public whitelistedAddresses;
  bool public hasWhitelisting = false;

  constructor(bool _hasWhitelisting, address token) public {
    hasWhitelisting = _hasWhitelisting;
    _token = token;
  }

  function register(address _address) public {
    uint256 userBalance = IERC20(_token).balanceOf(_address);
    if (userBalance >= GOLD_THRESHOLD) {
      goldParticipants.add(1);
      WhitelistStruct memory _whitelist = WhitelistStruct(
        msg.sender,
        "GOLD",
        true,
        false
      );
      whitelistedParticipants[_address] = _whitelist;
    } else if (
      userBalance >= SILVER_THRESHOLD && userBalance < GOLD_THRESHOLD
    ) {
      WhitelistStruct memory _whitelist = WhitelistStruct(
        msg.sender,
        "SILVER",
        true,
        false
      );
      whitelistedParticipants[_address] = _whitelist;
      silverParticipants.add(1);
    } else if (
      userBalance >= BRONZE_THRESHOLD && userBalance <= SILVER_THRESHOLD
    ) {
      WhitelistStruct memory _whitelist = WhitelistStruct(
        msg.sender,
        "BRONZE",
        true,
        false
      );
      whitelistedParticipants[_address] = _whitelist;
      bronzeParticipants.add(1);
    } else {
      WhitelistStruct memory _whitelist = WhitelistStruct(
        msg.sender,
        "PUBLIC",
        true,
        false
      );
      whitelistedParticipants[_address] = _whitelist;
      publicParticipants.add(1);
    }
    whitelistedAddresses.push(_address);
  }

  function isWhitelisted(address _address) public view returns (bool) {
    return whitelistedParticipants[_address].whitelist;
  }

  function getTotalParticipants() public view returns (uint256) {
    return whitelistedAddresses.length;
  }

  function calculateAmount(address _address, uint256 totalTokensForSale)
    internal
    view
    returns (uint256)
  {
    WhitelistStruct memory _whitelist = whitelistedParticipants[_address];
    uint256 totalWeight = (goldParticipants.mul(GOLD_WEIGHT))
      .add((silverParticipants.mul(SILVER_WEIGHT)))
      .add((bronzeParticipants.mul((BRONZE_WEIGHT))));

    uint256 tokenAllocationPerTier = totalTokensForSale.div(totalWeight);

    if (
      keccak256(abi.encode(_whitelist.tier)) == keccak256(abi.encode("GOLD"))
    ) {
      return goldParticipants.mul(tokenAllocationPerTier.mul(GOLD_WEIGHT));
    } else if (
      keccak256(abi.encode(_whitelist.tier)) == keccak256(abi.encode("SILVER"))
    ) {
      return silverParticipants.mul(tokenAllocationPerTier.mul(SILVER_WEIGHT));
    } else if (
      keccak256(abi.encode(_whitelist.tier)) == keccak256(abi.encode("BRONZE"))
    ) {
      return bronzeParticipants.mul(tokenAllocationPerTier.mul(BRONZE_WEIGHT));
    } else {
      return publicParticipants.mul(tokenAllocationPerTier);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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