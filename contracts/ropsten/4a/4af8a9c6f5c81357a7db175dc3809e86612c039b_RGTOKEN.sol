pragma solidity ^0.4.0;


contract Token{
    
    //@return total amount of token
    function totalSupply() constant returns (uint256 supply) {}
    
    //@param _owner The address from which the balance will be retrieved
    //@return the balance
    function balanceOf(address _owner) constant returns (uint256 balance){}
    
    //@notice send _value token to _to from msg.sender
    //@param _to the address of the receipient
    //@param _value amount of token to be transferred
    //@return if transfer is successful or not
    function transfer(address _to,uint256 _value) returns (bool success){}
    
    //@notice send _value token to _to from _from on the condition it is approved by _from
    //@return success or fail
    function transferFrom(address _from,address _to, uint256 _value) returns (bool success) {}
    
    //@notice msg.sender approves _addr  to spend  _value tokens
    //@param success approval or not
    function approve(address _spender, uint256 value) returns (bool success) {}
    
    //@return remaining token allowed to be spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining){}
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner,address indexed _spender, uint256 _value);
    
}

contract StandardToken is Token{
    
    function transfer(address _to,uint256 _value) returns (bool success){
        
        if(balances[msg.sender] >= _value && _value >0 ){
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        else{
            return false;
        }
        
    }
    
    function transferFrom(address _from,address _to,uint256 _value) returns (bool success){
        if(balances[_from] >= _value &&  allowed[_from][msg.sender] >= _value && _value > 0){
            balances[_to] += _value;
            balances[_from] += _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from,_to,_value);
            return true;
        }else{
            return false;
        }
    }
    
    function balanceOf(address _owner)constant returns (uint256 balance){
        return balances[_owner];
    }
    
    function approve(address _spender, uint256 _value) returns(bool success){
        allowed[msg.sender][_spender]=_value;
        Approval(msg.sender,_spender,_value);
        return true;
    }
    
    function allowance(address _owner,address _spender) constant returns (uint256 remaining){
        return allowed[_owner][_spender];
        
    }
    
    mapping (address => uint256) balances;
    mapping (address => mapping(address=>uint256)) allowed;
   
    uint256 public totalSupply;
    
    
}

contract RGTOKEN is StandardToken{
    
    string  public name;
    uint8 public decimals;
    string public symbol;
    string public version= 'H1.0';
    uint256 public unitsOneEthCanBuy;
    uint256 public totalEthInWei;
    
    address  public fundsWallet;
    
    function RGTOKEN(){
        balances[msg.sender]=100000000000000000;
        totalSupply=100000000000000000;
        
        name = "RGTOKEN";
        decimals=5;
        symbol='RGT';
        unitsOneEthCanBuy=1000000000;
        fundsWallet =msg.sender;
    }
    
    function() payable {
        totalEthInWei = totalEthInWei +msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        if(balances[fundsWallet] < amount){
            return;
        }
        
        balances[fundsWallet]=balances[fundsWallet]-amount;
        balances[msg.sender]=balances[msg.sender]+amount;
        Transfer(fundsWallet,msg.sender,amount);
        
        fundsWallet.transfer(msg.value);
        
    }
    
    function approveAndCall(address _spender,uint256 _value,bytes _extraData) returns (bool success){
        allowed[msg.sender][_spender]=_value;
        Approval(msg.sender,_spender,_value);
        
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))),
            msg.sender,_value,this,_extraData)){
                throw;
            }
        return true;
    }
    
}