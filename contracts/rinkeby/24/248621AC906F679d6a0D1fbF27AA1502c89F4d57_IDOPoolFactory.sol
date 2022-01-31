// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../Role/PoolCreator.sol";
import "../Interfaces/IRewardManager.sol";
import "./IDOPoolProxy.sol";


contract IDOPoolFactory is PoolCreator{
    ISparksToken public immutable sparksToken;
    IRewardManager public immutable rewardManager;
    address public immutable idoTokenBank;

    address public superAdmin;
    address public immutable usdTokenAddress;
    address public idoPoolImplementationAddr;

    uint256 public stakingPoolTaxRate;
    uint256 public minimumStakeAmount;

    /**
     * @param variables The IDOPoolProxy is created with these specs:
            variables[0] = launchDate
            variables[1] = maturityTime
            variables[2] = lockTime
            variables[3] = purchaseExpirationTime
            variables[4] = sizeAllocation
            variables[5] = stakeApr
            variables[6] = prizeAmount
            variables[7] = idoAllocationFee
            variables[8] = stakingPoolTaxRate
            variables[9] = idoPurchasePrice
            variables[10] = minimumStakeAmount
    */

    event PoolCreated(
        address indexed pool,
        address idoTokenContract,
        uint256[11] variables,
        uint256[8] ranks,
        uint256[8] percentages
    );

    event NewIDOPoolImplemnetationWasSet();

    event NewSuperAdminWasSet();

    constructor(
        ISparksToken _sparksToken,
        IRewardManager _rewardManager,
        address _idoTokenBank,
        address _usdTokenAddress,
        address _idoPoolImplementationAddr,
        address _superAdmin
    ) {
        sparksToken = _sparksToken;
        rewardManager = _rewardManager;
        idoTokenBank = _idoTokenBank;
        usdTokenAddress = _usdTokenAddress;

        idoPoolImplementationAddr = _idoPoolImplementationAddr;

        superAdmin = _superAdmin;

        stakingPoolTaxRate = 300;
    }

     /**
     * @notice creates an IDOPoolProxy for the  provided idoPoolImplementationAddr
            and initializes it so that the pool is ready to be used.
       @param _variables The IDOPoolProxy is created with these specs:
            variables[0] = launchDate
            variables[1] = maturityTime
            variables[2] = lockTime
            variables[3] = purchaseExpirationTime
            variables[4] = sizeAllocation
            variables[5] = stakeApr
            variables[6] = prizeAmount
            variables[7] = idoAllocationFee
            variables[8] = stakingPoolTaxRate
            variables[9] = idoPurchasePrice
            variables[10] = minimumStakeAmount
    */

    function createPoolProxy(
        string memory _poolType,
        address idoToken,
        uint256[11] memory _variables,
        uint256[8] memory _ranks,
        uint256[8] memory _percentages
        
    ) external onlyPoolCreator returns (address) {

        require(
            _ranks.length == _percentages.length,
            "length of ranks and percentages should be same"
        );

        IDOPoolProxy idoPoolProxy = new IDOPoolProxy();
        address idoPoolProxyAddr = address(idoPoolProxy);

        idoPoolProxy.upgradeTo(idoPoolImplementationAddr);

        if (_variables[8] == 0) {
            _variables[8] = stakingPoolTaxRate;
        }   

        idoPoolProxy.initialize(
            _poolType, 
            sparksToken, 
            rewardManager, 
            idoTokenBank, 
            usdTokenAddress, 
            idoToken, 
            _msgSender(),
            _variables, 
            _ranks, 
            _percentages
        );

        emit PoolCreated(
            idoPoolProxyAddr,
            idoToken,
            _variables,
            _ranks,
            _percentages
        );

        idoPoolProxy.transferOwnership(superAdmin);

        rewardManager.addPool(idoPoolProxyAddr);
        
        return idoPoolProxyAddr;
    }

    /**
     * @notice This function is called whenever we want to use a new IDOPoolImplementation
            to create our proxies for.
     * @param _ImpAdr address of the new IDOkingPoolImplementation contract.
    */
    function setNewIDOPoolImplementationAddr(address _ImpAdr) external onlyPoolCreator {
        require(
            idoPoolImplementationAddr != _ImpAdr, 
            'This address is the implementation that is  already being used'
        );
        idoPoolImplementationAddr = _ImpAdr;
        emit NewIDOPoolImplemnetationWasSet();
    }

    /**
     * @notice Changes superAdmin's address so that new IDOPoolProxies have this new superAdmin
    */
    function setNewSuperAdmin(address _superAdmin) external onlyPoolCreator {
        superAdmin = _superAdmin;
        emit NewSuperAdminWasSet();
    }

    function setDefaultTaxRate(uint256 newStakingPoolTaxRate)
        external
        onlyPoolCreator
    {
        require(
            newStakingPoolTaxRate < 10000,
            "0720 Tax connot be over 100% (10000 BP)"
        );
        stakingPoolTaxRate = newStakingPoolTaxRate;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "./Roles.sol";

contract PoolCreator is Context {
    using Roles for Roles.Role;

    event PoolCreatorAdded(address indexed account);
    event PoolCreatorRemoved(address indexed account);

    Roles.Role private _poolCreators;

    constructor() {
        if (!isPoolCreator(_msgSender())) {
            _addPoolCreator(_msgSender());
        }
    }

    modifier onlyPoolCreator() {
        require(
            isPoolCreator(_msgSender()),
            "PoolCreatorRole: caller does not have the PoolCreator role"
        );
        _;
    }

    function isPoolCreator(address account) public view returns (bool) {
        return _poolCreators.has(account);
    }

    function addPoolCreator(address account) public onlyPoolCreator {
        _addPoolCreator(account);
    }

    function renouncePoolCreator() public {
        _removePoolCreator(_msgSender());
    }

    function _addPoolCreator(address account) internal {
        _poolCreators.add(account);
        emit PoolCreatorAdded(account);
    }

    function _removePoolCreator(address account) internal {
        _poolCreators.remove(account);
        emit PoolCreatorRemoved(account);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// TODO: provide an interface so IDO-prediction can work with that
interface IRewardManager {

    event SetOperator(address operator);
    event SetRewarder(address rewarder);

    function setOperator(address _newOperator) external;

    function addPool(address _poolAddress) external;

    function rewardUser(address _user, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDOPoolStorageStructure.sol";

contract IDOPoolProxy is IDOPoolStorageStructure {

    modifier onlyPoolCreator() {
        require (msg.sender == poolCreator, "msg.sender is not an owner");
        _;
    }

    event ImplementationUpgraded();

    /**
     * @dev poolCreator is set to the address of IDOPoolFactory here, but it will change
            to the address of the owner after initialize is called. This is to prevent any other
            entity other than the IDOPoolFactory to call initialize and upgradeTo (for the 
            first time).
            upgradeEnabled set to true so that upgradeTo can be called for the first time
            when the main impelementaiton is being set. 
    */
    constructor() {
        poolCreator = msg.sender;
        upgradeEnabled = true;
    }

    /**
     * @notice This is called in case we want to upgrade a working pool which inherits from
            the original implementation, to apply bug fixes and consider emergency cases.
    */
    function upgradeTo(address _newIDOPoolImplementation) external onlyPoolCreator {
        require(upgradeEnabled, "Upgrade is not enabled yet");
        require(idoPoolImplementation != _newIDOPoolImplementation, "Is already the implementation");
        _setStakingPoolImplementation(_newIDOPoolImplementation);
        upgradeEnabled = false;
    }

    /**
     * @notice IDOPoolImplementation can't be upgraded unless superAdmin sets upgradeEnabled
     */
    function enableUpgrade() external onlyOwner{
        upgradeEnabled = true;
    }

    function disableUpgrade() external onlyOwner{
        upgradeEnabled = false;
    }

    /**
     * @notice The initializer modifier is used to make sure initialize() is not called 
            more than once because we want it to act like a constructor.
    */
    function initialize(
        string memory _poolType,
        ISparksToken _sparksToken,
        IRewardManager _rewardManager,
        address _idoTokenBank,
        address _usdTokenAddress,
        address _idoToken,
        address _poolCreator,
        uint256[11] memory _variables,
        uint256[8] memory _ranks,
        uint256[8] memory _percentages
    ) public initializer onlyPoolCreator
    {
        /// @dev we should call inits because we don't have a constructor to do it for us
        OwnableUpgradeable.__Ownable_init();
        ContextUpgradeable.__Context_init();

        require(
            _variables[0] > block.timestamp,
            "0301 launch date can't be in the past"
        );

         poolType = _poolType;

        sparksToken = _sparksToken;
        rewardManager = _rewardManager;
        idoTokenBank = _idoTokenBank;
        usdToken = IERC20(_usdTokenAddress);
        idoToken = _idoToken;
        poolCreator = _poolCreator;

        launchDate = _variables[0];

        maturityTime = _variables[1];
        lockTime = _variables[2];
        purchaseExpirationTime = _variables[3];

        sizeAllocation = _variables[4];
        stakeApr = _variables[5];
        prizeAmount = _variables[6];
        idoAllocationFee = _variables[7];
        stakeTaxRate = _variables[8];
        purchasePrice = _variables[9];
        minimumStakeAmount = _variables[10];

        for (uint256 i = 0; i < _ranks.length; i++) {

            if (_percentages[i] == 0) break;

            prizeRewardRates.push(
                PrizeRewardRate({
                    rank: _ranks[i], 
                    percentage: _percentages[i]
                })
            );
        }


        lps.launchDate = launchDate;
        lps.lockTime = lockTime;
        lps.maturityTime = maturityTime;
        lps.purchaseExpirationTime = purchaseExpirationTime;
        lps.maxPriceTillMaturity = maxPriceTillMaturity;
        lps.purchasePrice = purchasePrice;
        lps.prizeAmount = prizeAmount;
        lps.stakeApr = stakeApr;
        lps.idoAllocationFee = idoAllocationFee;
        lps.isMatured = isMatured;
    }

    fallback() external payable {
        address opr = idoPoolImplementation;
        require(opr != address(0));
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), opr, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
    
    receive() external payable {}

    function _setStakingPoolImplementation(address _newIDOPool) internal {
        idoPoolImplementation = _newIDOPool;
        emit ImplementationUpgraded();
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../Interfaces/IRewardManager.sol";
import "../Interfaces/ISparksToken.sol";

import "../Libraries/BasisPoints.sol";
import "../Libraries/CalculateRewardLib.sol";
import "../Libraries/ClaimRewardLib.sol";
import "../Libraries/PurchaseIDOLib.sol";

contract IDOPoolStorageStructure is
    OwnableUpgradeable
{
    address public idoPoolImplementation;
    address public poolCreator;

    /**
     * @notice Declared for passing the needed params to libraries.
     */
    struct LibParams {
        uint256 launchDate;
        uint256 lockTime;
        uint256 maturityTime;
        uint256 purchaseExpirationTime;
        uint256 maxPriceTillMaturity;
        uint256 purchasePrice;
        uint256 prizeAmount;
        uint256 stakeApr;
        uint256 idoAllocationFee;
        bool isMatured;
    }
    LibParams public lps;

    struct StakeWithPrediction {
        uint256 stakedBalance;
        uint256 stakedTime;
        uint256 amountWithdrawn;
        uint256 lastWithdrawalTime;
        uint256 pricePrediction1;
        uint256 pricePrediction2;
        uint256 difference;
        uint256 rank;
        bool didPrizeWithdrawn;
        bool didUnstake;
    }

    /**
     * @param totalAmount Total amount of tokens can be purchased.
     * @param amountWithdrawn The amount that has been withdrawn.
     */
    struct IDOTokenSchedule {
        bool isUSDPaid;
        uint256 totalAmount;
        uint256 amountWithdrawn;
    }

    struct PrizeRewardRate {
        uint256 rank;
        uint256 percentage;
    }


    address[] public stakers;
    address[] public winnerStakers;
    PrizeRewardRate[] public prizeRewardRates;

    mapping(address => StakeWithPrediction) public predictions;
    mapping(address => IDOTokenSchedule) public idoRecipients;

    // it wasn't possible to use totem token interface since we use taxRate variable
    ISparksToken public sparksToken;
    IRewardManager public rewardManager;
    address public idoTokenBank;
    IERC20 public usdToken;
    address public idoToken;

    string public poolType;

    /// @notice 100 means 1%
    uint256 public constant sizeLimitRangeRate = 500;
    
    /// @notice the default dexDecimal is 8 but can be modified in setIDOPrices
    uint256 public constant dexDecimal = 8;

    uint256 public constant tier1 = 3000*(10**18);
    uint256 public constant tier2 = 30000*(10**18);
    uint256 public constant tier3 = 150000*(10**18);
    

    uint256 public launchDate;
    uint256 public lockTime;
    uint256 public maturityTime;
    uint256 public purchaseExpirationTime;
    // TODO: adding expirationTime
    /// @notice total TOTM can be staked
    uint256 public sizeAllocation; 
    /// @notice the annual return rate for staking TOTM
    uint256 public stakeApr;

    /// @notice prizeUint (x) is the unit of TOTM that will be given to winners 
    ///         and multiply by 2 if user have staked more than an amount
    uint256 public prizeAmount;
    uint256 public idoTokenAmount;

    uint256 public stakeTaxRate;
    uint256 public idoAllocationFee;
    uint256 public minimumStakeAmount;

    uint256 public totalStaked;

    /// @notice matruing price and purchase price should have same decimals
    uint256 public maxPriceTillMaturity;
    uint256 public purchasePrice;


    bool public isAnEmergency;
    bool public isActive;
    bool public isLocked;
    bool public isMatured;
    bool public isDeleted;

    /**
     * @dev IDOPoolImplementation can't be upgraded unless superAdmin sets this flag.
     */
    bool public upgradeEnabled;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// TODO: add an interface for this to add the interface instead of 
interface ISparksToken {
    
    function setLocker(address _locker) external;

    function setDistributionTeamsAddresses(
        address _SeedInvestmentAddr,
        address _StrategicRoundAddr,
        address _PrivateSaleAddr,
        address _PublicSaleAddr,
        address _TeamAllocationAddr,
        address _StakingRewardsAddr,
        address _CommunityDevelopmentAddr,
        address _MarketingDevelopmentAddr,
        address _LiquidityPoolAddr,
        address _AirDropAddr
    ) external;

    function distributeTokens() external;

    function getTaxationWallet() external returns (address);

    function setTaxationWallet(address _newTaxationWallet) external;

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library BasisPoints {
    using SafeMath for uint256;

    uint256 private constant BASIS_POINTS = 10000;

    function mulBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        return amt.mul(bp).div(BASIS_POINTS);
    }

    function divBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        require(bp > 0, "Cannot divide by zero.");
        return amt.mul(BASIS_POINTS).div(bp);
    }

    function addBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.add(mulBP(amt, bp));
    }

    function subBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.sub(mulBP(amt, bp));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./BasisPoints.sol";
import "../Staking/IDOPoolStorageStructure.sol";

library CalculateRewardLib {

    using BasisPoints for uint256;
    using SafeMath for uint256;

    uint256 public constant dexDecimal = 8;

    function calcStakingReturn(uint256 totalRewardRate, uint256 timeDuration, uint256 totalStakedBalance) 
        public
        pure
        returns (uint256) 
    {
        uint256 yearInSeconds = 365 days;

        uint256 first = (yearInSeconds**2)
            .mul(10**8);

        uint256 second = timeDuration
            .mul(totalRewardRate) 
            .mul(yearInSeconds)
            .mul(5000);
        
        uint256 third = totalRewardRate
            .mul(yearInSeconds**2)
            .mul(5000);

        uint256 forth = (timeDuration**2)
            .mul(totalRewardRate**2)
            .div(6);

        uint256 fifth = timeDuration
            .mul(totalRewardRate**2)
            .mul(yearInSeconds)
            .div(2);

        uint256 sixth = (totalRewardRate**2)
            .mul(yearInSeconds**2)
            .div(3);
 
        uint256 rewardPerStake = first.add(second).add(forth).add(sixth);

        rewardPerStake = rewardPerStake.sub(third).sub(fifth);

        rewardPerStake = rewardPerStake
            .mul(totalRewardRate)
            .mul(timeDuration);

        rewardPerStake = rewardPerStake
            .mul(totalStakedBalance)
            .div(yearInSeconds**3)
            .div(10**12);

        return rewardPerStake; 
    }

    // getTotalStakedBalance return remained staked balance
    function getTotalStakedBalance(IDOPoolStorageStructure.StakeWithPrediction storage _userStake)
        public
        view
        returns (uint256)
    {
        if (_userStake.stakedBalance <= 0) return 0;

        uint256 totalStakedBalance = 0;

        if (!_userStake.didUnstake) {
            totalStakedBalance = totalStakedBalance.add(
                _userStake.stakedBalance
            );
        }

        return totalStakedBalance;
    }


    ////////////////////////// internal functions /////////////////////
    function _getPrizeAmount(
        uint256 _rank,
        IDOPoolStorageStructure.LibParams storage _lps,
        IDOPoolStorageStructure.PrizeRewardRate[] storage _prizeRewardRates
    )
        internal
        view
        returns (uint256)
    {

        for (uint256 i = 0; i < _prizeRewardRates.length; i++) {
            if (_rank <= _prizeRewardRates[i].rank) {
                return (_lps.prizeAmount).mulBP(_prizeRewardRates[i].percentage);
            }
        }

        return 0;
    } 

    function _getStakingReturnPerStake(
        IDOPoolStorageStructure.StakeWithPrediction storage _userStake, 
        IDOPoolStorageStructure.LibParams storage _lps
    )
        internal
        view
        returns (uint256)
    {

        if (_userStake.didUnstake) {
            return 0;
        }

        uint256 maturityDate = 
            _lps.launchDate + 
            _lps.lockTime + 
            _lps.maturityTime;

        uint256 timeTo =
            block.timestamp > maturityDate ? maturityDate : block.timestamp;


        // the reward formula is ((1 + stakeAPR +enhancedReward)^((MaturingDate - StakingDate)/365) - 1) * StakingBalance
        uint256 rewardPerStake = calcStakingReturn(
            _lps.stakeApr,
            timeTo.sub(_userStake.stakedTime),
            _userStake.stakedBalance
        );

        rewardPerStake = rewardPerStake.sub(_userStake.amountWithdrawn);

        return rewardPerStake;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./CalculateRewardLib.sol";
import "./BasisPoints.sol";
import "../Staking/IDOPoolStorageStructure.sol";

library ClaimRewardLib {

    using CalculateRewardLib for *;
    using BasisPoints for uint256; 
    using SafeMath for uint256;

    uint256 public constant oracleDecimal = 8;


    ////////////////////////// public functions /////////////////////
    function getStakingReturn(
        IDOPoolStorageStructure.StakeWithPrediction storage _userStake,
        IDOPoolStorageStructure.LibParams storage _lps
    )
        public
        view
        returns (uint256)
    {
        if (_userStake.stakedBalance == 0) return 0;

        uint256 reward = CalculateRewardLib._getStakingReturnPerStake(_userStake, _lps);

        return reward;
    }

    function withdrawStakingReturn(
        uint256 _rewardPerStake,
        IDOPoolStorageStructure.StakeWithPrediction storage _userStake
    ) 
        public
    {
        if (_userStake.stakedBalance <= 0) return;

        _userStake.lastWithdrawalTime = block.timestamp;
        _userStake.amountWithdrawn = _userStake.amountWithdrawn.add(
            _rewardPerStake
        );
    }

    function withdrawPrize(
        IDOPoolStorageStructure.StakeWithPrediction storage _userStake
    )
        public
    {
        if (_userStake.stakedBalance <= 0) return;

        _userStake.didPrizeWithdrawn = true;
    }

    function withdrawStakedBalance(
        IDOPoolStorageStructure.StakeWithPrediction storage _userStake
    ) 
        public
    {
        if (_userStake.stakedBalance <= 0) return;

        _userStake.didUnstake = true;
    }

    function getPrize(
        IDOPoolStorageStructure.StakeWithPrediction storage _userStake, 
        IDOPoolStorageStructure.LibParams storage _lps,
        IDOPoolStorageStructure.PrizeRewardRate[] storage _prizeRewardRates
    )
        public
        view
        returns (uint256)
    {
        // wihtout the maturing price calculating prize is impossible
        if (!_lps.isMatured) return 0;

        // users that don't stake don't get any prize also
        if (_userStake.stakedBalance <= 0) return 0;

        // uint256 maturingBTCPrizeAmount =
        //     (_lps.usdPrizeAmount.mul(10**oracleDecimal)).div(_lps.maturingPrice);

        uint256 reward = 0;
        // uint256 btcReward = 0;

        // only calculate the prize amount for stakes that are not withdrawn yet
        if (!_userStake.didPrizeWithdrawn) {

            uint256 _totemAmount = CalculateRewardLib._getPrizeAmount(_userStake.rank, _lps, _prizeRewardRates);

            reward = reward.add(
                        _totemAmount
                );      
        }

        return reward;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./CalculateRewardLib.sol";
import "./BasisPoints.sol";
import "../Staking/IDOPoolStorageStructure.sol";

library PurchaseIDOLib {

    using CalculateRewardLib for *;
    using BasisPoints for uint256; 
    using SafeMath for uint256;

    uint256 public constant oracleDecimal = 8;


    ////////////////////////// public functions /////////////////////
    function payUSDForIDOToken(
        IDOPoolStorageStructure.IDOTokenSchedule storage _winnerIDOSchedule
    ) 
        public
    {
        if (_winnerIDOSchedule.isUSDPaid) return;

        _winnerIDOSchedule.isUSDPaid = true;
    }

    function withdrawIDOToken(
        uint256 _amount,
        IDOPoolStorageStructure.IDOTokenSchedule storage _winnerIDOSchedule
    ) 
        public
    {
        if (_winnerIDOSchedule.totalAmount <= 0) return;

        _winnerIDOSchedule.amountWithdrawn = _winnerIDOSchedule.amountWithdrawn.add(
            _amount
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
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