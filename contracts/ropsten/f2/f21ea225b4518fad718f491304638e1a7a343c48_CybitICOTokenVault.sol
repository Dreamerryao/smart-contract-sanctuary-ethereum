pragma solidity 0.4.24;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}
contract owned {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner , "Unauthorized Access");
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface ERC223Interface {
   
    function balanceOf(address who) constant external returns (uint);
    function transfer(address to, uint value) external returns (bool success);
    function transfer(address to, uint value, bytes data) external returns (bool success);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}
/**
 * @title Contract that will work with ERC223 tokens.
 */
 
contract ERC223ReceivingContract { 
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */
 struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }
    function tokenFallback(address _from, uint _value, bytes _data) external;
}
contract ERC20BackedERC223 is ERC223Interface{
    
    

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function disApprove(address _spender)  public returns (bool success);
   function increaseApproval(address _spender, uint _addedValue) public returns (bool success);
   function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success);
     /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);
     function name() public view returns (string _name);

    /* Get the contract constant _symbol */
    function symbol() public view returns (string _symbol);

    /* Get the contract constant _decimals */
    function decimals() public view returns (uint8 _decimals); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
library SafeERC20BackedERC223 {

  function safeTransfer(ERC20BackedERC223 token, address to, uint256 value, bytes data) internal {
    assert(token.transfer(to, value, data));
  }    
    
  function safeTransfer(ERC20BackedERC223 token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20BackedERC223 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20BackedERC223 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}
contract CybitICOTokenVault is ERC223ReceivingContract, owned{
    
     using SafeERC20BackedERC223 for ERC20BackedERC223;
     ERC20BackedERC223 CybitToken;
      struct Investor {
        string fName;
        string lName;
    }
    
    mapping (address => Investor) investors;
    address[] public investorAccts;

     constructor() public
     {
         
         CybitToken = ERC20BackedERC223(0x2a08c4B5CB8eC0b84beEC790741Ae92Bd1f921E3);
     }
function tokenFallback(address _from, uint _value, bytes _data) external{
           /* tkn variable is analogue of msg variable of Ether transaction
      *  tkn.sender is person who initiated this token transaction   (analogue of msg.sender)
      *  tkn.value the number of tokens that were sent   (analogue of msg.value)
      *  tkn.data is data of token transaction   (analogue of msg.data)
      *  tkn.sig is 4 bytes signature of function
      *  if data of token transaction is a function execution
      */
        TKN memory tkn;
      tkn.sender = _from;
      tkn.value = _value;
      tkn.data = _data;
      
     
     }
     function() public {
         //not payable fallback function
          revert();
    }
    function sendApprovedTokensToInvestor(address _benificiary,uint256 _approvedamount,string _fName, string _lName) public onlyOwner
    {
        require(CybitToken.balanceOf(address(this)) > _approvedamount);
        investors[_benificiary] = Investor({
                                            fName: _fName,
                                            lName: _lName
            
        });
        
        investorAccts.push(_benificiary) -1;
        CybitToken.safeTransfer(_benificiary , _approvedamount);
    }
     function onlyPayForFuel() public payable onlyOwner{
        // Owner will pay in contract to bear the gas price if transactions made from contract
        
    }
    function withdrawEtherFromcontract(uint _amountInwei) public onlyOwner{
        require(address(this).balance > _amountInwei);
      require(msg.sender == owner);
      owner.transfer(_amountInwei);
     
    }
    function withdrawTokenFromcontract(ERC20BackedERC223 _token, uint256 _tamount) public onlyOwner{
        require(_token.balanceOf(address(this)) > _tamount);
         _token.safeTransfer(owner, _tamount);
     
    }
}