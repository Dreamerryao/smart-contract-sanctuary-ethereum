pragma solidity ^0.4.24;

contract TwogapContract {
    uint256 internal initialSupply = 210000000000e18;

    uint256 constant companyTokens = 31500000000e18;
    uint256 constant teamTokens = 31500000000e18;
    uint256 constant crowdsaleTokens = 69300000000e18;
    uint256 constant bountyTokens = 84000000000e18;
    uint256 constant mintingTokens = 69300000000e18;

    address company = 0x039a4c3a8014182d280bC49597F8aB66001B5e90;
    address team = 0x43285E497D1E57aBd161a26315EE7e58445f4CE6;
    address crowdsale = 0x5C0DF0a7BeA5dBc3a6e82AC37A8d9498C288a620;
    address bounty = 0x36D7a3C8d915Bd12bF30559195a7B33dde6CeB81;
    address minting = 0x9D8434F8177F7ECa84bD14749A6D23bDFc7A5BED;

    uint256 public totalSupply;
    uint8 constant public decimals = 18;
    string constant public name = "Twogap";
    string constant public symbol = "TGT";

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    
    constructor() public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        // InitialDistribution
        // preSale(company, companyTokens);
        // preSale(team, teamTokens);
        // preSale(crowdsale, crowdsaleTokens);
        // preSale(bounty, bountyTokens);
        // preSale(minting, mintingTokens);
    }

    function preSale(address _address, uint _amount) internal returns (bool) {
        balanceOf[_address] = _amount;
        // Transfer(address(0x0), _address, _amount);
    }

    /*function balanceOf(address _address) public returns (uint256) {
        return balanceOf[_address];
    }*/
    
    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousbalanceOf = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousbalanceOf);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    
    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
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
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
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
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}