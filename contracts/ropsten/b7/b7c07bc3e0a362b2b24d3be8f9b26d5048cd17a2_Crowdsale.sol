pragma solidity ^0.4.21;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public Publisher;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PublisherTransferred(address indexed Publisher, address indexed newPublisher);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable() public {
        owner = msg.sender;
        Publisher = msg.sender;
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

    /**
    * @dev return Owner address.
    */

    function OwnerAddress() public view returns(address){
        return owner;
    }

    /**
    * @dev Allows the current Publisher to transfer control of the contract to a newPublisher.
    * @param newPublisher The address to transfer Publisher to.
    */
    function transferPublisher(address newPublisher) public onlyOwner {
        emit PublisherTransferred(Publisher, newPublisher);
        Publisher = newPublisher;
    }

    /**
    * @dev return Owner address.
    */

    function PublisherAddress() public view returns(address){
        return Publisher;
    }

}


/*
 * @title Standard ERC20 token
 *
 */
contract YDHTOKEN is Ownable{
    using SafeMath for uint256;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed burner, uint256 value);
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event Setlockaddress(address indexed target, uint256 lock);
    event Setlockall(uint256 lock);

    mapping(address => uint256) balances;
    mapping(address => uint256) public lockaddress;    
    mapping (address => mapping (address => uint256)) internal allowed;

    uint256 public totalSupply;
    bool public mintingFinished;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public lockall;

    function YDHTOKEN (
        string name_,
        string symbol_,        
        uint256 totalSupply_
    ) public {
        lockall = 1;
        mintingFinished = false;
        decimals = 18;                
        name = name_;
        symbol = symbol_;
        totalSupply = totalSupply_ * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
    }

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier hasMintPermission() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(lockaddress[msg.sender] == 0);
        if((msg.sender != address(0)) && (msg.sender != OwnerAddress()) && (msg.sender != PublisherAddress()) && (lockall != 0)){
            revert();
        } 

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    *
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(lockaddress[msg.sender] == 0);
        if((msg.sender != address(0)) && (msg.sender != OwnerAddress()) && (msg.sender != PublisherAddress()) && (lockall != 0)){
            revert();
        } 

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        require(lockaddress[msg.sender] == 0);
        if((msg.sender != address(0)) && (msg.sender != OwnerAddress()) && (msg.sender != PublisherAddress()) && (lockall != 0)){
            revert();
        } 

        return allowed[_owner][_spender];
    }

    /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    *
    * approve should be called when allowed[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _addedValue The amount of tokens to increase the allowance by.
    */
    function increaseApproval(
        address _spender,
        uint _addedValue
    )
        public
        returns (bool)
    {
        require(lockaddress[msg.sender] == 0);
        if((msg.sender != address(0)) && (msg.sender != OwnerAddress()) && (msg.sender != PublisherAddress()) && (lockall != 0)){
            revert();
        } 
        
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    *
    * approve should be called when allowed[_spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param _spender The address which will spend the funds.
    * @param _subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseApproval(
        address _spender,
        uint _subtractedValue
    )
        public
        returns (bool)
    {
        require(lockaddress[msg.sender] == 0);
        if((msg.sender != address(0)) && (msg.sender != OwnerAddress()) && (msg.sender != PublisherAddress()) && (lockall != 0)){
            revert();
        }

        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(lockaddress[msg.sender] == 0);
        if((msg.sender != address(0)) && (msg.sender != OwnerAddress()) && (msg.sender != PublisherAddress()) && (lockall != 0)){
            revert();
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    /**
    * @dev Burns a specific amount of tokens.
    * @param _value The amount of token to be burned.
    */
    function burn(address _who, uint256 _value) onlyOwner public {
        _burn(_who, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        balances[_who] = balances[_who].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

    /**
    * @dev Function to mint tokens
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(
        address _to,
        uint256 _amount
    )
        hasMintPermission
        canMint
        public
        returns (bool)
    {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
    * @dev Function to stop minting new tokens.
    * @return True if the operation was successful.
    */
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    /**
    * @dev Function to set to lock address.
    */
    function setlockaddress(address target, uint256 lock) onlyOwner public {
        lockaddress[target] = lock;
        emit Setlockaddress(target, lock);
    }

    /**
    * @dev Function to set to lock all of address.
    */
    function setlockall(uint256 lock) onlyOwner public {
        lockall = lock;
        emit Setlockall(lock);
    }    

}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropiate to concatenate
 * behavior.
 */
contract Crowdsale is Ownable{
    using SafeMath for uint256;

    // The token being sold
    YDHTOKEN public token;

    // Address where funds are collected
    address public wallet;

    // whitelist Address
    mapping(address => bool) public whitelist;

    // flag for ico start/stop
    bool public startico = false;

    // minimum amount
    uint256 public minimumamount;

    // cap bounus
    uint256 public capbounusA;
    uint256 public capbounusB;
    uint256 public capbounusC;    
    // volume bounus
    uint256 public volumebounusA;
    uint256 public volumebounusB;
    uint256 public volumebounusC; 

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a DetailedERC20 token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    uint256 public rate;

    // Amount of wei raised
    uint256 public weiRaised;

    /**
    * Event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    event ICOStatus(
        bool _startico
    );

    /**
    * @param _rate Number of token units a buyer gets per wei
    * @param _wallet Address where collected funds will be forwarded to
    * @param _token Address of the token being sold
    */
    function Crowdsale (uint256 _rate, address _wallet, YDHTOKEN _token) public {
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));

        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

    // -----------------------------------------
    // Crowdsale external interface
    // -----------------------------------------

    /**
    * @dev fallback function ***DO NOT OVERRIDE***
    */
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
    * @dev low level token purchase ***DO NOT OVERRIDE***
    * @param _beneficiary Address performing the token purchase
    */
    function buyTokens(address _beneficiary) public payable {

        uint256 weiAmount = msg.value;
        require(startico);
        require(_beneficiary != address(0));
        require(weiAmount != 0);
        require(weiAmount >= minimumamount);
        require(isWhitelisted(_beneficiary));

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        weiRaised = weiRaised.add(weiAmount);
        _processPurchase(_beneficiary, tokens);

        emit TokenPurchase(
            msg.sender,
            _beneficiary,
            weiAmount,
            tokens
        );

        _forwardFunds();
    }

    /**
    * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
    * @param _beneficiary Address performing the token purchase
    * @param _tokenAmount Number of tokens to be emitted
    */
    function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
    )
        internal
    {
        token.transfer(_beneficiary, _tokenAmount);
    }

    /**
    * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
    * @param _beneficiary Address receiving the tokens
    * @param _tokenAmount Number of tokens to be purchased
    */
    function _processPurchase(
        address _beneficiary,
        uint256 _tokenAmount
    )
        internal
    {
        _deliverTokens(_beneficiary, _tokenAmount);
    }


    /**
    * @dev Override to extend the way in which ether is converted to tokens.
    * @param _weiAmount Value in wei to be converted into tokens
    * @return Number of tokens that can be purchased with the specified _weiAmount
    */
    function _getTokenAmount(uint256 _weiAmount)
        internal view returns (uint256)
    {
        uint256 totalAmount = 0;        
        uint256 bounsAmount = 0;
        uint256 tempAmount = 0;

        if((_weiAmount >= capbounusC) && (capbounusC != 0))
        {
            tempAmount = _weiAmount.div(100);
            bounsAmount = tempAmount.mul(volumebounusC);
        }
        else if(_weiAmount >= capbounusB && (capbounusB != 0))
        {
            tempAmount = _weiAmount.div(100);
            bounsAmount = tempAmount.mul(volumebounusB);
        }
        else if(_weiAmount >= capbounusA && (capbounusA != 0))
        {
            tempAmount = _weiAmount.div(100);
            bounsAmount = tempAmount.mul(volumebounusA);            
        }

        _weiAmount = _weiAmount.add(bounsAmount);
        totalAmount = _weiAmount.mul(rate);

        return totalAmount;
    }

    /**
    * @dev Determines how ETH is stored/forwarded on purchases.
    */
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }


    /**
    * @dev set minimum amount
    */
    function setminimumAmount(uint256 _minimumamount) public onlyOwner {
        minimumamount = _minimumamount;
    }

    /**
    * @dev set cap bounus.
    */
    function setcapbounus(uint256 _capbounusA, uint256 _capbounusB, uint256 _capbounusC) public onlyOwner {
            // cap bounus
        capbounusA = _capbounusA;
        capbounusB = _capbounusB;
        capbounusC = _capbounusC;   
    }

    /**
    * @dev set volume bounus.
    */
    function setvolumebounus(uint256 _volumebounusA, uint256 _volumebounusB, uint256 _volumebounusC) public onlyOwner {
            // volume bounus
        volumebounusA = _volumebounusA;
        volumebounusB = _volumebounusB;
        volumebounusC = _volumebounusC;   
    }

    /**
    * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
    */
    function isWhitelisted(address _beneficiary) public view returns(bool){
        bool check;
        check = whitelist[_beneficiary];

        return check;
    }

    /**
    * @dev Adds single address to whitelist.
    * @param _beneficiary Address to be added to the whitelist
    */
    
    function addToWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = true;
    }

    /**
    * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
    * @param _beneficiaries Addresses to be added to the whitelist
    */
    function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }

    /**
    * @dev Removes single address from whitelist.
    * @param _beneficiary Address to be removed to the whitelist
    */
    function removeFromWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = false;
    }

    /**
    * @dev control start/stop ico
    */
    function startstopICO(bool _startstop) public onlyOwner {        
        startico = _startstop;
    }

    /**
    * @dev return ramining token to owner address.
    */
    function returnTokenToWallet() public onlyOwner {        
        _processPurchase(OwnerAddress(), token.balanceOf(this));        
    }

    /**
    * @dev stop contract
    */
    function deleteThisContract() public onlyOwner {        
        selfdestruct(OwnerAddress());
    }


}