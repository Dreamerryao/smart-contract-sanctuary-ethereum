pragma solidity ^0.4.25;

/**
 * Definition of contract accepting THC tokens
 * Games, casinos, anything can reuse this contract to support AcceptsTHC tokens
 * ...
 * M3Divval
 * ...
 */
contract AcceptsTHC {
    Prosperity public tokenContract;

    constructor(address _tokenContract) public {
        tokenContract = Prosperity(_tokenContract);
    }

    modifier onlyTokenContract {
        require(msg.sender == address(tokenContract));
        _;
    }

    /**
    * @dev Standard ERC677 function that will handle incoming token transfers.
    *
    * @param _from  Token sender address.
    * @param _value Amount of tokens.
    * @param _data  Transaction metadata.
    */
    function tokenFallback(address _from, uint256 _value, bytes _data) external returns (bool);
}

contract Prosperity {
    /*=================================
    =            MODIFIERS            =
    =================================*/
    // only people with tokens
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }
    
    // only people with profits
    modifier onlyStronghands() {
        require(myDividends(true) > 0);
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
        require(administrator == _customerAddress);
        _;
    }
    
    
    // ensures that the first tokens in the contract will be equally distributed
    // meaning, no divine dump will be ever possible
    // result: healthy longevity.
    modifier antiEarlyWhale(uint256 _amountOfEthereum){
        address _customerAddress = msg.sender;
        
        // are we still in the vulnerable phase?
        // if so, enact anti early whale protocol 
        if( onlyAmbassadors && ((totalEthereumBalance() - _amountOfEthereum) <= ambassadorQuota_ )){
            require(
                // is the customer in the ambassador list?
                ambassadors_[_customerAddress] == true &&
                
                // does the customer purchase exceed the max ambassador quota?
                (ambassadorAccumulatedQuota_[_customerAddress] + _amountOfEthereum) <= ambassadorMaxPurchase_
                
            );
            
            // updated the accumulated quota    
            ambassadorAccumulatedQuota_[_customerAddress] = SafeMath.add(ambassadorAccumulatedQuota_[_customerAddress], _amountOfEthereum);
        
            // execute
            _;
        } else {
            // in case the ether count drops low, the ambassador phase won't reinitiate
            onlyAmbassadors = false;
            _;    
        }
    }
    
    
    /*==============================
    =            EVENTS            =
    ==============================*/
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingEthereum,
        uint256 tokensMinted,
        address indexed referredBy
    );
    
    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 ethereumEarned
    );
    
    event onReinvestment(
        address indexed customerAddress,
        uint256 ethereumReinvested,
        uint256 tokensMinted
    );
    
    event onWithdraw(
        address indexed customerAddress,
        uint256 ethereumWithdrawn
    );
    
    // ERC20
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
    
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "The HODL Community";
    string public symbol = "THC";
    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee_ = 17;	// 17% divvies
	uint8 constant internal fundFee_ = 3; 		// 3% investment fund fee on each buy/sell
	uint8 constant internal referralBonus_ = 5;
    uint256 constant internal tokenPriceInitial_ = 0.0000000069 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.000000000420 ether;
    uint256 constant internal magnitude = 2**64;
	
	// Address to send the 3% fee
    // https://etherscan.io/address/0x6bca7e1EC8595B2f0F4D7Ff578F1D25643004825
    address constant public giveEthFundAddress = 0x6bca7e1EC8595B2f0F4D7Ff578F1D25643004825;
    uint256 internal totalEthFundReceived; 		// total ETH received from this contract
    uint256 internal totalEthFundCollected; 	// total ETH collected in this contract
    
    // proof of stake (defaults at 100 tokens)
    uint256 public stakingRequirement = 20e18;
    
    // ambassador program
    mapping(address => bool) internal ambassadors_;
    uint256 constant internal ambassadorMaxPurchase_ = 2 ether;
    uint256 constant internal ambassadorQuota_ = 12 ether;
    
    
   /*================================
    =            DATASETS            =
    ================================*/
    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
	mapping(address => address) internal lastRef_;
    mapping(address => uint256) internal ambassadorAccumulatedQuota_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
    
    // administrator (see above on what they can do)
    address internal administrator;
    
    // when this is set to true, only ambassadors can purchase tokens (this prevents a whale premine, it ensures a fairly distributed upper pyramid)
    bool public onlyAmbassadors = true;
	
	// Special THC Platform control from scam game contracts on THC platform
    mapping(address => bool) public canAcceptTokens_; // contracts, which can accept THC tokens


    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /*
    * -- APPLICATION ENTRY POINTS --  
    */
    constructor()
        public
    {
        // add administrators here
        administrator = 0x6bca7e1EC8595B2f0F4D7Ff578F1D25643004825;
        
        // add the ambassadors here.
        ambassadors_[0x6bca7e1EC8595B2f0F4D7Ff578F1D25643004825] = true;	// tz
        ambassadors_[0x6134DD437C51423410BE01aBB8D7CEe427B90481] = true;	// fz
		ambassadors_[0x13f168168E2dB70679a59A191AFb62111D4142Ec] = true;	// jp
		ambassadors_[0xB62E2dcBf305ef0735b30F090C5822cA7CD07f65] = true;	// ds
		ambassadors_[0xd2e67b7678c2AFEe6C3Bf3E698Aa19F1d6fc0746] = true;	// ls
    }
    
     
    /**
     * Converts all incoming ethereum to tokens for the caller, and passes down the referral
     */
    function buy(address _referredBy)
        public
        payable
        returns(uint256)
    {
		address _lastRef = handleLastRef(_referredBy);
        purchaseTokens(msg.value, _lastRef);
    }
    
    /**
     * Fallback function to handle ethereum that was send straight to the contract
     * Unfortunately we cannot use a referral address this way.
     */
    function()
        payable
        public
    {
		address lastRef = handleLastRef(address(0));	// hopefully you used a referral somewhere in the past
        purchaseTokens(msg.value, lastRef);
    }
    
    /**
     * Converts all of caller's dividends to tokens.
     */
    function reinvest()
        onlyStronghands()
        public
    {
        // fetch dividends
        uint256 _dividends = myDividends(false); // retrieve ref. bonus later in the code
        
        // pay out the dividends virtually
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        
        // retrieve ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        
        // dispatch a buy order with the virtualized "withdrawn dividends"
		address _lastRef = handleLastRef(address(0));	// hopefully you used a referral somewhere in the past
        uint256 _tokens = purchaseTokens(_dividends, _lastRef);
        
        // fire event
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }
    
    /**
     * Alias of sell() and withdraw().
     */
    function exit()
        public
    {
        // get token count for caller & sell them all
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if(_tokens > 0) sell(_tokens);
        
        // lambo delivery service
        withdraw();
    }

    /**
     * Withdraws all of the callers earnings.
     */
    function withdraw()
        onlyStronghands()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false); // get ref. bonus later in the code
        
        // update dividend tracker
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        
        // add ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        
        // lambo delivery service
        _customerAddress.transfer(_dividends);
        
        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }
    
    /**
     * Liquifies tokens to ethereum.
     */
    function sell(uint256 _amountOfTokens)
        onlyBagholders()
        public
    {
        // setup data
        address _customerAddress = msg.sender;
        // russian hackers BTFO
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _ethereum = tokensToEthereum_(_tokens);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);				// 17%
		uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundFee_), 100);					// 3%
        uint256 _taxedEthereum =  SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _fundPayout);	// Take out dividends and then _fundPayout
		
		// Add ethereum for fund
        totalEthFundCollected = SafeMath.add(totalEthFundCollected, _fundPayout);
        
        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        
        // update dividends tracker
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEthereum * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;
        
        // dividing by zero is a bad idea
        if (tokenSupply_ > 0) {
            // update the amount of dividends per token
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }
        
        // fire event
        emit onTokenSell(_customerAddress, _tokens, _taxedEthereum);
    }
    
    
    /**
     * Transfer tokens from the caller to a new holder.
     * Remember, there's 0% fee here.
     */
    function transfer(address _toAddress, uint256 _amountOfTokens)
        onlyBagholders()
        public
        returns(bool)
    {
        // setup
        address _customerAddress = msg.sender;
        
        // make sure we have the requested tokens
        // also disables transfers until ambassador phase is over
        // ( we dont want whale premines )
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        
        // withdraw all outstanding dividends first
        if(myDividends(true) > 0) withdraw();

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);
		
		// update dividend trackers
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);
        
        // fire event
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        
        // ERC20
        return true;
    }
	
	/**
    * Transfer token to a specified address and forward the data to recipient
    * ERC-677 standard
    * https://github.com/ethereum/EIPs/issues/677
    * @param _to    Receiver address.
    * @param _value Amount of tokens that will be transferred.
    * @param _data  Transaction metadata.
    */
    function transferAndCall(address _to, uint256 _value, bytes _data)
		external 
		returns (bool) 
	{
		require(_to != address(0));
		require(canAcceptTokens_[_to] == true); 	// security check that contract approved by THC platform
		require(transfer(_to, _value)); 			// do a normal token transfer to the contract

		if (isContract(_to)) {
			AcceptsTHC receiver = AcceptsTHC(_to);
			require(receiver.tokenFallback(msg.sender, _value, _data));
		}

		return true;
    }

    /**
     * Additional check that the game address we are sending tokens to is a contract
     * assemble the given address bytecode. If bytecode exists then the _addr is a contract.
     */
     function isContract(address _addr) 
		private 
		constant 
		returns (bool is_contract) 
	{
		// retrieve the size of the code on target address, this needs assembly
		uint length;
		assembly { length := extcodesize(_addr) }
		return length > 0;
     }
	 
    
    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/	
    /**
     * In case the amassador quota is not met, the administrator can manually disable the ambassador phase.
     */
    function disableInitialStage()
        onlyAdministrator()
        public
    {
        onlyAmbassadors = false;
    }
	
	/**
     * Sends FUND money to the Fund Contract
     * The address is here https://etherscan.io/address/0x6bca7e1EC8595B2f0F4D7Ff578F1D25643004825
     */
    function payFund()
		onlyAdministrator()
		public 
	{
		uint256 ethToPay = SafeMath.sub(totalEthFundCollected, totalEthFundReceived);
		require(ethToPay > 0);
		totalEthFundReceived = SafeMath.add(totalEthFundReceived, ethToPay);
      
		if(!giveEthFundAddress.call.value(ethToPay).gas(400000)()) {
			totalEthFundReceived = SafeMath.sub(totalEthFundReceived, ethToPay);
		}
    }
    
    /**
     * In case one of us dies, we need to replace ourselves.
     */
    function setAdministrator(address _identifier)
        onlyAdministrator()
        public
    {
        administrator = _identifier;
    }
	
	/**
     * Only Add game contract, which can accept THC tokens.
	 * Disabling a contract is not possible after activating
     */
    function setCanAcceptTokens(address _address)
      onlyAdministrator()
      public
    {
      canAcceptTokens_[_address] = true;
    }
    
    /**
     * Precautionary measures in case we need to adjust the masternode rate.
     */
    function setStakingRequirement(uint256 _amountOfTokens)
        onlyAdministrator()
        public
    {
        stakingRequirement = _amountOfTokens;
    }
    
    /**
     * If we want to rebrand, we can.
     */
    function setName(string _name)
        onlyAdministrator()
        public
    {
        name = _name;
    }
    
    /**
     * If we want to rebrand, we can.
     */
    function setSymbol(string _symbol)
        onlyAdministrator()
        public
    {
        symbol = _symbol;
    }

    
    /*----------  HELPERS AND CALCULATORS  ----------*/
    /**
     * Method to view the current Ethereum stored in the contract
     * Example: totalEthereumBalance()
     */
    function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return address(this).balance;
    }
    
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
     * Retrieve the dividends owned by the caller.
     * If `_includeReferralBonus` is to to 1/true, the referral bonus will be included in the calculations.
     * The reason for this, is that in the frontend, we will want to get the total divs (global + ref)
     * But in the internal calculations, we want them separate. 
     */ 
    function myDividends(bool _includeReferralBonus) 
        public 
        view 
        returns(uint256)
    {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress) ;
    }
	
	/**
	 * Retrieve the last used referral address of the given address
	 */
	function myLastRef(address _addr)
		public
		view
		returns(address)
	{
		return lastRef_[_addr];
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
     * Retrieve the dividend balance of any single address.
     */
    function dividendsOf(address _customerAddress)
        view
        public
        returns(uint256)
    {
        return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
    }
    
    /**
     * Return the buy price of 1 individual token.
     */
    function sellPrice() 
        public 
        view 
        returns(uint256)
    {
        // our calculation relies on the token supply, so we need supply. Doh.
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
			uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundFee_), 100);
            uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _fundPayout);
            return _taxedEthereum;
        }
    }
    
    /**
     * Return the sell price of 1 individual token.
     */
    function buyPrice() 
        public 
        view 
        returns(uint256)
    {
        // our calculation relies on the token supply, so we need supply. Doh.
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ethereum = tokensToEthereum_(1e18);
            uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);
			uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundFee_), 100);
            uint256 _taxedEthereum =  SafeMath.add(SafeMath.add(_ethereum, _dividends), _fundPayout);
            return _taxedEthereum;
        }
    }
    
    /**
     * Function for the frontend to dynamically retrieve the price scaling of buy orders.
     */
    function calculateTokensReceived(uint256 _ethereumToSpend) 
        public 
        view 
        returns(uint256)
    {
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereumToSpend, dividendFee_), 100);			// 17%
		uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereumToSpend, fundFee_), 100);				// 3%
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereumToSpend, _dividends), _fundPayout); // 80%
        uint256 _amountOfTokens = ethereumToTokens_(_taxedEthereum);
        return _amountOfTokens;
    }
    
    /**
     * Function for the frontend to dynamically retrieve the price scaling of sell orders.
     */
    function calculateEthereumReceived(uint256 _tokensToSell) 
        public 
        view 
        returns(uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ethereum = tokensToEthereum_(_tokensToSell);
        uint256 _dividends = SafeMath.div(SafeMath.mul(_ethereum, dividendFee_), 100);				// 17%
		uint256 _fundPayout = SafeMath.div(SafeMath.mul(_ethereum, fundFee_), 100);					// 3%
        uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_ethereum, _dividends), _fundPayout);	// 80%
        return _taxedEthereum;
    }
	
	/**
     * Function for the frontend to show ether waiting to be send to fund in contract
     */
    function etherToSendFund()
        public
        view
        returns(uint256)
	{
        return SafeMath.sub(totalEthFundCollected, totalEthFundReceived);
    }
    
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
	function handleLastRef(address _ref)
		internal 
		returns(address)
	{
		address _customerAddress = msg.sender;			// sender
		address _lastRef = lastRef_[_customerAddress];	// last saved ref
		
		// no cheating by referring yourself
		if (_ref == _customerAddress) {
			return _lastRef;
		}
		
		// try to use last ref of customer
		if (_ref == address(0)) {
			return _lastRef;
		} else {
			// new ref is another address, replace 
			if (_ref != _lastRef) {
				lastRef_[_customerAddress] = _ref;	// save new ref for next time
				return _ref;						// return new ref
			} else {
				return _lastRef;					// return last used ref
			}
		}
	}
	
    function purchaseTokens(uint256 _incomingEthereum, address _referredBy)
        antiEarlyWhale(_incomingEthereum)
        internal
        returns(uint256)
    {
        // data setup
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(SafeMath.mul(_incomingEthereum, dividendFee_), 100);				// 17%
		uint256 _fundPayout = SafeMath.div(SafeMath.mul(_incomingEthereum, fundFee_), 100);							// 3%
		uint256 _referralPayout = SafeMath.div(SafeMath.mul(_incomingEthereum, referralBonus_), 100);				// 5%
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralPayout);									// 12% => 17% - 5%
        //uint256 _taxedEthereum = SafeMath.sub(SafeMath.sub(_incomingEthereum, _undividedDividends), _fundPayout);	// 80%
        totalEthFundCollected = SafeMath.add(totalEthFundCollected, _fundPayout);
		
		// _taxedEthereum should be used, but stack is too deep here
        uint256 _amountOfTokens = ethereumToTokens_(SafeMath.sub(SafeMath.sub(_incomingEthereum, _undividedDividends), _fundPayout));
        uint256 _fee = _dividends * magnitude;
 
        // no point in continuing execution if OP is a poorfag russian hacker
        // prevents overflow in the case that the pyramid somehow magically starts being used by everyone in the world
        // (or hackers)
        // and yes we know that the safemath function automatically rules out the "greater then" equasion.
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        
        // is the user referred by a masternode?
        if(
            // is this a referred purchase?
            _referredBy != 0x0000000000000000000000000000000000000000 &&

            // no cheating!
            _referredBy != _customerAddress &&
            
            // does the referrer have at least X whole tokens?
            // i.e is the referrer a godly chad masternode
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ){
            // wealth redistribution
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralPayout);
        } else {
            // no ref purchase
            // add the referral bonus back to the global dividends cake
            _dividends = SafeMath.add(_dividends, _referralPayout);
            _fee = _dividends * magnitude;
        }
        
        // we can't give people infinite ethereum
        if(tokenSupply_ > 0){
            
            // add tokens to the pool
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
 
            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));
            
            // calculate the amount of tokens the customer receives over his purchase 
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));
        
        } else {
            // add tokens to the pool
            tokenSupply_ = _amountOfTokens;
        }
        
        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        
        // Tells the contract that the buyer doesn't deserve dividends for the tokens before they owned them;
        // really i know you think you do but you don't
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;
        
        // fire event
        emit onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, _referredBy);
        
        return _amountOfTokens;
    }

    /**
     * Calculate Token price based on an amount of incoming ethereum
     * It's an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function ethereumToTokens_(uint256 _ethereum)
        internal
        view
        returns(uint256)
    {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokenPriceIncremental = tokenPriceIncremental_ * 1e18;
        uint256 _tokenSupply = tokenSupply_ / 1e18;
        uint256 _tokensReceived = 
         (
            (
                // underflow attempts BTFO
                SafeMath.sub(
                    (sqrt
                        (
                            1e36*((_tokenPriceInitial)**2)
                            +
                            1e36*(2*(_tokenPriceIncremental)*((_ethereum) * 1e18))
                            +
                            1e36*(((_tokenPriceIncremental)**2)*(_tokenSupply**2))
                            +
                            1e36*(2*(_tokenPriceIncremental)*(_tokenPriceInitial)*(_tokenSupply))
                        )
                    ), ((_tokenPriceInitial)*1e18)
                )
            )/(_tokenPriceIncremental)
        )-((_tokenSupply)*1e18)
        ;
  
        return _tokensReceived;
    }
    
    /**
     * Calculate token sell value.
     * It's an algorithm, hopefully we gave you the whitepaper with it in scientific notation;
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
     function tokensToEthereum_(uint256 _tokens)
        internal
        view
        returns(uint256)
    {

        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _etherReceived =
        (
            // underflow attempts BTFO
            SafeMath.sub(
                (
                    (
                        (
                            tokenPriceInitial_ +(tokenPriceIncremental_ * (_tokenSupply/1e18))
                        )-tokenPriceIncremental_
                    )*(tokens_ - 1e18)
                ),(tokenPriceIncremental_*((tokens_**2-tokens_)/1e18))/2
            )
        /1e18);
        return _etherReceived;
    }
    
    
    //This is where all your gas goes, sorry
    //Not sorry, you probably only paid 1 gwei
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
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