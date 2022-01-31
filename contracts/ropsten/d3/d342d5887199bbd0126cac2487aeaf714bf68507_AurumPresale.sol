pragma solidity 0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, ownership can be transferred in 2 steps (transfer-accept).
 */
contract Ownable {
    address ABYSS = address(0);

    address public owner;
    address public pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can do that.");
        _;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "Only nominated pretender can do that.");
        _;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function acceptOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = ABYSS;
    }
}


/**
 * @title ERC20 Token Standard Interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/**
 * @title Aurum Services Presale contract
 * @author Igor D&#235;min
 * @dev Presale accepting contributions only within a time frame and capped to specific amount.
 */
contract AurumPresale is Ownable {
    using SafeMath for uint256;

    // How many minimal token units a buyer gets per wei, presale rate (1:5000 x 1.5)
    uint256 public constant RATE = 7500;

    // presale cap, 7.5M tokens to be sold
    uint256 public constant CAP = 1000 ether;

    // The token being sold
    ERC20 public token;

    // Address where funds are collected
    address public wallet;

    // Crowdsale opening time
    uint256 public openingTime;

    // Crowdsale closing time
    uint256 public closingTime;

    // Amount of wei raised
    uint256 public totalRaised;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value wei paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    constructor(ERC20 _token, address _wallet, uint256 _openingTime, uint256 _closingTime) public {
        require(_token != ABYSS);
        require(_wallet != ABYSS);
        require(_openingTime >= now);
        require(_closingTime > _openingTime);

        token = _token;
        wallet = _wallet;
        openingTime = _openingTime;
        closingTime = _closingTime;

        require(token.balanceOf(msg.sender) >= 7500000e18);
    }

    modifier onlyWhileActive() {
        require(isActive(), "Presale has closed.");
        _;
    }

    /**
     * @dev Sets minimal participation threshold
     */
    modifier minThreshold(uint256 _amount) {
        require(msg.value >= _amount, "Not enough Ether provided.");
        _;
    }

    /**
     * @dev fallback function
     */
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
     * @dev Reclaim all ERC20 compatible tokens
     * @param _token ERC20 The address of the token contract
     */
    function reclaimToken(ERC20 _token) external onlyOwner {
        require(!isActive());
        uint256 tokenBalance = _token.balanceOf(this);
        require(_token.transfer(owner, tokenBalance));
    }

    /**
     * @dev Transfer all Ether held by the contract to the owner.
     */
    function reclaimEther() external onlyOwner {
        owner.transfer(address(this).balance);
    }

    function isActive() public view returns (bool) {
        return isOpen() && !capReached();
    }

    /**
     * @dev Token purchase
     * @param _beneficiary Address performing the token purchase
     */
    function buyTokens(address _beneficiary)
        public
        payable
        onlyWhileActive
        minThreshold(20 finney)
    {
        require(_beneficiary != ABYSS);

        uint256 weiRaised = msg.value;
        uint256 newRaised = totalRaised.add(weiRaised);

        bool overCapped = false;
        if (newRaised > CAP) {
           weiRaised = CAP.sub(totalRaised);
           overCapped = true;
        }

        // calculate token amount
        uint256 tokenAmount = getTokenAmount(weiRaised);

        // update sale progress
        totalRaised = totalRaised.add(weiRaised);

        require(token.transfer(_beneficiary, tokenAmount));
        emit TokenPurchase(msg.sender, _beneficiary, weiRaised, tokenAmount);

        if (overCapped) {
            uint256 refundValue = newRaised.sub(CAP);
            msg.sender.transfer(refundValue);
        }

        wallet.transfer(weiRaised);
    }

    /**
     * @dev Checks whether the period in which the presale is open has already elapsed.
     * @return Whether presale period has elapsed
     */
    function isOpen() internal view returns (bool) {
        return now >= openingTime && now <= closingTime;
    }

    /**
     * @dev Checks whether the cap has been reached.
     * @return Whether the cap was reached
     */
    function capReached() internal view returns (bool) {
        return totalRaised >= CAP;
    }

    /**
     * @dev Calculate amount of tokens.
     * @param _weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function getTokenAmount(uint256 _weiAmount) internal pure returns (uint256) {
        return _weiAmount.mul(RATE);
    }

}