pragma solidity ^0.4.21;



//Replace safe math with ordinary math where checks are performed


//     THIS IS NEXT CONTRACT TO BE TESTED

//VERSION 0.3


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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

contract owned {
    //Safe Math
    using SafeMath for uint256;

    //Damage control
    bool internal contractBlocked = true;

    address internal ownerCandidate;//When transfering ownership store owner candidate in to this variable and make it call confirmOwnership in order to assure that address can actually call a contract
    address public owner;

    //function owned() public {
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event ContractBlocked(uint256 time_of_blocking);

    function blockContract() onlyOwner public {
        emit ContractBlocked(now);
        contractBlocked = true;
    }

    event ContractEnabled(uint256 time_of_enabling);

    function enableContract() onlyOwner public {
        emit ContractEnabled(now);
        contractBlocked = false;
    }

    modifier onlyIfEnabled {
        require(contractBlocked == false);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        ownerCandidate = newOwner;
    }
    function confirmOwnership() public {
        require(msg.sender == ownerCandidate);
        owner = ownerCandidate;
    }

}


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 is owned {
    //Safe Math
    using SafeMath for uint256;

    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18; // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    //function TokenERC20(
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol        
    ) public {
        totalSupply = initialSupply.mul(10 ** uint256(decimals));  // Update total supply with the decimal amount//!S!M        
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
     
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool){
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to].add(_value) > balanceOf[_to]);//!S!M
        // Save this for an assertion in the future
        uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]);//!S!M
        // Subtract from the sender
        balanceOf[_from] = balanceOf[_from].sub(_value);//!S!M
        // Add the same to the recipient
        balanceOf[_to] = balanceOf[_to].add(_value);//!S!M
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);//!S!M
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
    function transfer(address _to, uint256 _value) onlyIfEnabled public returns (bool){
        return _transfer(msg.sender, _to, _value);        
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
    function transferFrom(address _from, address _to, uint256 _value) onlyIfEnabled public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);//!S!M
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) onlyIfEnabled public
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
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) onlyIfEnabled
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
    function burn(uint256 _value) onlyIfEnabled public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value); // Subtract from the sender//!S!M
        totalSupply = totalSupply.sub(_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
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
    function burnFrom(address _from, uint256 _value) onlyIfEnabled public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] = balanceOf[_from].sub(_value);    // Subtract from the targeted balance//!S!M
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value); // Subtract from the sender's allowance//!S!M
        totalSupply = totalSupply.sub(_value);                              // Update totalSupply//!S!M
        emit Burn(_from, _value);
        return true;
    }
}

library SafeERC20 {
    function safeTransfer(TokenERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        TokenERC20 token,
        address from,
        address to,
        uint256 value
    )
    internal
    {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(TokenERC20 token, address spender, uint256 value) internal {
        require(token.approve(spender, value));
    }
}

/******************************************/
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/

contract SafeAdvancedToken is TokenERC20 {
    //Safe Math
    using SafeMath for uint256;    

    //CHECK COMPATIBILITY WITH NORMAL ERC20
    using SafeERC20 for TokenERC20;

    uint256 public sellPrice;
    uint256 public buyPrice;


    bool public weiCapSet = false;
    uint256 public hardCapWei = 0;//maximum ethers this contract can accept in wei
    uint256 public softCapWei = 0;//if we reach this goal ICO funding has been successfull
    uint256 public totalWei = 0;//Total ammount of wei raised
    bool public ICOSet = false;
    uint256 public preICOstartTime = 0;//UNIX time stamp that determines when will the funding start
    uint256 public preICOendTime = 0;//UNIX time stamp that determines when will the funding end
    uint256 public ICOstartTime = 0;//UNIX time stamp that determines when will the funding start
    uint256 public ICOendTime = 0;//UNIX time stamp that determines when will the funding end
    bool public ICOPricesSet = false;
    uint256 public preICOBuyPrice;
    uint256 public ICOBuyPrice;
    uint256 public postICOBuyPrice;
    uint256 public postICOSellPrice;
    //add function that will prevent user from selling tokens until certain condition is met
    //account with ehter and coinbase and cryptopia accounts
    //if crowdsale does not succede do we refund
    // should ico use wallets
    //if we reach softcap burn all remaining token after funding ends
    //allow pre sale - Early bird discounts for investors which contribute in the first few days of the campaign are basically a must.
    //should we allow few people to buy most of the tokens right away or do we want to distribute them equaly

    modifier ICOnotSetup {
        require(ICOSet == false);
        _;
    }
    event SetupICONowTime(uint256 timestamp);
    function setupICO(uint256 _preICOstartTime, uint256 _preICOendTime, uint256 _ICOstartTime, uint256 _ICOendTime) onlyOwner ICOnotSetup public{        
        emit SetupICONowTime(now);
        require(_preICOstartTime<=_preICOendTime && _preICOendTime<=_ICOstartTime && _ICOstartTime<=_ICOendTime);        
        preICOstartTime=_preICOstartTime;
        preICOendTime=_preICOendTime;
        ICOstartTime=_ICOstartTime;
        ICOendTime=_ICOendTime;
        ICOSet=true;
    }
    event TimeOut(string command, int256 time);
    function isPreICO() public view returns(int8){
        if(ICOSet==true){
            emit TimeOut('isPreICO', int256(preICOendTime - now));
            if ((now>=preICOstartTime)&&(now<=preICOendTime)){
                return 1;
            } else {
                return 0;
            }
        } else {
            return -1;
        }
    }
    function isICO() public view returns(int8){
        if(ICOSet==true){
            emit TimeOut('isICO', int256(ICOendTime - now));
            if ((now>=ICOstartTime)&&(now<=ICOendTime)){
                return 1;
            } else {
                return 0;
            }
        } else {
            return -1;
        }
    }
    function isICOOver() public view returns(int8){        
        if(ICOSet==true){
            emit TimeOut('isICOOver', int256(ICOendTime - now));
            if (now>ICOendTime){            
                return 1;
            } else {
                return 0;
            }
        } else {
            return -1;
        }
    }
    function setupICOPrices(uint256 _preICOBuyPrice, uint256 _ICOBuyPrice, uint256 _postICOBuyPrice, uint256 _postICOSellPrice) onlyOwner public{
        require(ICOSet == true);
        ICOPricesSet = true;
        preICOBuyPrice=_preICOBuyPrice;
        ICOBuyPrice=_ICOBuyPrice;
        postICOBuyPrice=_postICOBuyPrice;
        postICOSellPrice=_postICOSellPrice;
    }
    modifier weiCapnotSet {
        require(weiCapSet == false);
        _;
    }
    function setupWeiCaps(uint256 _hardCapWei, uint256 _softCapWei ) onlyOwner weiCapnotSet public {
        require(_hardCapWei>=_softCapWei);
        hardCapWei = _hardCapWei.mul(10**uint256(decimals));
        softCapWei = _softCapWei.mul(10**uint256(decimals));
        weiCapSet = true;
    }
    function SoftCapReached() public view returns (bool){
        return (weiCapSet == true)&&(totalWei>=softCapWei);
    }
    function HardCapReached() public view returns (bool){
        return (weiCapSet == true)&&(totalWei>=hardCapWei);
    }


    mapping (address => bool) public frozenAccount;


    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address indexed target, bool indexed frozen);


    /* Initializes contract with initial supply tokens to the creator of the contract */
    //function SafeAdvancedToken(
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool){
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);               // Check if the sender has enough
        require (balanceOf[_to].add(_value) > balanceOf[_to]); // Check for overflows//!S!M
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
        balanceOf[_from] = balanceOf[_from].sub(_value);                         // Subtract from the sender//!S!M
        balanceOf[_to] = balanceOf[_to].add(_value);                           // Add the same to the recipient//!S!M
        emit Transfer(_from, _to, _value);
        return true;
    }

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] = balanceOf[target].add(mintedAmount);//!S!M
        totalSupply = totalSupply.add(mintedAmount);//!S!M
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    /// @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    /// @param newSellPrice Price the users can sell to the contract
    /// @param newBuyPrice Price users can buy from the contract
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    /// @notice Buy tokens from contract by sending ether
    function buy() payable onlyIfEnabled public {
        if(ICOSet==true){
            require(isPreICO()==1 || isICO()==1);
            if(ICOPricesSet==true){
                if(isPreICO()==1){
                   buyPrice = preICOBuyPrice;
                } else if(isICO()==1){
                   buyPrice = ICOBuyPrice;
                } else if(isICOOver()==1){
                   buyPrice = postICOBuyPrice;
                   sellPrice = postICOSellPrice;
                }
            }
        }
        require(buyPrice>0);
        require(HardCapReached()==false);
        uint256 amount = msg.value.div(buyPrice);              // calculates the amount//!S!M
        totalWei = totalWei.add(msg.value);
        require(_transfer(this, msg.sender, amount)==true);   // makes the transfers
    }

    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold

    bool public sellAllowed = false;
    function usersCanSell(bool value) onlyOwner public{
        sellAllowed = value;
    }
    function sell(uint256 amount) onlyIfEnabled public{
        require(sellAllowed==true);
        if(ICOSet==true){
            require(isICOOver()==1);
            if(ICOPricesSet==true){
                buyPrice = postICOBuyPrice;
                sellPrice = postICOSellPrice;
            }
        }       
        require(sellPrice>0);
        uint256 weiAmount = amount.mul(sellPrice);//!S!M
        require(address(this).balance >= weiAmount);      // checks if the contract has enough ether to buy//!S!M
        _transfer(msg.sender, this, amount);              // makes the transfers        
        totalWei = totalWei.sub(weiAmount);
        msg.sender.transfer(weiAmount);          // sends ether to the seller. It's important to do this last to avoid recursion attacks        
    }
    bool public refundEnabled = false;
    function setRefund(bool value) onlyOwner public{
        refundEnabled = value;
    }
    //Buys back all users tokens at current price, same as selling all owners tokens
    function refundToken() onlyIfEnabled public{        
        require(refundEnabled==true);
        require(sellPrice>0);
        if(ICOSet==true){
            require(isICOOver()==1);
            if(ICOPricesSet==true){
                buyPrice = postICOBuyPrice;
                sellPrice = postICOSellPrice;
            }
        }       
        uint256 weiAmount = balanceOf[msg.sender].mul(sellPrice);//!S!M
        require(address(this).balance >= weiAmount);             // checks if the contract has enough ether to buy//!S!M
        _transfer(msg.sender, this, balanceOf[msg.sender]);              // makes the transfers        
        totalWei = totalWei.sub(weiAmount);
        msg.sender.transfer(weiAmount);          // sends ether to the seller. It's important to do this last to avoid recursion attacks        
    }
    /// @notice Send ether to the owner
    /// @param amount amount of ether to transfer from contract to address
    event FundsToOwner(uint256 _time_of_transfer, uint256 amount);
    function fundsToOwner(uint256 amount)public onlyOwner{
        require(address(this).balance >= amount);
        owner.transfer(amount);
        emit FundsToOwner(now, amount);
    }

    // @notice Send ether to any address
    event FundsToAddress(uint256 _time_of_transfer, address indexed sendTo, uint256 amount);
    function fundsToAddress(address sendTo, uint256 amount)public onlyOwner{
        require(address(this).balance >= amount);
        sendTo.transfer(amount);
        emit FundsToAddress(now, sendTo, amount);
    }

   //implement selfdestruct (note to self suicide is deprecated)
    function warningERASEcontract() public onlyOwner {
        //check if ICO has ended
        selfdestruct(owner);
    }

    //check why fallback function writes no data to the event log
    //Fallback function can only log, since that much is all the gas we have
    event FallbackEvent(address sender);//NOTE MUST NOT HAVE MORE THAN ONE PARAMETER OR OUT OF GAS WILL OCCURE (2300)
    function() payable public{//WE AGRE GREEDY WE ALWAYS ACCEPT ETHER EVEN IF WE ARE BLOCKED BUT WE LOG WHO TRANSFERED FUNDS!!! IN ORDER TO REFUND USE fundsToAddress
        emit FallbackEvent(msg.sender);
        //throw; in a case we dont want to accept money
    }
}