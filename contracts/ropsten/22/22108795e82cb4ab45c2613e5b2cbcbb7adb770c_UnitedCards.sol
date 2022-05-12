pragma solidity ^0.4.24;

/*
*
* https://www.unitedetc.club/cards
* Card Flip Game that feeds the United ETC Lending Game    
*
*/

contract UnitedCards {
    /*=================================
    =        MODIFIERS        =
    =================================*/



    modifier onlyOwner(){

        require(msg.sender == dev);
        _;
    }


    /*==============================
    =            EVENTS            =
    ==============================*/
    event oncardPurchase(
        address customerAddress,
        uint256 incomingEthereum,
        uint256 card,
        uint256 newPrice
    );

    event onWithdraw(
        address customerAddress,
        uint256 ethereumWithdrawn
    );

    // ERC20
    event Transfer(
        address from,
        address to,
        uint256 card
    );
    
   event Random(
   address player, 
   uint256 result
   );


    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "United ETC Cards";
    string public symbol = "UEC";

    uint8 constant public promoterRate = 9;
    uint8 constant public subpromoterRate = 2;
    uint8 constant public ownerDivRate = 40;
    uint8 constant public distDivRate = 40;
    uint8 constant public referralRate = 5;
    uint8 constant public decimals = 18;
    uint256 public resetvalue = 975;
    uint public totalCardValue = 2.25 ether; // Make sure this is sum of constructor values
    uint256 randomizer = 9734953091;
    uint256 private randNonce = 0;
  /*================================
    =            DATASETS            =
    ================================*/

    mapping(uint => address) internal cardOwner;
    mapping(uint => uint) public cardPrice;
    mapping(uint => uint) internal cardPreviousPrice;
    mapping(address => uint) internal ownerAccounts;
    uint cardPriceIncrement = 225;
    uint public totalCards;
    

    address dev;
    address developer;
    address promoter;
    address subpromoter;
    address lendingcontract;
    
    
    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /*
    * -- APPLICATION ENTRY POINTS --
    */
    constructor()
        public
    {
        dev = msg.sender;
        developer = 0xf6cB996d03d8d9b6ee786e9EfefB69f16015913F;
        promoter = 0xf379B1eBF7BbA56eaE7EAf55C5EA6d547384c6De;
        subpromoter = 0x0414Bb9A5427FaA0E9EB7C2864342467DB764B46;
        lendingcontract = 0x160290dF5Db71887B4218136fB187654ff836cDC; // Money will be sent to the lending contract once in 24 hours and portion of it will be used for games bankroll
        
        totalCards = 9;

        cardOwner[0] = dev;
        cardPrice[0] = 0.05 ether;
        cardPreviousPrice[0] = cardPrice[0];

        cardOwner[1] = dev;
        cardPrice[1] = 0.10 ether;
        cardPreviousPrice[1] = cardPrice[1];

        cardOwner[2] = dev;
        cardPrice[2] = 0.15 ether;
        cardPreviousPrice[2] = cardPrice[2];

        cardOwner[3] = dev;
        cardPrice[3] = 0.20 ether;
        cardPreviousPrice[3] = cardPrice[3];

        cardOwner[4] = dev;
        cardPrice[4] = 0.25 ether;
        cardPreviousPrice[4] = cardPrice[4];

        cardOwner[5] = dev;
        cardPrice[5] = 0.30 ether;
        cardPreviousPrice[5] = cardPrice[5];

        cardOwner[6] = dev;
        cardPrice[6] = 0.35 ether;
        cardPreviousPrice[6] = cardPrice[6];

        cardOwner[7] = dev;
        cardPrice[7] = 0.40 ether;
        cardPreviousPrice[7] = cardPrice[7];

        cardOwner[8] = dev;
        cardPrice[8] = 0.45 ether;
        cardPreviousPrice[8] = cardPrice[8];
}

    function addtotalCardValue(uint _new, uint _old)
    internal
    {
        uint newPrice = SafeMath.div(SafeMath.mul(_new,cardPriceIncrement),100);
        totalCardValue = SafeMath.add(totalCardValue, SafeMath.sub(newPrice,_old));
    }

    function buy(uint _card, address _referrer)
        public
        payable

    {
        require(_card < totalCards);
        require(msg.value == cardPrice[_card]);
        require(msg.sender != cardOwner[_card]);

        addtotalCardValue(msg.value, cardPreviousPrice[_card]);
        uint _newPrice = SafeMath.div(SafeMath.mul(msg.value, cardPriceIncrement), 100);
        uint _baseDividends = SafeMath.sub(msg.value, cardPreviousPrice[_card]);
        uint _promoterDividends = SafeMath.div(SafeMath.mul(_baseDividends, promoterRate),100);
        uint _subpromoterDividends = SafeMath.div(SafeMath.mul(_baseDividends, subpromoterRate),100);
        uint _ownerDividends = SafeMath.div(SafeMath.mul(_baseDividends, ownerDivRate), 100);
        _ownerDividends = SafeMath.add(_ownerDividends, cardPreviousPrice[_card]);
        uint _distDividends = SafeMath.div(SafeMath.mul(_baseDividends, distDivRate), 100);

        if (_referrer != msg.sender && _referrer != 0x0000000000000000000000000000000000000000) {

            uint _referralDividends = SafeMath.div(SafeMath.mul(_baseDividends, referralRate), 100);

            _distDividends = SafeMath.sub(_distDividends, _referralDividends);
            
            ownerAccounts[_referrer] = SafeMath.add(ownerAccounts[_referrer], _referralDividends);
        }

        address _previousOwner = cardOwner[_card];
        address _newOwner = msg.sender;
        ownerAccounts[_previousOwner] = SafeMath.add(ownerAccounts[_previousOwner], _ownerDividends);
        developer.transfer(_promoterDividends);
        promoter.transfer(_promoterDividends);
        subpromoter.transfer(_subpromoterDividends);
        lendingcontract.transfer(_distDividends);
        cardPreviousPrice[_card] = msg.value;
        cardPrice[_card] = _newPrice;
        cardOwner[_card] = _newOwner;
        emit oncardPurchase(msg.sender, msg.value, _card, SafeMath.div(SafeMath.mul(msg.value, cardPriceIncrement), 100));
}

function withdraw()

        public
    {
        address _customerAddress = msg.sender;
        require(ownerAccounts[_customerAddress] >= 0.001 ether);
        uint _dividends = ownerAccounts[_customerAddress];
        ownerAccounts[_customerAddress] = 0;
        _customerAddress.transfer(_dividends);
        uint256 random = getRandomNumber(msg.sender) + 1;
        if (random > resetvalue) {
        resetcardPrice();
        emit Random(msg.sender, random);
        }

        emit onWithdraw(_customerAddress, _dividends);
    }
    
    
    function playerwithdraw()

        public
    {
        address _customerAddress = msg.sender;
        require(ownerAccounts[_customerAddress] >= 0.001 ether);
        uint _dividends = ownerAccounts[_customerAddress];
        ownerAccounts[_customerAddress] = 0;
        _customerAddress.transfer(_dividends);
        emit onWithdraw(_customerAddress, _dividends);
    }



    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/
    function setName(string _name)
        onlyOwner()
        public
    {
        name = _name;
    }


    function setSymbol(string _symbol)
        onlyOwner()
        public
    {
        symbol = _symbol;
    }

    function setcardPrice(uint _card, uint _price)  
        onlyOwner()
        public
    {
         cardPrice[_card] = _price;
    }
    
    
    function settotalCardValue(uint _price)  
        onlyOwner()
        public
    {
         totalCardValue = _price;
    }
    
     function ResetCardPriceAdmin()  
        onlyOwner()
        public
    {
         resetcardPrice();
    }
    
     function resetcardPrice()   
        private
    {
        cardOwner[0] = dev;
        cardPrice[0] = 0.05 ether;
        cardPreviousPrice[0] = cardPrice[0];

        cardOwner[1] = dev;
        cardPrice[1] = 0.10 ether;
        cardPreviousPrice[1] = cardPrice[1];

        cardOwner[2] = dev;
        cardPrice[2] = 0.15 ether;
        cardPreviousPrice[2] = cardPrice[2];

        cardOwner[3] = dev;
        cardPrice[3] = 0.20 ether;
        cardPreviousPrice[3] = cardPrice[3];

        cardOwner[4] = dev;
        cardPrice[4] = 0.25 ether;
        cardPreviousPrice[4] = cardPrice[4];

        cardOwner[5] = dev;
        cardPrice[5] = 0.30 ether;
        cardPreviousPrice[5] = cardPrice[5];

        cardOwner[6] = dev;
        cardPrice[6] = 0.35 ether;
        cardPreviousPrice[6] = cardPrice[6];

        cardOwner[7] = dev;
        cardPrice[7] = 0.40 ether;
        cardPreviousPrice[7] = cardPrice[7];

        cardOwner[8] = dev;
        cardPrice[8] = 0.45 ether;
        cardPreviousPrice[8] = cardPrice[8];
        
        totalCardValue = 2.25 ether;
    }

     function setRandomizer(uint256 _Randomizer) public {
      require(msg.sender==dev);
      randomizer = _Randomizer;
    }
    
     function setResetvalue(uint256 _resetvalue) public {
      require(msg.sender==dev);
      resetvalue = _resetvalue;
    }
    
     function setPromoter(address _promoter) public {
      require(msg.sender==dev);
      promoter = _promoter;
    }
    
     function setSubPromoter(address _subpromoter) public {
      require(msg.sender==dev);
      subpromoter = _subpromoter;
    }
    
    function setLendingContract(address _lendingcontract) public {
      require(msg.sender==dev);
      lendingcontract = _lendingcontract;
    }
    
    function addNewcard(uint _price)
        onlyOwner()
        public
    {
        cardPrice[totalCards-1] = _price;
        cardOwner[totalCards-1] = dev;
        totalCards = totalCards + 1;
    }

   
    function getRandomNumber(address _addr) private returns(uint256 randomNumber) 
    {
        randNonce++;
        randomNumber = uint256(keccak256(abi.encodePacked(now, _addr, randNonce, randomizer, block.coinbase, block.number))) % 1000;
    }
   
    function getMyBalance()
        public
        view
        returns(uint)
    {
        return ownerAccounts[msg.sender];
    }

    function getOwnerBalance(address _cardOwner)
        public
        view
        returns(uint)
    {
        return ownerAccounts[_cardOwner];
    }

    function getcardPrice(uint _card)
        public
        view
        returns(uint)
    {
        require(_card < totalCards);
        return cardPrice[_card];
    }

    function getcardOwner(uint _card)
        public
        view
        returns(address)
    {
        require(_card < totalCards);
        return cardOwner[_card];
    }

  function totalEthereumBalance()
        public
        view
        returns(uint)
    {
        return address (this).balance;
    }

    function gettotalCards()
        public
        view
        returns(uint)
    {
        return totalCards;
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