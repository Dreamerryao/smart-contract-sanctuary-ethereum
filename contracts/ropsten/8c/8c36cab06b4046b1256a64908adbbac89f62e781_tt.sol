pragma solidity ^0.4.25;

contract tt{
    mapping (address=>uint)balances;
    uint public totalsupply;
    string public name;
    string public symbol;
    uint public decimals;
    address public owner;
    function createToken() public returns (uint256){
        balances[msg.sender]=1000;
        totalsupply=1000;
        name='newtoken';
        symbol='new';
        decimals=0;
        owner=msg.sender;
        return totalsupply;
    }
   
  
    function increaseTS(uint amount)public onlySeller{
        totalsupply+=amount;
        balances[msg.sender]=totalsupply;
    }
    
    modifier onlySeller() { // Modifier
        require(
            msg.sender == owner,
            "Only owner can call this."
        );
        _;
    }


     
    function checkbalance(address account) public constant returns(uint balance){
        return balances[account];
        
    }
    function transfer(address account,uint amount)public payable returns(bool success){
        if(balances[msg.sender]>amount)
        {
            balances[msg.sender]-= amount;
            balances[account]+=amount;
            emit transfer1(msg.sender,account,amount);
            return true;
        }
    }
    event transfer1(address sender,address recevier,uint amount);
    
}