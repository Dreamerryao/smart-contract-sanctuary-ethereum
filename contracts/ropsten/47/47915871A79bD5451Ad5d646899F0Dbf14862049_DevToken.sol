// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// helpers
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./Context.sol";
// contract
import "./Stakeable.sol";
import "./Vendor.sol";
import "./Migration.sol";

/**
 * @notice DevToken is a development token that we use to learn how to code solidity
 * and what X interface requires
 */
contract DevToken is Context, Ownable, Pausable, Vendor, Stakeable, Migration {
    using SafeMath for uint256;

    /**
     * @notice Our Tokens required variables that are needed to operate everything
     */
    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;

    struct infoToken {
        uint256 _totalSupply;
        uint8 _decimals;
        string _symbol;
        string _name;
    }

    /**
     * @notice _balances is a mapping that contains a address as KEY
     * and the balance of the address as the value
     */
    mapping(address => uint256) private _balances;

    /**
     * @notice _allowances is used to manage and control allownace
     * An allowance is the right to use another accounts balance, or part of it
     */
    mapping(address => mapping(address => uint256)) private _allowances;

    /**
     * @notice Events are created below.
     * Transfer event is a event that notify the blockchain that a transfer of assets has taken place
     *
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @notice Approval is emitted when a new Spender is approved to spend Tokens on
     * the Owners account
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @notice constructor will be triggered when we create the Smart contract
     * _name = name of the token
     * _short_symbol = Short Symbol name for the token
     * token_decimals = The decimal precision of the Token, defaults 18
     * _totalSupply is how much Tokens there are totally
     */

    uint256 minimum_purchase_amount_staked = 10000000000; // 100 Token

    constructor(
        string memory token_name,
        string memory short_symbol,
        uint8 token_decimals,
        uint256 token_totalSupply
    ) Vendor(address(this)) {
        _name = token_name;
        _symbol = short_symbol;
        _decimals = token_decimals;

        // _totalSupply = token_totalSupply * (uint256(10)**uint256(_decimals));
        _totalSupply = token_totalSupply * 10**uint256(_decimals);
        _balances[owner()] = _totalSupply;
        _mint(address(this), 7000000 * 10**uint256(_decimals));
        // // Emit an Transfer event to notify the blockchain that an Transfer has occured
        emit Transfer(address(0), address(this), _totalSupply);
    }

    /**
     * @notice we get the token information
     */
    function getInfoToken()
        external
        view
        returns (infoToken memory _propertyObj)
    {
        return infoToken(_totalSupply, _decimals, _symbol, _name);
    }

    /**
     * @notice balanceOf will return the account balance for the given account
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice _mint will create tokens on the address inputted and then increase the total supply
     *
     * It will also emit an Transfer event, with sender set to zero address (adress(0))
     *
     * Requires that the address that is recieveing the tokens is not zero address
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "cannot mint to zero address");

        // Increase total supply
        _totalSupply = _totalSupply.add(amount);

        // Add amount to the account balance using the balance mapping
        _balances[account] = _balances[account].add(amount);

        // Emit our event to log the action
        emit Transfer(address(0), account, amount);
    }

    /**
     * @notice _burn will destroy tokens from an address inputted and then decrease total supply
     * An Transfer event will emit with receiever set to zero address
     *
     * Requires
     * - Account cannot be zero
     * - Account balance has to be bigger or equal to amount
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "cannot burn from zero address");
        require(
            _balances[account] >= amount,
            "Cannot burn more than the account owns"
        );

        // Remove the amount from the account balance
        _balances[account] = _balances[account].sub(
            amount,
            "burn amount exceeds balance"
        );

        // Decrease totalSupply
        _totalSupply = _totalSupply.sub(amount);

        // Emit event, use zero address as reciever
        emit Transfer(account, address(0), amount);
    }

    /**
     * @notice burn is used to destroy tokens on an address
     *
     * See {_burn}
     * Requires
     *   - msg.sender must be the token owner
     *
     */
    function burn(address account, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        _burn(account, amount);
        return true;
    }

    /**
     * @notice mint is used to create tokens and assign them to msg.sender
     *
     * See {_mint}
     * Requires
     *   - msg.sender must be the token owner
     *
     */
    function mint(address account, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        _mint(account, amount);
        return true;
    }

    /**
     * @notice transfer is used to transfer funds from the sender to the recipient
     * This function is only callable from outside the contract. For internal usage see
     * _transfer
     *
     * Requires
     * - Caller cannot be zero
     * - Caller must have a balance = or bigger than amount
     *
     */
    function transfer(address recipient, uint256 amount)
        external
        whenNotPaused
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @notice _transfer is used for internal transfers
     *
     * Events
     * - Transfer
     *
     * Requires
     *  - Sender cannot be zero
     *  - recipient cannot be zero
     *  - sender balance most be = or bigger than amount
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "transfer from zero address");
        require(recipient != address(0), "transfer to zero address");
        require(
            _balances[sender] >= amount,
            "cant transfer more than your account holds"
        );

        _balances[sender] = _balances[sender].sub(
            amount,
            "transfer amount exceeds balance"
        );

        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    /**
     * @notice getOwner just calls Ownables owner function.
     * returns owner of the token
     *
     */
    function getOwner() external view returns (address) {
        return owner();
    }

    /**
     * @notice allowance is used view how much allowance an spender has
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @notice approve will use the senders address and allow the spender to use X amount of tokens on his behalf
     */
    function approve(address spender, uint256 amount)
        external
        whenNotPaused
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @notice _approve is used to add a new Spender to a Owners account
     *
     * Events
     *   - {Approval}
     *
     * Requires
     *   - owner and spender cannot be zero address
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(
            owner != address(0),
            "approve cannot be done from zero address"
        );
        require(spender != address(0), "approve cannot be to zero address");

        // Set the allowance of the spender address at the Owner mapping over accounts to the amount
        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /**
     * @notice transferFrom is uesd to transfer Tokens from a Accounts allowance
     * Spender address should be the token holder
     *
     * Requires
     *   - The caller must have a allowance = or bigger than the amount spending
     */

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external whenNotPaused returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "You cannot spend that much on this account"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @notice increaseAllowance
     * Adds allowance to a account from the function caller address
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        whenNotPaused
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );

        return true;
    }

    /**
     * @notice decreaseAllowance
     * Decrease the allowance on the account inputted from the caller address
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        whenNotPaused
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "decreased allowance below zero"
            )
        );

        return true;
    }

    // ---------- STAKES ----------

    /**
     * Add functionality like burn to the _stake afunction
     *
     */
    function stake(
        uint256 _amount,
        uint256 _untilBlock,
        uint256 _rewardRate
    ) public whenNotPausedPresale {
        // Make sure staker actually is good for it
        require(
            _amount < _balances[_msgSender()],
            "Cannot stake more than you own"
        );

        // the initial amount must be greater than 100 jdb
        require(
            _amount >= minimum_purchase_amount_staked,
            "the initial amount must be greater than 100 jdb"
        );

        _stake(_amount, _untilBlock, _rewardRate);

        // Burn the amount of tokens on the sender
        _burn(_msgSender(), _amount);
    }

    /**
     * @notice withdrawStake is used to withdraw stakes from the account holder
     */
    function withdrawStake(uint256 amount, uint256 stake_index)
        public
        whenNotPausedPresale
    {
        uint256 amount_to_mint = _withdrawStake(amount, stake_index);
        // Return staked tokens to user
        _mint(_msgSender(), amount_to_mint);
    }

    /**
     * @notice A method to the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */

    function totalStakes() public view returns (uint256) {
        return _totalStakes();
    }

    /**
     * @dev change minimum purchase amount
     */
    function changeMinimumStakesAmount(uint256 _minimum_purchase_amount_staked)
        public
        onlyOwner
        returns (bool)
    {
        minimum_purchase_amount_staked = _minimum_purchase_amount_staked;
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Ownable.sol";
import "./PausableSell.sol";

import "./SafeMath.sol";
import "./Presale.sol";
import "./DevToken.sol";
import "./PriceConsumerV3.sol";

contract Vendor is Context, Ownable, PausableSell, Presale, PriceConsumerV3 {
    // Our Token Contract
    DevToken devToken;

    using SafeMath for uint256;

    // token price for ETH
    uint256 public tokensPerEth = 100;

    /*
     * variables to obtain reward for purchase
     */
    uint256 bonusA = 10000000000; // 100 Token
    uint256 bonusB = 100000000000; // 1000 Token
    uint256 bonusC = 500000000000; // 5000 Token
    uint256 bonusD = 1000000000000; // 10000 Token
    uint256 minimum_purchase_amount = 10000000000; // 100 Token

    // Event that log buy operation
    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event BonusTreeTokens(address inviter, uint256 commissionInviter);
    event SellTokens(
        address seller,
        uint256 amountOfTokens,
        uint256 amountOfETH
    );

    constructor(address tokenAddress) {
        devToken = DevToken(tokenAddress);
    }

    /**
     * @notice Allow users to buy tokens for ETH
     */
    function buyTokens(address inviter)
        public
        payable
        returns (uint256 tokenAmount)
    {
        require(msg.value > 0, "Send ETH to buy some tokens");

        // precio variable por token // servicio chainlink
        uint256 _price = uint256(getEthUsd()) / 10**8; // ETH/USD
        uint256 amountToBuy = (msg.value * _price) / 10**10;

        // Check that the requested amount of tokens to sell is more than 100
        require(
            amountToBuy >= minimum_purchase_amount,
            "DevToken: the initial amount must be greater than 100 jdb"
        );

        // check if the Vendor Contract has enough amount of tokens for the transaction
        uint256 vendorBalance = devToken.balanceOf(address(this));
        require(
            vendorBalance >= amountToBuy,
            "Vendor contract has not enough tokens in its balance"
        );

        // variables mas bonus
        uint256 amountToBuyMoreBonus = 0;
        if (!pausedPresale) {
            // pre-sale bonus calculation
            amountToBuyMoreBonus = amountToBuy + calculateBonus(amountToBuy);

            if (inviter != address(0) && inviter != address(this)) {
                uint256 commissionInviter = amountToBuy.mul(10).div(100);

                bool sent = devToken.transfer(inviter, commissionInviter);
                require(
                    sent,
                    "Commission Inviter Failed to transfer token to inviter"
                );

                emit BonusTreeTokens(inviter, commissionInviter);
            }
        } else {
            amountToBuyMoreBonus = amountToBuy;
        }

        // Transfer token to the msg.sender
        bool sent = devToken.transfer(_msgSender(), amountToBuyMoreBonus);
        require(sent, "Failed to transfer token to user");

        // emit the event
        emit BuyTokens(_msgSender(), msg.value, amountToBuyMoreBonus);

        return amountToBuyMoreBonus;
    }

    /**
     * @notice Allow users to sell tokens for ETH
     */
    function sellTokens(uint256 tokenAmountToSell) public SellWhenNotPaused {
        // Check that the requested amount of tokens to sell is more than 0
        require(
            tokenAmountToSell > 0,
            "Specify an amount of token greater than zero"
        );

        // Check that the user's token balance is enough to do the swap
        uint256 userBalance = devToken.balanceOf(_msgSender());
        require(
            userBalance >= tokenAmountToSell,
            "Your balance is lower than the amount of tokens you want to sell"
        );

        // Check that the Vendor's balance is enough to do the swap
        // precio fijo por token
        // uint256 amountOfETHToTransfer = tokenAmountToSell / tokensPerEth;

        // precio variable por token // servicio chainlink
        int256 _price = getEthUsd() / 10**8;
        uint256 amountOfETHToTransfer = tokenAmountToSell / uint256(_price);

        uint256 ownerETHBalance = address(this).balance;
        require(
            ownerETHBalance >= amountOfETHToTransfer,
            "Vendor has not enough funds to accept the sell request"
        );

        bool sent = devToken.transferFrom(
            _msgSender(),
            address(this),
            tokenAmountToSell
        );
        require(sent, "Failed to transfer tokens from user to vendor");

        (sent, ) = _msgSender().call{value: amountOfETHToTransfer}("");
        require(sent, "Failed to send ETH to the user");
    }

    /**
     * @notice Allow the owner of the contract to withdraw ETH
     */
    function withdraw() public onlyOwner {
        uint256 ownerBalance = address(this).balance;
        require(ownerBalance > 0, "Owner has not balance to withdraw");

        (bool sent, ) = _msgSender().call{value: address(this).balance}("");
        require(sent, "Failed to send user balance back to the owner");
    }

    /**
     * @notice we get the bonus according to the purchase
     */
    function calculateBonus(uint256 tokenAmountToBuy)
        internal
        view
        returns (uint256)
    {
        require(tokenAmountToBuy > 0, "must buy some tokens");

        uint256 result;

        if (tokenAmountToBuy <= bonusA) {
            // 5% de beneficio
            result = 0;
        } else if (tokenAmountToBuy > bonusA && tokenAmountToBuy <= bonusB) {
            // 10% de beneficio
            result = (tokenAmountToBuy.mul(5)).div(100);
        } else if (tokenAmountToBuy > bonusB && tokenAmountToBuy <= bonusC) {
            // 15% de beneficio
            result = (tokenAmountToBuy.mul(10)).div(100);
        } else if (tokenAmountToBuy > bonusC && tokenAmountToBuy <= bonusD) {
            // 20% de beneficio
            result = (tokenAmountToBuy.mul(15)).div(100);
        } else if (tokenAmountToBuy > bonusD) {
            // 25% de beneficio
            result = (tokenAmountToBuy.mul(20)).div(100);
        }
        return result;
    }

    /**
     * @dev cambiar el precio de los tokens
     */
    function changeMinimumPurchaseAmount(uint256 _minimum_purchase_amount)
        public
        onlyOwner
        returns (bool)
    {
        minimum_purchase_amount = _minimum_purchase_amount;
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Ownable.sol";
import "./SafeMath.sol";

/**
 * @notice Stakeable is a contract who is ment to be inherited by other contract that wants Staking capabilities
 */
contract Stakeable is Context, Ownable {
    using SafeMath for uint256;

    /**
     * @notice Constructor since this contract is not ment to be used without inheritance
     * push once to stakeholders for it to work proplerly
     */
    constructor() {
        // This push is needed so we avoid index 0 causing bug of index-1
        stakeholders.push();
    }

    /**
     * @notice
     * A stake struct is used to represent the way we store stakes,
     * A Stake will contain the users address, the amount staked and a timestamp,
     * Since which is when the stake was made
     */
    struct Stake {
        address user;
        uint256 amount;
        uint256 sinceBlock;
        uint256 untilBlock;
        uint256 rewardRate;
        // This claimable field is new and used to tell how big of a reward is currently available
        uint256 claimable;
    }
    /**
     * @notice Stakeholder is a staker that has active stakes
     */
    struct Stakeholder {
        address user;
        Stake[] address_stakes;
    }
    /**
     * @notice
     * StakingSummary is a struct that is used to contain all stakes performed by a certain account
     */
    struct StakingSummary {
        uint256 total_amount;
        Stake[] stakes;
    }

    /**
     * @notice
     *   This is a array where we store all Stakes that are performed on the Contract
     *   The stakes for each address are stored at a certain index, the index can be found using the stakes mapping
     */
    Stakeholder[] internal stakeholders;
    /**
     * @notice
     * stakes is used to keep track of the INDEX for the stakers in the stakes array
     */
    mapping(address => uint256) internal stakes;
    /**
     * @notice Staked event is triggered whenever a user stakes tokens, address is indexed to make it filterable
     */
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 index,
        uint256 sinceBlock,
        uint256 untilBlock,
        uint256 rewardRate
    );

    // ---------- STAKES ----------

    /**
     * @notice _addStakeholder takes care of adding a stakeholder to the stakeholders array
     */
    function _addStakeholder(address staker) internal returns (uint256) {
        // Push a empty item to the Array to make space for our new stakeholder
        stakeholders.push();
        // Calculate the index of the last item in the array by Len-1
        uint256 userIndex = stakeholders.length - 1;
        // Assign the address to the new index
        stakeholders[userIndex].user = staker;
        // Add index to the stakeHolders
        stakes[staker] = userIndex;
        return userIndex;
    }

    /**
     * @notice
     * _Stake is used to make a stake for an sender. It will remove the amount staked from the stakers account and place those tokens inside a stake container
     * StakeID
     */
    function _stake(
        uint256 _amount,
        uint256 _untilBlock,
        uint256 _rewardRate
    ) internal {
        // Simple check so that user does not stake 0
        require(_amount > 0, "Cannot stake nothing");

        // Mappings in solidity creates all values, but empty, so we can just check the address
        uint256 index = stakes[_msgSender()];
        // block.timestamp = timestamp of the current block in seconds since the epoch
        uint256 sinceBlock = block.timestamp;
        // See if the staker already has a staked index or if its the first time
        if (index == 0) {
            // This stakeholder stakes for the first time
            // We need to add him to the stakeHolders and also map it into the Index of the stakes
            // The index returned will be the index of the stakeholder in the stakeholders array
            index = _addStakeholder(_msgSender());
        }

        uint256 timeToDistribute = sinceBlock + _untilBlock;

        // Use the index to push a new Stake
        // push a newly created Stake with the current block timestamp.
        stakeholders[index].address_stakes.push(
            Stake(
                _msgSender(),
                _amount,
                sinceBlock,
                timeToDistribute,
                _rewardRate,
                0
            )
        );
        // Emit an event that the stake has occured
        emit Staked(
            _msgSender(),
            _amount,
            index,
            sinceBlock,
            timeToDistribute,
            _rewardRate
        );
    }

    /**
     * @notice A method to the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */
    function _totalStakes() internal view returns (uint256) {
        uint256 __totalStakes = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1) {
            __totalStakes =
                __totalStakes +
                stakeholders[s].address_stakes.length;
        }

        return __totalStakes;
    }

    /**
     * @notice
     * calculateStakeReward is used to calculate how much a user should be rewarded for their stakes
     * and the duration the stake has been active
     */

    function calculateStakeRewardBlock(Stake memory _current_stake)
        internal
        pure
        returns (uint256)
    {
        // Current staked Amount : staked amount *stake fee — unstaked amount *unstake fee
        // RewardRate : APY %
        // TimeDiff : current timestamp — last timestamp
        // RewardInterval: 365 days

        return
            (1 + (_current_stake.rewardRate / 1) * 1 - 1) *
            _current_stake.amount;
    }

    /**
     * @notice
     * withdrawStake takes in an amount and a index of the stake and will remove tokens from that stake
     * Notice index of the stake is the users stake counter, starting at 0 for the first stake
     * Will return the amount to MINT onto the acount
     * Will also calculateStakeReward and reset timer
     */
    function _withdrawStake(uint256 amount, uint256 index)
        internal
        returns (uint256)
    {
        // Grab user_index which is the index to use to grab the Stake[]
        uint256 user_index = stakes[_msgSender()];
        Stake memory current_stake = stakeholders[user_index].address_stakes[
            index
        ];

        require(
            block.timestamp >= current_stake.untilBlock,
            "Staking: You cannot withdraw, it is still in its authorized blocking time"
        );

        require(
            current_stake.amount >= amount,
            "Staking: Cannot withdraw more than you have staked"
        );

        // Calculate available Reward first before we start modifying data
        uint256 reward = calculateStakeRewardBlock(current_stake);

        // Remove by subtracting the money unstaked
        current_stake.amount = current_stake.amount - amount;
        // If stake is empty, 0, then remove it from the array of stakes
        if (current_stake.amount == 0) {
            delete stakeholders[user_index].address_stakes[index];
        } else {
            // If not empty then replace the value of it
            stakeholders[user_index]
                .address_stakes[index]
                .amount = current_stake.amount;
            // Reset timer of stake
            stakeholders[user_index].address_stakes[index].sinceBlock = block
                .timestamp;
        }

        return amount + reward;
    }

    /**
     * @notice
     * hasStake is used to check if a account has stakes and the total amount along with all the seperate stakes
     */
    function hasStake(address _staker)
        public
        view
        returns (StakingSummary memory)
    {
        // totalStakeAmount is used to count total staked amount of the address
        uint256 totalStakeAmount;
        // Keep a summary in memory since we need to calculate this
        StakingSummary memory summary = StakingSummary(
            0,
            stakeholders[stakes[_staker]].address_stakes
        );

        // Itterate all stakes and grab amount of stakes
        for (uint256 s = 0; s < summary.stakes.length; s += 1) {
            uint256 availableReward = calculateStakeRewardBlock(
                summary.stakes[s]
            );
            summary.stakes[s].claimable = availableReward;
            totalStakeAmount = totalStakeAmount + summary.stakes[s].amount;
        }
        // Assign calculate amount to summary
        summary.total_amount = totalStakeAmount;
        return summary;
    }

    /**
     */
    function getTime() public view returns (uint256 time) {
        return block.timestamp; // timestamp of the current block in seconds since the epoch
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 {
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Rinkeby
     * Decimal: 8
     * Aggregator: ETH / USD	
     * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
     */
    constructor() {
        priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
    }

    /**
     * Returns the latest price
     */
    function getEthUsd() public view returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        // If the round is not complete yet, timestamp is 0
        require(timeStamp > 0, "Round not complete");
        return price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Ownable.sol";

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Presale is Ownable {
    event PausePresale();
    event UnpausePresale();

    bool public pausedPresale = false;

    /**
     * @dev modifier to allow actions only when the contract IS paused
     */
    modifier whenNotPausedPresale() {
        require(!pausedPresale);
        _;
    }

    /**
     * @dev modifier to allow actions only when the contract IS NOT paused
     */
    modifier whenPausedPresale() {
        require(pausedPresale);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pausePresale() public onlyOwner whenNotPausedPresale returns (bool) {
        pausedPresale = true;
        emit PausePresale();
        return true;
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpausePresale() public onlyOwner whenPausedPresale returns (bool) {
        pausedPresale = false;
        emit UnpausePresale();
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Ownable.sol";

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract PausableSell is Ownable {
    event SellPause();
    event SellUnpause();

    bool public Sellpaused = false;

    /**
     * @dev modifier to allow actions only when the contract IS paused
     */
    modifier SellWhenNotPaused() {
        require(!Sellpaused);
        _;
    }

    /**
     * @dev modifier to allow actions only when the contract IS NOT paused
     */
    modifier SellWhenPaused() {
        require(Sellpaused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function Sellpause() public onlyOwner SellWhenNotPaused returns (bool) {
        Sellpaused = true;
        emit SellPause();
        return true;
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function Sellunpause() public onlyOwner SellWhenPaused returns (bool) {
        Sellpaused = false;
        emit SellUnpause();
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Ownable.sol";

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev modifier to allow actions only when the contract IS paused
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev modifier to allow actions only when the contract IS NOT paused
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(isOwner(), "Ownable: only owner can call this function");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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
        require(
            newOwner != address(0),
            "Ownable: only owner can call this function"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./DevToken.sol";

/**
 * @dev Initiate the account of destinations[i] with values[i]. The function must only be called before
 * any transfer of tokens (duringInitialization). The caller must check that destinations are unique addresses.
 * For a large number of destinations, separate the balances initialization in different calls to batchTransfer.
 * destinations List of addresses to set the values
 * values List of values to set
 */

contract Migration is Ownable {
    DevToken _devToken;
    event migrationTokens(address destinations, uint256 values);

    function batchTransfer(
        address[] memory destinations,
        uint256[] memory values
    ) public onlyOwner returns (bool) {
        require(destinations.length == values.length);

        uint256 length = destinations.length;
        uint256 i;

        for (i = 0; i < length; i++) {
            _devToken.transfer(destinations[i], values[i]);
            emit migrationTokens(destinations[i], values[i]);
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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