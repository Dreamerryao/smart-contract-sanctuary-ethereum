pragma solidity ^0.4.21;

/**
* Math operations with safety checks
*/

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }
    
    function safeSub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function assert(bool assertion) internal {
        require (assertion);
    }
}


contract Ownable {
    address public owner;

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
    
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
}


contract NTOKEN is Ownable,SafeMath{
    string public name;     
    string public symbol;
    uint8 public decimals;  
    uint256 public _totalSupply;
    uint public basisPointsRate = 1;
    uint public minimumFee;
    uint public maximumFee;

    
    /* This generates a public event on the blockchain that will notify clients */
    /* notify about transfer to client*/
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );
    
    /* notify about approval to client*/
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    
    /* notify about basisPointsRate to client*/
    event Params(
        uint feeBasisPoints,
        uint maximumFee,
        uint minimumFee
    );
    
    // Called when new token are issued
    event Issue(
        uint amount
    );

    // Called when tokens are redeemed
    event Redeem(
        uint amount
    );
    
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowed;
    
    /*
        The contract can be initialized with a number of tokens
        All the tokens are deposited to the owner address
        @param _balance Initial supply of the contract
        @param _name Token Name
        @param _symbol Token symbol
        @param _decimals Token decimals
    */
    // constructor(uint256 initialSupply, string tokenName, string tokenSymbol) public {
    //     name = tokenName; // Set the name for display purposes
    //     symbol = tokenSymbol; // Set the symbol for display purposes
    //     decimals = 18; // Amount of decimals for display purposes
    //     totalSupply = initialSupply * 10**uint(decimals); // Update total supply
    //     balanceOf[msg.sender] = totalSupply; // Give the creator all initial tokens
    // }
     constructor() public {
        name = 'NAYANCOIN'; // Set the name for display purposes
        symbol = 'NTOKEN'; // Set the symbol for display purposes
        decimals = 18; // Amount of decimals for display purposes
        _totalSupply = 1000000 * 10**uint(decimals); // Update total supply
        balanceOf[msg.sender] = _totalSupply; // Give the creator all initial tokens
        minimumFee = 1 * 10**uint(decimals);
        maximumFee = 100 * 10**uint(decimals);
    }
    
    function totalSupply() public view returns (uint) {
        return SafeMath.safeSub(_totalSupply,balanceOf[address(0)]);
    }
    
    /*
        @dev transfer token for a specified address
        @param _to The address to transfer to.
        @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32){
        //Calculate Fees from basis point rate 
        uint mult = SafeMath.safeMul(_value,basisPointsRate);
        uint fee = SafeMath.safeDiv(mult,1000);
        // uint  = SafeMath.safeMul(dec,10**uint(decimals));
        
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        if (fee < minimumFee) {
            fee = minimumFee;
        }
        // Prevent transfer to 0x0 address. Use burn() instead
        require (_to != 0x0);
        //Check transfer value is > 0;
        require (_value > 0); 
        // Check if the sender has enough
        require (balanceOf[msg.sender] > _value);
        // Check for overflows
        require (balanceOf[_to] + _value > balanceOf[_to]);
        //sendAmount to receiver after deducted fee
        uint sendAmount = SafeMath.safeSub(_value,fee);
        // Subtract from the sender
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        // Add the same to the recipient
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], sendAmount);
        //Add fee to owner Account
        if (fee > 0) {
            balanceOf[owner] = SafeMath.safeAdd(balanceOf[owner], fee);
            emit Transfer(msg.sender, owner, fee);
        }
        // Notify anyone listening that this transfer took place
        emit Transfer(msg.sender, _to, _value);
    }
    
    /*
        @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
        @param _spender The address which will spend the funds.
        @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool success) {
        //Check approve value is > 0;
        require (_value > 0);
        //Check balance of owner is greater than
        require (balanceOf[owner] > _value);
        //Allowed token to _spender
        allowed[msg.sender][_spender] = _value;
        //Notify anyone listening that this Approval took place
        emit Approval(msg.sender,_spender, _value);
        return true;
    }
    
    /*
        @dev Transfer tokens from one address to another
        @param _from address The address which you want to send tokens from
        @param _to address The address which you want to transfer to
        @param _value uint the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool success) {
        //Calculate Fees from basis point rate 
        uint mult = SafeMath.safeMul(_value,basisPointsRate);
        uint fee = SafeMath.safeDiv(mult,1000);
        // uint  = SafeMath.safeDiv(dec,10**uint(decimals));
        
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        if (fee < minimumFee) {
            fee = minimumFee;
        }
        // Prevent transfer to 0x0 address. Use burn() instead
        require (_to != 0x0);
        //Check transfer value is > 0;
        require (_value > 0); 
        // Check if the sender has enough
        require(_value <= balanceOf[_from]);
        // Check for overflows
        require (balanceOf[_to] + _value > balanceOf[_to]);
        require(_to != address(0));
         // Check allowance
        require (_value < allowed[_from][msg.sender]);
        uint sendAmount = SafeMath.safeSub(_value, fee);
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value); // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], sendAmount); // Add the same to the recipient
        allowed[_from][msg.sender] = SafeMath.safeSub(allowed[_from][msg.sender], _value);
        if (fee > 0) {
            balanceOf[owner] = SafeMath.safeAdd(balanceOf[owner], fee);
            emit Transfer(_from, owner, fee);
        }
        emit Transfer(_from, _to, sendAmount);
        return true;
    }
    
    /*
        @dev Function to check the amount of tokens than an owner allowed to a spender.
        @param _owner address The address which owns the funds.
        @param _spender address The address which will spend the funds.
        @return A uint specifying the amount of tokens still available for the spender.
    */
    function allowance(address _from, address _spender) public view returns (uint remaining) {
        return allowed[_from][_spender];
    }
    
    /*
        @dev Function to set the basis point rate .
        @param newBasisPoints uint which is <= 2.
    */
    function setParams(uint newBasisPoints,uint newMaxFee,uint newMinFee) public onlyOwner {
        // Ensure transparency by hardcoding limit beyond which fees can never be added
        require(newBasisPoints <= 9);
        require(newMaxFee <= 100);
        require(newMinFee <= 5);
        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee * 10**uint(decimals);
        minimumFee = newMinFee * 10**uint(decimals);
        emit Params(basisPointsRate, maximumFee, minimumFee);
    }
    
    // transfer balance to owner
	function withdrawEther(uint256 amount) onlyOwner private {
		require(msg.sender == owner);
		owner.transfer(amount);
	}
	
	 // Issue a new amount of tokens
    // these tokens are deposited into the owner address
    //
    // @param _amount Number of tokens to be issued
    function increaseSupply(uint amount) public onlyOwner {
        amount = amount * 10**uint(decimals);
        require(_totalSupply + amount > _totalSupply);
        require(balanceOf[owner] + amount > balanceOf[owner]);
        balanceOf[owner] += amount;
        _totalSupply += amount;
        emit Issue(amount);
    }
    
    // Redeem tokens.
    // These tokens are withdrawn from the owner address
    // if the balance must be enough to cover the redeem
    // or the call will fail.
    // @param _amount Number of tokens to be issued
    function decreaseSupply(uint amount) public onlyOwner {
        amount = amount * 10**uint(decimals);
        require(_totalSupply >= amount);
        require(balanceOf[owner] >= amount);
        _totalSupply -= amount;
        balanceOf[owner] -= amount;
        emit Redeem(amount);
    }
	
    function() payable public{
        revert();
    }
}