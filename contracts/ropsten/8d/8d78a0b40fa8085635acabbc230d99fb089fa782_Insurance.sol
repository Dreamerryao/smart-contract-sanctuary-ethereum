pragma solidity ^0.4.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }

}


/**
 * Safe unsigned safe math.
 *
 * https://blog.aragon.one/library-driven-development-in-solidity-2bebcaf88736#.750gwtwli
 *
 * Originally from https://raw.githubusercontent.com/AragonOne/zeppelin-solidity/master/contracts/SafeMathLib.sol
 *
 * Maintained here until merged to mainline zeppelin-solidity.
 *
 */
library SafeMathLibExt {

    function times(uint a, uint b) returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function divides(uint a, uint b) returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function minus(uint a, uint b) returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function plus(uint a, uint b) returns (uint) {
        uint c = a + b;
        assert(c>=a);
        return c;
    }

}


contract Destructable is Ownable {

    function burn() public onlyOwner {
        selfdestruct(owner);
    }

}


contract TokensContract {
    function balanceOf(address who) public constant returns (uint256);
}

contract Insurance is Destructable, SafeMath  {

    uint startClaimDate;
    uint endClaimDate;
    uint rewardWeiCoefficient;
    uint256 buyPrice;
    address tokensContractAddress;
    uint256 ichnDecimals;

    mapping (address => uint256) buyersBalances;

    struct ClientInsurance {
        uint256 tokensCount;
        bool isApplied;
        bool exists;
        bool isBlocked;
    }


    mapping(address => ClientInsurance) insurancesMap;


    function Insurance() public {
        tokensContractAddress = 0x89D642cFf8B6fa9C1A5C5D8208b4d5a496ebf2a8;

        /* Change it !!! */
        startClaimDate = 1533315600;
        endClaimDate = 1533319200;


        /* 0.1 ether */
        rewardWeiCoefficient = 100000000000000000;

        /* 0.05 ether */
        buyPrice = 50000000000000000;

        /* ICHN Token Decimals is 18 */
        ichnDecimals = 1000000000000000000;
    }

    /**
     * Don't expect to just send money by anyone except the owner
     */
    function () public payable {
        throw;
    }

    /**
     * Owner can send money
     */
    function addEth() public payable onlyOwner {
    }

    /**
     * Basic entry point for buy insurance
     */
    function buy() public payable {
        /* Can be called only once for address */
        require(buyersBalances[msg.sender] == 0);

        /* Checking price */
        require(msg.value == buyPrice);

        /* At least one token */
        require(hasTokens(msg.sender));

        /* Remember payment */
        buyersBalances[msg.sender] = safeAdd(buyersBalances[msg.sender], msg.value);
    }

    function isClient(address clientAddress) public constant onlyOwner returns(bool) {
        return insurancesMap[clientAddress].exists;
    }

    function addBuyer(address clientAddress, uint256 tokensCount) public onlyOwner {
        require( (clientAddress != address(0)) && (tokensCount > 0) );

        /* Checking payment */
        require(buyersBalances[clientAddress] == buyPrice);

        /* Can be called only once for address */
        require(!insurancesMap[clientAddress].exists);

        /* Checking the current number of tokens */
        require(getTokensCount(clientAddress) >= tokensCount);

        insurancesMap[clientAddress] = ClientInsurance(tokensCount, false, true, false);
    }

    function claim(address to, uint256 returnedTokensCount) public onlyOwner {
        /* Can be called only on time range */
        require(now > startClaimDate && now < endClaimDate);

        /* Can be called once for address */
        require( (to != address(0)) && (insurancesMap[to].exists) && (!insurancesMap[to].isApplied) && (!insurancesMap[to].isBlocked) );

        /* Tokens returned */
        require(returnedTokensCount >= insurancesMap[to].tokensCount);

        /* Start transfer */
        uint amount = getRewardWei(to);

        require(address(this).balance > amount);
        insurancesMap[to].isApplied = true;

        to.transfer(amount);
    }

    function blockClient(address clientAddress) public onlyOwner {
        insurancesMap[clientAddress].isBlocked = true;
    }

    function unblockClient(address clientAddress) public onlyOwner {
        insurancesMap[clientAddress].isBlocked = false;
    }

    function isClientBlocked(address clientAddress) public constant onlyOwner returns(bool) {
        return insurancesMap[clientAddress].isBlocked;
    }

    /**
     * Sets buy price for insurance
     */
    function setBuyPrice(uint256 priceWei) public onlyOwner {
        buyPrice = priceWei;
    }

    /**
     * Sets toknes contract address from which check balance of tokens
     */
    function setTokensContractAddress(address contractAddress) public onlyOwner {
        tokensContractAddress = contractAddress;
    }

    /**
     * Returns address of tokens contract from which check balance of tokens
     */
    function getTokensContractAddress() public constant onlyOwner returns(address) {
        return tokensContractAddress;
    }

    function getRewardWei(address clientAddress) private constant returns (uint256) {
        uint tokensCount = insurancesMap[clientAddress].tokensCount;
        return safeMul(tokensCount, rewardWeiCoefficient);
    }

    function hasTokens(address clientAddress) private constant returns (bool) {
        return getTokensCount(clientAddress) > 0;
    }

    function getTokensCount(address clientAddress) private constant returns (uint256) {
        TokensContract tokensContract = TokensContract(tokensContractAddress);

        uint256 tcBalance = tokensContract.balanceOf(clientAddress);

        return safeDiv(tcBalance, ichnDecimals);
    }
}