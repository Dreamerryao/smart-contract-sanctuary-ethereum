pragma solidity ^0.4.24;

// Some interesting features for Regulating Securities Tokens Accounts in IBBT
// Securities Tokens Vault offer by IBBT

library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }

  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }

  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}

contract Nonpayable {

  // ------------------------------------------------------------------------
  // Don't accept ETH
  // ------------------------------------------------------------------------
  function () public payable {
    revert();
  }
}

contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function DissolveBusiness() public onlyOwner { 
    // This function is called when the organization is no longer actively operating
    // The Management can decide to Terminate access to the Securities Token. 
    // The Blockchain records remain, but the contract no longer can perform functions pertaining 
    // to the operations of the Securities.
    // https://www.irs.gov/businesses/small-businesses-self-employed/closing-a-business-checklist
    selfdestruct(owner);
  }
}

contract Regulated is Ownable {
  event Whitelisted(address indexed shareholder);
  event CorpBlackBook(address indexed shareholder); // Consider this option as the Nevada Commision little black book, bad actors are blacklisted 
  
  mapping(address => bool) regulationStatus;

  function whitelist(address shareholder) public onlyOwner {
    regulationStatus[shareholder] = true;
    emit Whitelisted(shareholder);
  }

  function NevadaBlackBook(address shareholder) public onlyOwner {
    regulationStatus[shareholder] = false;
    emit CorpBlackBook(shareholder);
  }
  
  function ensureRegulated(address shareholder) public constant {
    require(regulationStatus[shareholder] == true);
  }

  function isRegulated(address shareholder) public constant returns (bool approved) { 
    return regulationStatus[shareholder];
  }
}

contract ERC20 {
  function totalSupply() public constant returns (uint);
  function balanceOf(address tokenOwner) public constant returns (uint balance);
  function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract SecuritiesVaultBank is ERC20, Regulated, Nonpayable {
  using SafeMath for uint;

  string public symbol;
  string public  name;
  uint8 public decimals;
  uint public _totalSupply;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  function SecuritiesVaultBank() public {
    symbol = "YST";                                 // Create the Sucurities Token Symbol Here
    name = "Your Securities Token";                 // Description of the Securetized Tokens
    // In our sample we have created securites tokens and fractional securities for the tokens upto 18 digits
    decimals = 18;                                  // Number of Digits [0-18] If an organization wants to fractionalize the securities
    // The 0 can be any digit up to 18. Eighteen is the standard for cryptocurrencies
    _totalSupply = 1000000 * 10**uint(decimals);    // Total Number of Securities Issued (example 1,000,000 Shares of YST)
    balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply); // Owner or Company Representative (CFO/COO/CEO/CHAIRMAN)

    regulationStatus[owner] = true;
    emit Whitelisted(owner);
  }

  function issue(address recipient, uint tokens) public onlyOwner returns (bool success) {
    require(recipient != address(0));
    require(recipient != owner);
    
    whitelist(recipient);
    transfer(recipient, tokens);
    return true;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    // Organization is Merged or Sold and Securities Management needs to transfer to new owners
    require(newOwner != address(0));
    require(newOwner != owner);
   
    whitelist(newOwner);
    transfer(newOwner, balances[owner]);
    owner = newOwner;
  }

  function totalSupply() public constant returns (uint supply) {
    return _totalSupply - balances[address(0)];
  }

  function balanceOf(address tokenOwner) public constant returns (uint balance) {
    return balances[tokenOwner];
  }

  function transfer(address to, uint tokens) public returns (bool success) {
    ensureRegulated(msg.sender);
    ensureRegulated(to);
    
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }

  function approve(address spender, uint tokens) public returns (bool success) {
    // Put a check for race condition issue with approval workflow of ERC20
    require((tokens == 0) || (allowed[msg.sender][spender] == 0));
    
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }

  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
    ensureRegulated(from);
    ensureRegulated(to);

    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
  }

  function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }
}