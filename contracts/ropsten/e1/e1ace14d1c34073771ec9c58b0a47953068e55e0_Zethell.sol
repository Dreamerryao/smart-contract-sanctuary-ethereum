pragma solidity ^0.4.23;

/*
* Zethell.
*
* Written June 2018 for Zethr (https://www.zethr.io) by Norsefire.
* Special thanks to oguzhanox and Etherguy for assistance with debugging.
*
*/

contract ZTHReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data) public returns (bool);
}

contract ZTHInterface {
    function transfer(address _to, uint _value) public returns (bool);
    function approve(address spender, uint tokens) public returns (bool);
}

contract Zethell is ZTHReceivingContract {
    using SafeMath for uint;

    address private owner;
    address private bankroll;

    uint    private houseTake;
    uint    public tokensInPlay;
    uint    public contractBalance;
    address public currentWinner;

    uint    public gameStarted;
    uint    public gameEnds;
    bool    public gameActive;

    address private constant ZTHTKNADDR  = 0xf1dFc1447f8AbDb766151FB4De130F079c345bd1;
    address private constant ZTHBANKROLL = 0x5C07E52d25418DBE5CA3Bc8279eEe09258671086;
    ZTHInterface private     ZTHTKN;

    mapping (uint => bool) validTokenBet;
    mapping (uint => uint) tokenToTimer;

    event GameEnded(
        address winner,
        uint tokensWon,
        uint timeOfWin
    );

    event HouseRetrievedTake(
        uint timeTaken,
        uint tokensWithdrawn
    );

    event TokensWagered(
        address _wagerer,
        uint _wagered,
        uint _newExpiry
    );

    modifier onlyOwner {
         require(msg.sender == owner);
         _;
    }

    modifier onlyBankroll {
         require(msg.sender == bankroll);
         _;
    }

    constructor() public {

        owner         = ZTHBANKROLL;
        bankroll      = ZTHBANKROLL;
        currentWinner = ZTHBANKROLL;

        ZTHTKN = ZTHInterface(ZTHTKNADDR);
        ZTHTKN.approve(ZTHBANKROLL, 2**256 - 1);

        validTokenBet[5e18]  = true;
        validTokenBet[10e18] = true;
        validTokenBet[25e18] = true;
        validTokenBet[50e18] = true;

        tokenToTimer[5e18]  = 60 minutes;
        tokenToTimer[10e18] = 40 minutes;
        tokenToTimer[25e18] = 25 minutes;
        tokenToTimer[50e18] = 15 minutes;
        

        gameStarted = now;
        gameEnds    = now;
        gameActive  = true;
    }
    
    function() public payable {}

    struct TKN { address sender; uint value; }
    function tokenFallback(address _from, uint _value, bytes /* _data */) public returns (bool){
        TKN memory          _tkn;
        _tkn.sender       = _from;
        _tkn.value        = _value;
        _stakeTokens(_tkn);
        return true;
    }

    function _stakeTokens(TKN _tkn) private {
    
        require(_zthToken(msg.sender));
        
        if (now > gameEnds) { _settleAndRestart(); }

        address _customerAddress = _tkn.sender;
        uint    _wagered         = _tkn.value;

        uint rightNow      = now;
        uint timePurchased = tokenToTimer[_tkn.value];
        uint newGameEnd    = rightNow.add(timePurchased);

        gameStarted   = rightNow;
        gameEnds      = newGameEnd;
        currentWinner = _customerAddress;

        contractBalance = contractBalance.add(_wagered);
        uint houseCut   = _wagered.div(100);
        uint toAdd      = _wagered.sub(houseCut);
        houseTake       = houseTake.add(houseCut);
        tokensInPlay    = tokensInPlay.add(toAdd);

        emit TokensWagered(_customerAddress, _wagered, newGameEnd);

    }

    function _settleAndRestart() private {
        gameActive      = false;
        contractBalance = contractBalance.sub(tokensInPlay);

        if (tokensInPlay > 0) { ZTHTKN.transfer(currentWinner, tokensInPlay);
            if (address(this).balance > 0){
                ZTHBANKROLL.transfer(address(this).balance); // divs go into bankroll and get dumped back into zethr 
            }}

        emit GameEnded(currentWinner, tokensInPlay, now);

        // Reset values.
        tokensInPlay  = 0;
        gameActive    = true;
    }

    function balanceOf() public view returns (uint) {
        return contractBalance;
    }

    function addTokenTime(uint _tokenAmount, uint _timeBought) public onlyOwner {
        validTokenBet[_tokenAmount] = true;
        tokenToTimer[_tokenAmount]  = _timeBought;
    }

    function removeTokenTime(uint _tokenAmount) public onlyOwner {
        validTokenBet[_tokenAmount] = false;
        tokenToTimer[_tokenAmount]  = 232 days;
    }

    function retrieveHouseTake() public onlyBankroll {
        uint toTake = houseTake;
        houseTake = 0;
        contractBalance = contractBalance.sub(toTake);
        ZTHTKN.transfer(bankroll, toTake);

        emit HouseRetrievedTake(now, toTake);
    }

    function pauseGame() public onlyOwner {
        gameActive = false;
    }

    function resumeGame() public onlyOwner {
        gameActive = true;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function changeBankroll(address _newBankroll) public onlyOwner {
        bankroll = _newBankroll;
    }

    function _zthToken(address _tokenContract) private pure returns (bool) {
       return _tokenContract == ZTHTKNADDR;
    }

    function _humanSender(address _from) private view returns (bool) {
      uint codeLength;
      assembly {
          codeLength := extcodesize(_from)
      }
      return (codeLength == 0);
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
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}