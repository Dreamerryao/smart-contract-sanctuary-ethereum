pragma solidity ^0.4.18;


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
	constructor() public {
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
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}
}

interface tokenRecipient {
	function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}
/*****
    * @title Basic Token
    * @dev Basic Version of a Generic Token
*/
contract ERC20BasicToken is Ownable{
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;
	
    // This creates an array with all balances
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;
	
    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
	
    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
	
    //Fix for the ERC20 short address attack.
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4) ;
        _;
	}
	
    /**
		* Internal transfer, only can be called by this contract
	*/
    function _transfer(address _from, address _to, uint _value)  internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balances[_from] >= _value);
        // Check for overflows
        require(balances[_to] + _value > balances[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balances[_from] + balances[_to];
        // Subtract from the sender
        balances[_from] -= _value;
        // Add the same to the recipient
        balances[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[_from] + balances[_to] == previousBalances);
	}
	
	
    /**
		* Transfer tokens from other address
		*
		* Send `_value` tokens to `_to` in behalf of `_from`
		*
		* @param _from The address of the sender
		* @param _to The address of the recipient
		* @param _value the amount to send
	*/
    function transferFrom(address _from, address _to, uint256 _value)  onlyPayloadSize(2 * 32) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
	}
	
    /**
		* Transfer tokens
		*
		* Send `_value` tokens to `_to` from your account
		*
		* @param _to The address of the recipient
		* @param _value the amount to send
	*/
    function transfer(address _to, uint256 _value)  onlyPayloadSize(2 * 32) public {
        _transfer(msg.sender, _to, _value);
	}
	
    /**
		* @notice Create `mintedAmount` tokens and send it to `target`
		* @param target Address to receive the tokens
		* @param mintedAmount the amount of tokens it will receive
	*/
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balances[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
	}
	
    /**
		* Set allowance for other address
		*
		* Allows `_spender` to spend no more than `_value` tokens in your behalf
		*
		* @param _spender The address authorized to spend
		* @param _value the max amount they can spend
	*/
    function approve(address _spender, uint256 _value) public
	returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
	}
	
    /**
		* Set allowance for other address and notify
		*
		* Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
		*
		* @param _spender The address authorized to spend
		* @param _value the max amount they can spend
		* @param _extraData some extra information to send to the approved contract
	*/
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
	public
	returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
		}
	}
	
    /**
		* Destroy tokens
		*
		* Remove `_value` tokens from the system irreversibly
		*
		* @param _value the amount of money to burn
	*/
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
	}
	
    /**
		* Destroy tokens from other account
		*
		* Remove `_value` tokens from the system irreversibly on behalf of `_from`.
		*
		* @param _from the address of the sender
		* @param _value the amount of money to burn
	*/
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balances[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
	}
	
    /**
		* Return balance of an account
		* @param _owner the address to get balance
	*/
  	function balanceOf(address _owner) public constant returns (uint balance) {
  		return balances[_owner];
	}
	
    /**
		* Return allowance for other address
		* @param _owner The address spend to the other
		* @param _spender The address authorized to spend
	*/
  	function allowance(address _owner, address _spender) public constant returns (uint remaining) {
  		return allowance[_owner][_spender];
	}
}

/**
	* @title SafeMath
	* @dev Math operations with safety checks that throw on error
*/
library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}
	
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold
		return c;
	}
	
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}
	
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

/**
	* Store config of phase ICO
*/
contract PhaseBonus is Ownable {
	
	using SafeMath for uint256;
	address public icoContract;
	
	mapping(uint256 => mapping(uint256 => uint256))  phaseSale;
	mapping(uint256 => mapping(uint256 => uint256))  bonusSale;
	mapping(uint256 => uint256)  bonusAffiliate;
	mapping(address => uint256)  accountBonus;
	
	constructor() public{
		bonusSale[1][0] = 13; // Private Sale
		bonusSale[1][1] = 10; // Private Sale
		bonusSale[2][0] = 2; // Public Sale
		bonusAffiliate[1] = 2; // Private Sale
		bonusAffiliate[2] = 2; // Public Sale
		
		phaseSale[1][0] = 1531231200; // Private Sale
		phaseSale[1][1] = 1532959200; // Private Sale
		
		phaseSale[2][0] = 1533132000; // Public Sale
		phaseSale[2][1] = 1535637600; // Public Sale
	}
	
	function setBonusAffiliate(uint256 _phase,uint256 _value) public onlyOwner returns(bool){
	    require(_value>0);
	    bonusAffiliate[_phase] = _value;
	    return true;
	}
	
	function getBonusAffiliate(uint256 _phase) public constant returns(uint256){
	    require(_phase>0);
	    return  bonusAffiliate[_phase];
	}
	
	function setAccountBonus(address _address,uint256 _value) public returns(bool){
	    require(_address != address(0));
	    require(_value>=0);
        accountBonus[_address] = accountBonus[_address].add(_value);
	    return true;
	}
	
	/**
	* Get bonus balance of an account
	* @param _address - the address to get bonus of
	*/
	function getAccountBonus(address _address) public constant returns(uint256){
	     require(_address != address(0));
        return accountBonus[_address];
	}
	
	/**
	* Get the current ICO phase
	*/
	function getCurrentPhase() public constant returns(uint256) {
		uint256 phase = 0;
		if(now>=phaseSale[1][0] && now<phaseSale[1][1]){
			phase = 1;
		} else if (now>=phaseSale[2][0] && now<phaseSale[2][1]) {
			phase = 2;
		}
		return phase;
	}
	
	/**
	* Set phase
	* @param _phase - phase
	*/
	function setPhaseSale(uint256 _phase,uint256 _index, uint256 _timestaps) public onlyOwner returns(bool) {
		phaseSale[_phase][_index]=_timestaps;
		return true;
	}
	
	function getPhaseSale(uint256 _phase,uint256 _index) public constant returns(uint256){
	    require(_phase>0);
	    return phaseSale[_phase][_index];
	}
	
	function setBonusSale(uint256 _phase,uint256 _index, uint256 _bonus) public onlyOwner returns(bool){
	   bonusSale[_phase][_index] = _bonus;
	   return true;
	}
	
	function getBonusSale(uint256 _phase,uint256 _index) public constant returns(uint256){
	    require(_phase>0);
	    return bonusSale[_phase][_index];
	}
	
	function getCurrentBonus(bool _isCompany) public constant returns(uint256){
		uint256 isPhase = getCurrentPhase();
	    if(isPhase==1){
	        if(_isCompany){
                return bonusSale[isPhase][0];
	        }else{
	            return bonusSale[isPhase][1];
	        }
	    }else if(isPhase==2){
	        return bonusSale[isPhase][0];
	    }
		return 0;
	}
	

	/**
	* Set ICO Contract
	* @param _icoContract - ICO Contract address
	*/
	function setIcoContract(address _icoContract) public onlyOwner {
		if (_icoContract != address(0)) {
			icoContract = _icoContract;
		}
	}
}

// CGN Token
contract CGNToken is ERC20BasicToken {
	using SafeMath for uint256;
	
	string public constant name      = "CGN"; //tokens name
	string public constant symbol    = "CGN"; //token symbol
	uint256 public constant decimals = 18;    //token decimal
	string public constant version   = "1.0"; //tokens version
	
	address public icoContract;
	
	// constructor
	constructor() public {
		totalSupply = 500000000 * 10**decimals;
	}
	
	/**
		* Set ICO Contract for this token to make sure called by our ICO contract
		* @param _icoContract - ICO Contract address
	*/
	function setIcoContract(address _icoContract) public onlyOwner {
		if (_icoContract != address(0)) {
			icoContract = _icoContract;
		}
	}
	
	/**
		* Sell tokens when ICO. Only called by ICO Contract
		* @param _recipient - address send ETH to buy tokens
		* @param _value - amount of tokens
	*/
	function sell(address _recipient, uint256 _value) public  returns (bool success) {
		assert(_value > 0);
		require(msg.sender == icoContract);
		
		balances[_recipient] = balances[_recipient].add(_value);
		
		Transfer(0x0, _recipient, _value);
		return true;
	}
	
	/**
		* Sell tokens when we don't have enough token Only called by ICO Contract
		* @param _recipient - address send ETH to buy tokens
		* @param _value - amount of tokens
	*/
	function sellSpecialTokens(address _recipient, uint256 _value) public  returns (bool success) {
		assert(_value > 0);
		require(msg.sender == icoContract);
		
		balances[_recipient] = balances[_recipient].add(_value);
		totalSupply = totalSupply.add(_value);
		
		Transfer(0x0, _recipient, _value);
		return true;
	}
}

/**
	* This contract will send tokens when an account send eth
	* Note: before send eth to token, address has to be registered by registerRecipient function
*/
contract IcoContract is Ownable{
	using SafeMath for uint256;
	
	CGNToken cgnToken;
	address public tokenAddress;
	
	//IcoPhase icoPhase;
	//address public icoPhaseAddress;
	
	//Bonus bonus;
	address public bonusAddress;
	
	uint256 public minPrivateSaleBuy = 200 ether;
	uint256 private minPrivateSaleCompanyBuy = 8000 ether;
	uint256 private maxPrivateSaleBuy = 20000 ether;
	
	uint256 private affiliateRate = 2; //2% affilate
	uint256 private tokenExchangeRate = 2000;//1ETH=2000 tokens
	uint256 public constant decimals = 18;
	
	uint256 public tokenForPreSale    = 140000000 * 10**decimals;
	uint256 public tokenForPublicSale = 60000000 * 10**decimals;
	
	uint256 public tokenSoldInPreSale    = 0;
	uint256 public tokenSoldInPublicSale = 0;
	
	address public ethFundDeposit = 0x8B9BC17cda83E783701590A5ab8686eB8096cBe5;//multi-sig wallet
	
	bool public isFinalized;
	
	//constructor
	constructor(address _tokenAddress, address _icoPhaseAddress) public {
		tokenAddress = _tokenAddress;
		cgnToken = CGNToken(tokenAddress);
		//setIcoPhaseAddress(_icoPhaseAddress);
		//setBonusAddress(_bonusAddress);
		isFinalized=false;
	}
	
	/**
		* Set IcoPhase contract address
		* @param _icoPhaseAddress - IcoPhase Contract address
	*/
	/*function setIcoPhaseAddress(address _icoPhaseAddress) public onlyOwner {
		if (_icoPhaseAddress != address(0)) {
			icoPhaseAddress = _icoPhaseAddress;
			icoPhase = IcoPhase(icoPhaseAddress);
		}
	}*/
	/**
		* Get affiliate rate by level
	*/
	function getAffiliateRate() public constant returns (uint256) {
		return affiliateRate;
	}
	/**
		* Set affiliate rate
		* @param _rate - new rate
	*/
	function setAffiliateRate(uint256 _rate) public onlyOwner returns (bool) {
		affiliateRate = _rate;
		return true;
	}
	/**
		* Set Bonus contract address
		* @param _bonusAddress - Bonus Contract address
	*/
	/*function setBonusAddress(address _bonusAddress) public onlyOwner {
		if (_bonusAddress != address(0)) {
			bonusAddress = _bonusAddress;
			bonus = Bonus(bonusAddress);
		}
	}*/
	
	/**
		*	get minimum for private can buy	
	*/
	function getMinPrivateSaleBuy() public constant returns(uint256){
		return minPrivateSaleBuy;
	}
	
	/**
		*	set minimum for private can buy
		*	@param _minBuy - new value
	*/
	function setMinPrivateSaleBuy(uint256 _minBuy) public onlyOwner returns (bool){
		require (_minBuy>=0);
		minPrivateSaleBuy = _minBuy;
		return true;
	}
	
	/**
		*	get limit for private can buy
		*	
	*/
	function getMaxPrivateSaleBuy() public constant returns (uint256 maxBuy){
		maxBuy = maxPrivateSaleBuy;
	}
	
	/**
		*	set limit for private can buy
		*	@param _maxBuy - new value
	*/
	function setMaxPrivateSaleBuy(uint256 _maxBuy) public onlyOwner returns (bool){
		require (_maxBuy>=0);
		maxPrivateSaleBuy = _maxBuy;
		return true;
	}
	
	/**
		*	get min private of company for private can buy
		*
	*/
	function getMinPrivateSaleCompanyBuy() public constant returns (uint256 minBuy){
		minBuy = minPrivateSaleCompanyBuy;
	}
	
	/**
		*	set min private of company for private can buy
		*	@param	_minBuy - new value
	*/
	function setMinPrivateSaleCompanyBuy(uint256 _minBuy) public onlyOwner returns (bool){
		require (_minBuy>=0);
		minPrivateSaleCompanyBuy = _minBuy;
		return true;
	}
	
	/**
		* will be called when user send eth to buy token
	*/
	function () public payable{
		createTokens(msg.sender, msg.value);
	}
	
	function createTokens(address _sender, uint256 _value) internal{
		require (!isFinalized);
		require (_sender != address(0));
		/*uint256 phaseICO = icoPhase.getCurrentICOPhase();
		require (phaseICO!=0);
		
		uint256 tokens = SafeMath.mul(_value, tokenExchangeRate);
		uint256 tokenRemain = 0;
		if(phaseICO==1){
			require (_value>=minPrivateSaleBuy && _value<=maxPrivateSaleBuy);
			cgnToken.sell(msg.sender, tokens);
			tokenForPreSale = SafeMath.sub(tokenForPreSale,tokens);
		}
		ethFundDeposit.transfer(this.balance);
		*/
	}
	
	function finalize() external onlyOwner {
		require (!isFinalized);
		// move to operational
		isFinalized = true;
		ethFundDeposit.transfer(this.balance);
	}
	
	/**
		* Get amount of tokens that be sold
	*/
	function getTokenSold() public constant returns(uint256 tokenSold) {
		tokenSold = tokenSoldInPreSale.add(tokenSoldInPublicSale);
	}
	
	/**
		* Change multi-sig address, the address to receive ETH
		* @param _ethFundDeposit - new multi-sig address
	*/
	function setEthFundDeposit(address _ethFundDeposit) public onlyOwner returns (bool) {
		require(_ethFundDeposit != address(0));
		ethFundDeposit=_ethFundDeposit;
		return true;
	}
	
	
	/**
		* Set amount of tokens used to sell in presale
		* @param _tokenForPreSale - amount of tokens to sell
	*/
	function setTokenForPreSale(uint256 _tokenForPreSale) public onlyOwner returns (bool) {
		tokenForPreSale = _tokenForPreSale;
		return true;
	}
	
	/**
		* Set amount of tokens used to sell in publicSale
		* @param _tokenForPublicSale - amount of tokens to sell
	*/
	function setTokenForPublicSale(uint256 _tokenForPublicSale) public onlyOwner returns (bool) {
		tokenForPublicSale = _tokenForPublicSale;
		return true;
	}
	
	function getTokenExchangeRate() public constant returns (uint256) {
		return tokenExchangeRate;
	}
	/**
		* Set token exchange rate
		* @param _value - rate of eth-token
	*/
	function setTokenExchangeRate(uint256 _value) public onlyOwner returns (uint256) {
		require (_value>0);
		tokenExchangeRate = _value;
		return tokenExchangeRate;
	}
}