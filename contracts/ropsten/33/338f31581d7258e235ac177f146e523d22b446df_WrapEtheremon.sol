pragma solidity ^0.4.24;

interface KyberNetworkProxyInterface {
    function maxGasPrice() public view returns(uint);
    function getUserCapInWei(address user) public view returns(uint);
    function getUserCapInTokenWei(address user, ERC20 token) public view returns(uint);
    function enabled() public view returns(bool);
    function info(bytes32 id) public view returns(uint);

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) public view
        returns (uint expectedRate, uint slippageRate);

    function tradeWithHint(ERC20 src, uint srcAmount, ERC20 dest, address destAddress, uint maxDestAmount,
        uint minConversionRate, address walletId, bytes hint) public payable returns(uint);
}

interface EtheremonDataBase {
    function addMonsterObj(uint32 _classId, address _trainer, string _name) external returns(uint64);
    function addElementToArrayType(EtheremonEnum.ArrayType _type, uint64 _id, uint8 _value) external returns(uint);

    // read
    function getElementInArrayType(EtheremonEnum.ArrayType _type, uint64 _id, uint _index) constant external returns(uint8);
    function getMonsterClass(uint32 _classId) constant external returns(uint32 classId, uint256 price, uint256 returnPrice, uint32 total, bool catchable);
}

contract BasicAccessControl {
    address public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping (address => bool) public moderators;
    bool public isMaintaining = false;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyModerators() {
        require(msg.sender == owner || moderators[msg.sender] == true);
        _;
    }

    modifier isActive {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address _newOwner) onlyOwner public {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }


    function AddModerator(address _newModerator) onlyOwner public {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }

    function RemoveModerator(address _oldModerator) onlyOwner public {
        if (moderators[_oldModerator] == true) {
            moderators[_oldModerator] = false;
            totalModerators -= 1;
        }
    }

    function UpdateMaintaining(bool _isMaintaining) onlyOwner public {
        isMaintaining = _isMaintaining;
    }
}

interface ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract EtheremonEnum {
    enum ResultCode {
        SUCCESS,
        ERROR_CLASS_NOT_FOUND,
        ERROR_LOW_BALANCE,
        ERROR_SEND_FAIL,
        ERROR_NOT_TRAINER,
        ERROR_NOT_ENOUGH_MONEY,
        ERROR_INVALID_AMOUNT
    }

    enum ArrayType {
        CLASS_TYPE,
        STAT_STEP,
        STAT_START,
        STAT_BASE,
        OBJ_SKILL
    }

    enum PropertyType {
        ANCESTOR,
        XFACTOR
    }
}

contract EtheremonExternalPayment is EtheremonEnum, BasicAccessControl {
    uint8 constant public STAT_COUNT = 6;
    uint8 constant public STAT_MAX = 32;

    struct MonsterClassAcc {
        uint32 classId;
        uint256 price;
        uint256 returnPrice;
        uint32 total;
        bool catchable;
    }

    address public dataContract;
    uint public gapFactor = 0.001 ether;
    uint16 public priceIncreasingRatio = 1000;
    uint seed = 0;

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

    function setDataContract(address _contract) onlyOwner public {
        dataContract = _contract;
    }

    function setPriceIncreasingRatio(uint16 _ratio) onlyModerators external {
        priceIncreasingRatio = _ratio;
    }

    function setFactor(uint _gapFactor) onlyOwner public {
        gapFactor = _gapFactor;
    }

    function withdrawEther(address _sendTo, uint _amount) onlyOwner public {
        // no user money is kept in this contract, only trasaction fee
        if (_amount > address(this).balance) {
            revert();
        }
        _sendTo.transfer(_amount);
    }

    function getRandom(address _player, uint _block, uint _seed, uint _count) constant public returns(uint) {
        return uint(keccak256(abi.encodePacked(blockhash(_block), _player, _seed, _count)));
    }

    function catchMonster(address _player, uint32 _classId, string _name) onlyModerators external payable returns(uint tokenId) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (class.classId, class.price, class.returnPrice, class.total, class.catchable) = data.getMonsterClass(_classId);

        if (class.classId == 0 || class.catchable == false) {
            revert();
        }

        uint price = class.price;
        if (class.total > 0)
            price += class.price*(class.total-1)/priceIncreasingRatio;
        if (msg.value + gapFactor < price) {
            revert();
        }

        // add new monster
        uint64 objId = data.addMonsterObj(_classId, _player, _name);
        uint8 value;
        seed = getRandom(_player, block.number, seed, objId);
        // generate base stat for the previous one
        for (uint i=0; i < STAT_COUNT; i+= 1) {
            value = uint8(seed % STAT_MAX) + data.getElementInArrayType(ArrayType.STAT_START, uint64(_classId), i);
            data.addElementToArrayType(ArrayType.STAT_BASE, objId, value);
        }

        emit Transfer(address(0), _player, objId);

        return objId;
    }

    // public
    function getPrice(uint32 _classId) constant external returns(bool catchable, uint price) {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterClassAcc memory class;
        (class.classId, class.price, class.returnPrice, class.total, class.catchable) = data.getMonsterClass(_classId);

        price = class.price;
        if (class.total > 0)
            price += class.price*(class.total-1)/priceIncreasingRatio;

        return (class.catchable, price);
    }
}

contract Utils {

    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    uint  constant internal PRECISION = (10**18);
    uint  constant internal MAX_QTY   = (10**28); // 10B tokens
    uint  constant internal MAX_RATE  = (PRECISION * 10**6); // up to 1M tokens per ETH
    uint  constant internal MAX_DECIMALS = 18;
    uint  constant internal ETH_DECIMALS = 18;
    mapping(address=>uint) internal decimals;

    function setDecimals(ERC20 token) internal {
        if (token == ETH_TOKEN_ADDRESS) decimals[token] = ETH_DECIMALS;
        else decimals[token] = token.decimals();
    }

    function getDecimals(ERC20 token) internal view returns(uint) {
        if (token == ETH_TOKEN_ADDRESS) return ETH_DECIMALS; // save storage access
        uint tokenDecimals = decimals[token];
        // technically, there might be token with decimals 0
        // moreover, very possible that old tokens have decimals 0
        // these tokens will just have higher gas fees.
        if(tokenDecimals == 0) return token.decimals();

        return tokenDecimals;
    }

    function calcDstQty(uint srcQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns(uint) {
        require(srcQty <= MAX_QTY);
        require(rate <= MAX_RATE);

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            return (srcQty * rate * (10**(dstDecimals - srcDecimals))) / PRECISION;
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            return (srcQty * rate) / (PRECISION * (10**(srcDecimals - dstDecimals)));
        }
    }

    function calcSrcQty(uint dstQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns(uint) {
        require(dstQty <= MAX_QTY);
        require(rate <= MAX_RATE);
        
        //source quantity is rounded up. to avoid dest quantity being too low.
        uint numerator;
        uint denominator;
        if (srcDecimals >= dstDecimals) {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            numerator = (PRECISION * dstQty * (10**(srcDecimals - dstDecimals)));
            denominator = rate;
        } else {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            numerator = (PRECISION * dstQty);
            denominator = (rate * (10**(dstDecimals - srcDecimals)));
        }
        return (numerator + denominator - 1) / denominator; //avoid rounding down errors
    }
}

contract Utils2 is Utils {

    /// @dev get the balance of a user.
    /// @param token The token type
    /// @return The balance
    function getBalance(ERC20 token, address user) public view returns(uint) {
        if (token == ETH_TOKEN_ADDRESS)
            return user.balance;
        else
            return token.balanceOf(user);
    }

    function getDecimalsSafe(ERC20 token) internal returns(uint) {

        if (decimals[token] == 0) {
            setDecimals(token);
        }

        return decimals[token];
    }

    function calcDestAmount(ERC20 src, ERC20 dest, uint srcAmount, uint rate) internal view returns(uint) {
        return calcDstQty(srcAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcSrcAmount(ERC20 src, ERC20 dest, uint destAmount, uint rate) internal view returns(uint) {
        return calcSrcQty(destAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcRateFromQty(uint srcAmount, uint destAmount, uint srcDecimals, uint dstDecimals)
        internal pure returns(uint)
    {
        require(srcAmount <= MAX_QTY);
        require(destAmount <= MAX_QTY);

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            return (destAmount * PRECISION / ((10 ** (dstDecimals - srcDecimals)) * srcAmount));
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            return (destAmount * PRECISION * (10 ** (srcDecimals - dstDecimals)) / srcAmount);
        }
    }
}

contract WrapEtheremon is Utils2 {
    event SwapTokenChange(uint balanceBefore, uint balanceAfter, uint change);
    event EtherChange(address indexed sender, uint amount);

    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    /// @dev Contract contstructor
    constructor () public { }

    /// @dev Return the ETH to user that was taken back by the network
    function() public payable {
        msg.sender.transfer(msg.value);
        emit EtherChange(msg.sender, msg.value);
    }

    /// @dev Get the token price equivalent of the Etheremon monster
    /// @param _kyber KyberNetworkProxyInterface address
    /// @param _etheremon EtheremonExternalPayment address
    /// @param token ERC20 token address
    /// @param _classId Class ID of monster
    /// @return expectedRate, slippageRate, tokenPrice
    function getMonsterPriceInTokens(
        KyberNetworkProxyInterface _kyber,
        EtheremonExternalPayment _etheremon,
        ERC20 token,
        uint32 _classId
    )
        public
        view
        returns (
          uint expectedRate,
          uint slippageRate,
          uint tokenPrice
        )
    {
        bool catchable;
        uint ethValue;

        (catchable, ethValue) = _etheremon.getPrice(_classId);
        (expectedRate, slippageRate) = _kyber.getExpectedRate(ETH_TOKEN_ADDRESS, token, ethValue);
        tokenPrice = calcDestAmount(ETH_TOKEN_ADDRESS, token, ethValue, expectedRate);

        return (expectedRate, slippageRate, tokenPrice);
    }

    /// @dev Acquires the monster from Etheremon using tokens
    /// @param _kyber KyberNetworkProxyInterface address
    /// @param _etheremon EtheremonExternalPayment address
    /// @param _classId Class ID of monster
    /// @param _name Name of the monster
    /// @param token ERC20 token address
    /// @param tokenQty Amount of tokens required to acquire the monster
    /// @param maxDestQty Limit on the amount of destination tokens
    /// @param minRate Minimum conversion rate
    /// @param walletId Wallet ID where Kyber referral fees will be sent to
    /// @return monsterId
    function catchMonster(
        KyberNetworkProxyInterface _kyber,
        EtheremonExternalPayment _etheremon,
        uint32 _classId,
        string _name,
        ERC20 token,
        uint tokenQty,
        uint maxDestQty,
        uint minRate,
        address walletId
    )
        public
        returns (uint monsterId)
    {
        address kyberAddress = address(_kyber);
        uint tokenPrice;

        // Get the starting token balance of the player's wallet
        uint startTokenBalance = token.balanceOf(this);

        // Check that the player has transferred the token to this contract
        require(token.transferFrom(msg.sender, this, tokenQty));

        // Mitigate ERC20 Approve front-running attack, by initially setting
        // allowance to 0
        token.approve(kyberAddress, 0);

        // Verify that the token balance has not decreased from front-running
        require(token.balanceOf(this) == startTokenBalance);

        // Once verified, set the token allowance to tokenQty
        token.approve(kyberAddress, tokenQty);

        // Get the current price of the monster
        (,tokenPrice) = getMonsterPriceInTokens(_kyber, _etheremon, token, _classId);

        // Swap player's token to ETH to send to Etheremon payments contract
        uint destAmount = _kyber.tradeWithHint(token, tokenQty, ETH_TOKEN_ADDRESS, address(this), maxDestQty, minRate, walletId, "");

        // Check that destAmount >= tokenPrice
        require(destAmount >= tokenPrice);

        // Acquire the monster and send to player
        monsterId = _etheremon.catchMonster.value(destAmount)(msg.sender, _classId, _name);

        // Return change to player if any
        calcPlayerChange(token, startTokenBalance);

        return monsterId;
    }

    /// @dev Calculates token change and returns to player
    /// @param token ERC20 token address
    /// @param startTokenBalance Starting token balance of the player's wallet
    function calcPlayerChange(ERC20 token, uint startTokenBalance) private {
        // Calculate change of player
        uint change = token.balanceOf(this) - startTokenBalance;

        // Log the exchange event
        emit SwapTokenChange(startTokenBalance, token.balanceOf(this), change);

        // Transfer change back to player
        token.transfer(msg.sender, change);
    }
}