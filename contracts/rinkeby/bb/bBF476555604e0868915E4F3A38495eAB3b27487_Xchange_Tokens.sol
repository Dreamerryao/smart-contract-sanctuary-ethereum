/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
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

interface tokenInterface
{
   function transfer(address _to, uint _amount) external returns (bool);
   function transferFrom(address _from, address _to, uint _amount) external returns (bool);
   function balanceOf(address user) external view returns(uint);
}
interface IEACAggregatorProxy
{
    function latestAnswer() external view returns (uint256);
}

  contract Xchange_Tokens {

    using SafeMath for uint256;

    modifier onlyAdministrator(){
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress],"Caller must be admin");
        _;
    }

    /*==============================
    =            EVENTS           =
    ==============================*/


    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );

    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name ;
    uint256 public decimals = 18;
    address public tokenBUSDAddress;
    address public tokenMainAddress;
    address public EACAggregatorProxyAddress;
    uint256 public tokenSupply_ = 0;

    mapping(address => bool) internal administrators;

    address public terminal;


    uint256 public tokenPriceInitial_ = 1 * (10**(decimals-1));
    uint256 public tokenPriceIncremental_ = 0 * (10**(decimals-6));
    uint256 public currentPrice_  = (10**(decimals-1));
    uint256 public sellPrice  = (10**(decimals-1));
    uint public busdToMainTokenPercent = 1 * (10 ** (decimals-1));
    uint public base = 100 * (10 ** decimals);
    bool public isSell;

    constructor(string memory name_,address _tokenBUSDAddress,address _tokenMainAddress,address _EACAggregatorProxyAddress, uint256 _tokenPriceInitial,uint256 _tokenPriceIncremental)
    {
        name = name_;
        tokenPriceInitial_ = _tokenPriceInitial;
        tokenPriceIncremental_ = _tokenPriceIncremental;
        terminal = msg.sender;
        administrators[terminal] = true;
        tokenBUSDAddress = _tokenBUSDAddress;
        tokenMainAddress = _tokenMainAddress;
        //test -- 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        //main -- 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
        EACAggregatorProxyAddress = _EACAggregatorProxyAddress;
    }



    /*==========================================
    =            VIEW FUNCTIONS            =
    ==========================================*/

    function isContract(address _address) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }



    function BNBToBUSD(uint bnbAmount) public view returns(uint)
    {
        uint256  bnbpreice = IEACAggregatorProxy(EACAggregatorProxyAddress).latestAnswer();
        return bnbAmount * bnbpreice * (10 ** (decimals-8)) / (10 ** (decimals));
    }

    function BUSDToBNB(uint busdAmount) public view returns(uint)
    {
        uint256  bnbpreice = IEACAggregatorProxy(EACAggregatorProxyAddress).latestAnswer();
        return busdAmount  / bnbpreice * (10 ** (decimals-8));
    }

    function BUSDToToken(uint busdAmount) public view returns(uint)
    {
       return ((busdAmount / currentPrice_) * (10 ** decimals)) ;
    }

    function TokenToBUSD(uint TokenAmount) public view returns(uint)
    {
        return TokenAmount / (10**decimals) * currentPrice_;
    }
    function TokenToBNB(uint TokenAmount) public view returns(uint)
    {
        uint amt =  TokenToBUSD(TokenAmount);
        return BUSDToBNB(amt);
    }
    /*==========================================
    =            WRITE FUNCTIONS            =
    ==========================================*/

    event BuyToken(address _user,uint256 _amount,bool _isBnb, uint256 _currentPrice);
    function buy( uint256 tokenAmount) public payable returns(uint256)
    {
      bool isBNB;
      require(!isContract(msg.sender),  'No contract address allowed');
      require(tokenAmount > 0 || msg.value > 0, "invalid amount sent");
      if(tokenAmount > 0 )
      {
        tokenAmount = TokenToBUSD(tokenAmount);
        tokenInterface(tokenBUSDAddress).transferFrom(msg.sender, address(this), tokenAmount);
      }
      if(msg.value > 0)
      {
        isBNB =true;
        tokenAmount += BNBToBUSD(msg.value);
      }

      uint256 TokenPurchased = BUSDToToken(tokenAmount);
      currentPrice_ = currentPrice_ + tokenPriceIncremental_;
      tokenSupply_ = tokenSupply_.add(TokenPurchased);
      tokenInterface(tokenMainAddress).transfer(msg.sender, TokenPurchased);
      // fire event

      emit BuyToken(msg.sender, TokenPurchased, isBNB, currentPrice_);
      return TokenPurchased;
    }


    event Sell(address _user,uint256 _amount,bool _isBnb);
    function sell(uint256 _amountOfTokens, bool isBNB ) external
    {
        require(isSell,"Sell is not enabled");
        require(_amountOfTokens > 0, "Amount must be greater than zero");
        address _customerAddress = msg.sender;
        uint256 userbalance = tokenInterface(tokenMainAddress).balanceOf(_customerAddress);
        require(userbalance >= _amountOfTokens ,"Not enough balance");

        tokenInterface(tokenMainAddress).transferFrom(_customerAddress,address(this),_amountOfTokens);
        if(isBNB)
        {
            uint256 bnbamt = TokenToBNB(_amountOfTokens);
            require(address(this).balance > bnbamt ,"Not enough BNB balance");
            uint userbnb = bnbamt * 95 /100;
            uint adminfee = bnbamt * 5 /100;
            payable(_customerAddress).transfer(userbnb);
            payable(terminal).transfer(adminfee);
        }
        else
        {
            uint256 _busd = TokenToBUSD(_amountOfTokens) * sellPrice ;
            uint tokenBalance = tokenInterface(tokenBUSDAddress).balanceOf(address(this));
            require(tokenBalance > _busd,"Not enough BUSD balance");
            uint userbbusd = _busd * 95 /100;
            uint adminfee = _busd * 5 /100;
            tokenInterface(tokenBUSDAddress).transfer(_customerAddress,userbbusd);
            tokenInterface(tokenBUSDAddress).transfer(terminal,adminfee);
        }
        emit Sell(_customerAddress, _amountOfTokens, isBNB);
    }

      receive() external payable {
    }

    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/




    /*==========================================
    =            Admin FUNCTIONS            =
    ==========================================*/
    function adjustPrice(uint currenT, uint increamentaL) public onlyAdministrator returns(bool)
    {
        currentPrice_ = currenT;
        tokenPriceIncremental_ = increamentaL;
        return true;
    }
    function adjustSellPrice(uint _sellprice) public onlyAdministrator returns(bool)
    {
        sellPrice = _sellprice;
        return true;
    }

    function changeBUSDTokenAddress(address _tokenBUSDAddress) public onlyAdministrator returns(bool)
    {
        tokenBUSDAddress = _tokenBUSDAddress;
        return true;
    }

    function changeMainTokenAddress(address _tokenMainAddress) public onlyAdministrator returns(bool)
    {
        tokenMainAddress = _tokenMainAddress;
        return true;
    }

    function sendToOnlyExchangeContract() public onlyAdministrator returns(bool)
    {
        require(!isContract(msg.sender),  'No contract address allowed');
        payable(terminal).transfer(address(this).balance);
        uint tokenBalance = tokenInterface(tokenBUSDAddress).balanceOf(address(this));
        tokenInterface(tokenBUSDAddress).transfer(terminal, tokenBalance);
        return true;
    }
    function destruct() onlyAdministrator() public{
        selfdestruct(payable(terminal));
    }

    function setSell(bool _isSell) public onlyAdministrator returns(bool)
    {
        isSell = _isSell;
        return true;
    }
    function setTerminal(address _terminal) public onlyAdministrator returns(bool)
    {
        require(terminal != _terminal , 'Already set as admin');
        terminal = _terminal;
        administrators[terminal] = true;
        return true;
    }
    function setbusdToMainTokenPercent(uint _busdToMainTokenPercent) public onlyAdministrator returns(bool)
    {
        busdToMainTokenPercent = _busdToMainTokenPercent;
        return true;
    }
}