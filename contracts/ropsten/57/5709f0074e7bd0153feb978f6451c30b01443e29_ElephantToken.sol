pragma solidity ^ 0.4.24;

/******************************************/
/*           Elephant TOKEN               */
/******************************************/

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}   

/**
 * Math operations with safety checks
 */
contract SafeMath { 
    function safeMul(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

contract ElephantToken is owned, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals = 8;
    uint256 public totalSupply;
    uint256 public sellPrice;
    uint256 public buyPrice;

    /* This creates an array with all balances */
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public freezeOf;
    mapping(address => mapping(address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);

    /* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);

    /* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor (uint256 initialSupply, string tokenName, string tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals); // Update total supply
        balanceOf[msg.sender] = totalSupply; // Give the creator all initial tokens
        name = tokenName; // Set the name for display purposes
        symbol = tokenSymbol; // Set the symbol for display purposes
        owner = msg.sender;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) internal {
        require(_to != 0x0);
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        require(SafeMath.safeAdd(balanceOf[_to], _value) >= balanceOf[_to]);    // Check for overflows
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value); // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value); // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value); // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public returns(bool success) {
        require(_value > 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
        require(_to != 0x0); // Prevent transfer to 0x0 address. Use burn() instead
        require(_value > 0);
        require(balanceOf[_from] >= _value); // Check if the sender has enough
        require(SafeMath.safeAdd(balanceOf[_to], _value) >= balanceOf[_to]); // Check for overflows
        require(_value <= allowance[_from][msg.sender]); // Check allowance
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value); // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value); // Add the same to the recipient
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns(bool success) {
        require(balanceOf[msg.sender] >= _value); // Check if the sender has enough
        require(_value > 0);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value); // Subtract from the sender
        totalSupply = SafeMath.safeSub(totalSupply, _value); // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    function freeze(uint256 _value) public returns(bool success) {
        require(balanceOf[msg.sender] >= _value); // Check if the sender has enough
        require(_value > 0);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value); // Subtract from the sender
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value); // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }

    function unfreeze(uint256 _value) public returns(bool success) {
        require(freezeOf[msg.sender] >= _value); // Check if the sender has enough
        require(_value > 0);
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value); // Subtract from the sender
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }

    // transfer balance to owner
    function withdrawEther(uint256 amount) public {
        require(msg.sender == owner);
        owner.transfer(amount);
    }

    // can accept ether
    function() payable public {}

    //increaseSupply
    function increaseSupply(uint256 value, address to) onlyOwner public returns(bool) {
        value = value * 10 ** uint256(decimals);
        totalSupply = SafeMath.safeAdd(totalSupply, value);
        balanceOf[to] = SafeMath.safeAdd(balanceOf[to], value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    //decreaseSupply
    function decreaseSupply(uint256 value, address from) onlyOwner public returns(bool) {
        value = value * 10 ** uint256(decimals);
        balanceOf[from] = SafeMath.safeSub(balanceOf[from], value);
        totalSupply = SafeMath.safeSub(totalSupply, value);
        emit Transfer(from, msg.sender, value);
        return true;
    }

    /// @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    /// @param newSellPrice Price the users can sell to the contract
    /// @param newBuyPrice Price users can buy from the contract
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    /// @notice Buy tokens from contract by sending ether
    function buy() payable public {
        uint amount = SafeMath.safeSub(msg.value, buyPrice);               // calculates the amount
        emit Transfer(this, msg.sender, amount);              // makes the transfers
    }

    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sell(uint256 amount) public {
        address myAddress = this;
        require(myAddress.balance >= SafeMath.safeMul(amount, sellPrice));      // checks if the contract has enough ether to buy
        emit Transfer(msg.sender, this, amount);              // makes the transfers
        msg.sender.transfer(amount * sellPrice);          // sends ether to the seller. It's important to do this last to avoid recursion attacks
    }
}