pragma solidity ^0.4.25;


contract Prosperity {}


/**
 * Definition of contract accepting THC tokens
 * Games, casinos, anything can reuse this contract to support AcceptsProsperity tokens
 * ...
 * M3Divval
 * ...
 */
contract AcceptsProsperity {   
	
	/*==============================
    =            EVENTS            =
    ==============================*/    
    // ERC20
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
	
	
	/*=================================
    =            MODIFIERS            =
    =================================*/
    // only people with tokens
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }
	
	modifier onlyTokenContract {
        require(msg.sender == address(tokenContract));
        _;
    }
	
	// administrators can:
    // -> change the name of the contract
    // -> change the name of the token
    // -> change the PoS difficulty (How many tokens it costs to hold a masternode, in case it gets crazy high later)
    // they CANNOT:
    // -> take funds, except the funding contract
    // -> disable withdrawals
    // -> kill the contract
    // -> change the price of tokens
    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrator_ == _customerAddress);
        _;
    }
	
	
	/*================================
    =            DATASETS            =
    ================================*/
    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    uint256 internal tokenSupply_ = 0;
	
	// data
	Prosperity public tokenContract;
	
	// administrator (see above on what they can do)
    address internal administrator_;
    
	
	/*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    constructor() public {
        
		administrator_ = 0x6bca7e1EC8595B2f0F4D7Ff578F1D25643004825;
    }
	
	/**
    * @dev Standard ERC677 function that will handle incoming token transfers.
    *
    * @param _from  Token sender address.
    * @param _value Amount of tokens.
    * @param _data  Transaction metadata.
    */
    function tokenFallback(address _from, uint256 _value, bytes _data)
		external
		returns (bool)
	{
        // allocate tokens
        tokenBalanceLedger_[_from] = SafeMath.add(tokenBalanceLedger_[_from], _value);
		tokenSupply_ = SafeMath.add(tokenSupply_, _value);
		
		return true;
	}
	
	
	/*----------  HELPERS AND CALCULATORS  ----------*/    
    /**
     * Retrieve the total token supply.
     */
    function totalSupply()
        public
        view
        returns(uint256)
    {
        return tokenSupply_;
    }
	
	/**
     * Retrieve the tokens owned by the caller.
     */
    function myTokens()
        public
        view
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }
	
	/**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return tokenBalanceLedger_[_customerAddress];
    }
	
	/**
	 * Set the token contract
	 */
	function setTokenContract(address _tokenContract)
		onlyAdministrator()
		public
	{
		tokenContract = Prosperity(_tokenContract);
	}
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}