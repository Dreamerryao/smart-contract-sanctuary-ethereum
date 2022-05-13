pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// 'ADE' 'AdeCoin' token contract
//
// Symbol      : ADE
// Name        : AdeCoin
// Total supply: Generated from contributions
// Decimals    : 8
//
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event TransferSell(address indexed from, uint tokens, uint eth);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals
// Receives ETH and generates tokens
// ----------------------------------------------------------------------------
contract MyToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public totalSupply;
    uint public sellRate;
    uint public buyRate;
    
    //uint private lockRate = 30 days;
    uint private lockRate = 30;
    
    struct lockPosition{
        uint time;
        uint count;
        uint releaseRate;
    }
    
    struct lockPosition1{
        uint8 typ; // 1 2 3 4
        uint count;
        uint time1;
        uint8 releaseRate1;
        uint time2;
        uint8 releaseRate2;
        uint time3;
        uint8 releaseRate3;
        uint time4;
        uint8 releaseRate4;
    }
    
    
    mapping(address => lockPosition) private lposition;
    mapping(address => lockPosition1) public lposition1;
    
    // locked account dictionary that maps addresses to boolean
    mapping (address => bool) private lockedAccounts;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    modifier is_not_locked(address _address) {
        if (lockedAccounts[_address] == true) revert();
        _;
    }
    
    modifier validate_address(address _address) {
        if (_address == address(0)) revert();
        _;
    }
    
    modifier is_locked(address _address) {
        if (lockedAccounts[_address] != true) revert();
        _;
    }
    
    modifier validate_position(address _address,uint count) {
        if(balances[_address] < count) revert();
        if(lposition[_address].count > 0 && safeSub(balances[_address],count) < lposition[_address].count && now < lposition[_address].time) revert();
        if(lposition1[_address].count > 0 && safeSub(balances[_address],count) < lposition1[_address].count && now < lposition1[_address].time1) revert();
        checkPosition1(_address,count);
        checkPosition(_address,count);
        _;
    }
    
    function checkPosition(address _address,uint count) private view {
        if(lposition[_address].releaseRate < 100 && lposition[_address].count > 0){
            uint _rate = safeDiv(100,lposition[_address].releaseRate);
            uint _time = lposition[_address].time;
            uint _tmpRate = lposition[_address].releaseRate;
            uint _tmpRateAll = 0;
            uint _count = 0;
            for(uint _a=1;_a<=_rate;_a++){
                if(now >= _time){
                    _count = _a;
                    _tmpRateAll = safeAdd(_tmpRateAll,_tmpRate);
                    _time = safeAdd(_time,lockRate);
                }
            }
            uint _tmp1 = safeSub(balances[_address],count);
            uint _tmp2 = safeSub(lposition[_address].count,safeDiv(lposition[_address].count*_tmpRateAll,100));
            if(_count < _rate && _tmp1 < _tmp2  && now >= lposition[_address].time) revert();
        }
    }
    
    function lockSupplierAndLockPosition(address _address) private view returns (uint _count){
        if(lposition[_address].count > 0 && now < lposition[_address].time){
            return lposition[_address].count;
        }else if(lposition[_address].count > 0 && now >= lposition[_address].time){
            return getPositionCount(_address);
        }else if(lposition[_address].count == 0){
            return 0;
        }
    }
    
    function getPositionCount(address _address) private view returns (uint _countAll) {
        if(lposition[_address].releaseRate < 100 && lposition[_address].count > 0){
            uint _rate = safeDiv(100,lposition[_address].releaseRate);
            uint _time = lposition[_address].time;
            uint _tmpRate = lposition[_address].releaseRate;
            uint _tmpRateAll = 0;
            uint _count = 0;
            for(uint _a=1;_a<=_rate;_a++){
                if(now >= _time){
                    _count = _a;
                    _tmpRateAll = safeAdd(_tmpRateAll,_tmpRate);
                    _time = safeAdd(_time,lockRate);
                }
            }
            
            uint _tmp = safeSub(lposition[_address].count,safeDiv(lposition[_address].count*_tmpRateAll,100));
            
            if(_count < _rate && now >= lposition[_address].time){
                return _tmp;
            }else{
                return 0;
            }
        }
    }
    
    
    function checkPosition1(address _address,uint count) private view {
        if(lposition1[_address].releaseRate1 < 100 && lposition1[_address].count > 0){
            uint _tmpRateAll = 0;
            
            if(lposition1[_address].typ == 2 && now < lposition1[_address].time2){
                if(now >= lposition1[_address].time1){
                    _tmpRateAll = lposition1[_address].releaseRate1;
                }
            }
            
            if(lposition1[_address].typ == 3 && now < lposition1[_address].time3){
                if(now >= lposition1[_address].time1){
                    _tmpRateAll = lposition1[_address].releaseRate1;
                }
                if(now >= lposition1[_address].time2){
                    _tmpRateAll = safeAdd(lposition1[_address].releaseRate2,_tmpRateAll);
                }
            }
            
            if(lposition1[_address].typ == 4 && now < lposition1[_address].time4){
                if(now >= lposition1[_address].time1){
                    _tmpRateAll = lposition1[_address].releaseRate1;
                }
                if(now >= lposition1[_address].time2){
                    _tmpRateAll = safeAdd(lposition1[_address].releaseRate2,_tmpRateAll);
                }
                if(now >= lposition1[_address].time3){
                    _tmpRateAll = safeAdd(lposition1[_address].releaseRate3,_tmpRateAll);
                }
            }
            
            uint _tmp1 = safeSub(balances[_address],count);
            uint _tmp2 = safeSub(lposition1[_address].count,safeDiv(lposition1[_address].count*_tmpRateAll,100));
            
            if(_tmpRateAll > 0){
                if(_tmp1 < _tmp2) revert();
            }
        }
    }
    
    function lockSupplierAndLockPosition1(address _address) private view returns (uint _count){
        if(lposition1[_address].count > 0 && now < lposition1[_address].time1){
            return lposition1[_address].count;
        }else if(lposition1[_address].count > 0 && now >= lposition1[_address].time1){
            return getPositionCount1(_address);
        }else if(lposition1[_address].count == 0){
            return 0;
        }
        
    }
    
    function getPositionCount1(address _address) private view returns (uint _countAll) {
        if(lposition1[_address].releaseRate1 < 100){
            
            uint _tmpRateAll = 0;
            
            if(lposition1[_address].typ == 2 && now < lposition1[_address].time2){
                _tmpRateAll = lposition1[_address].releaseRate1;
            }
            
            if(lposition1[_address].typ == 3 && now < lposition1[_address].time3){
                
                _tmpRateAll = lposition1[_address].releaseRate1;
                
                if(lposition1[_address].time2 >= now){
                    _tmpRateAll = safeAdd(lposition1[_address].releaseRate2,_tmpRateAll);
                }
            }
            
            if(lposition1[_address].typ == 4 && now < lposition1[_address].time4){
                
                _tmpRateAll = lposition1[_address].releaseRate1;
                
                if(lposition1[_address].time2 >= now){
                    _tmpRateAll = safeAdd(lposition1[_address].releaseRate2,_tmpRateAll);
                }
                
                if(lposition1[_address].time3 >= now){
                    _tmpRateAll = safeAdd(lposition1[_address].releaseRate3,_tmpRateAll);
                }
            }
            
            if(lposition1[_address].typ == 2 && now >= lposition1[_address].time2){
                _tmpRateAll = 100;
            }
            
            if(lposition1[_address].typ == 3 && now >= lposition1[_address].time3){
                _tmpRateAll = 100;
            }
            
            if(lposition1[_address].typ == 4 && now >= lposition1[_address].time4){
                _tmpRateAll = 100;
            }
            
            if(_tmpRateAll > 0 && _tmpRateAll != 100){
                uint _tmp = safeSub(lposition1[_address].count,safeDiv(lposition1[_address].count*_tmpRateAll,100));
                return _tmp;
            }else{
                return 0;
            }
        }
        return 0;
    }
    
    event _lockAccount(address _add);
    event _unlockAccount(address _add);
    
    function () public payable{
        uint tokens;
        require(owner != msg.sender);
        require(buyRate > 0);
        require(msg.value >= 0.1 ether && msg.value <= 1000 ether);
        
        tokens = msg.value / (1 ether * 1 wei / buyRate);
        require(balances[owner] >= tokens * 10**uint(decimals));
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens * 10**uint(decimals));
        balances[owner] = safeSub(balances[owner], tokens * 10**uint(decimals));
    }

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function MyToken(uint _sellRate,uint _buyRate,string _symbo1,string _name) public payable {
        require(_sellRate >0 && _buyRate > 0);
        symbol = _symbo1;
        name = _name;
        decimals = 8;
        totalSupply = 2000000000 * 10**uint(decimals);
        balances[owner] = totalSupply;
        Transfer(address(0), owner, totalSupply);
        sellRate = _sellRate;
        buyRate = _buyRate;
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public is_not_locked(msg.sender) is_not_locked(to) validate_position(msg.sender,tokens) returns (bool success) {
        require(to != msg.sender);
        require(tokens > 0);
        require(balances[msg.sender] >= tokens);
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public is_not_locked(msg.sender) is_not_locked(spender) validate_position(msg.sender,tokens) returns (bool success) {
        require(spender != msg.sender);
        require(tokens > 0);
        require(balances[msg.sender] >= tokens);
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public is_not_locked(msg.sender) is_not_locked(from) is_not_locked(to) validate_position(from,tokens) returns (bool success) {
        require(transferFromCheck(from,to,tokens));
        return true;
    }
    
    function transferFromCheck(address from,address to,uint tokens) private returns (bool success) {
        require(tokens > 0);
        require(from != msg.sender && msg.sender != to && from != to);
        require(balances[from] >= tokens && allowed[from][msg.sender] >= tokens);
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    

    // ------------------------------------------------------------------------
    // Sall a token from a contract
    // ------------------------------------------------------------------------
    function sellCoin(address seller, uint amount) public onlyOwner is_not_locked(seller) validate_position(seller,amount* 10**uint(decimals)) {
        require(balances[seller] >= amount * 10**uint(decimals) && amount * 10**uint(decimals) > 0);
        require(sellRate > 0);
        require(seller != msg.sender);
        uint tmpAmount = amount * (1 ether * 1 wei / sellRate);
        
        balances[owner] += amount * 10**uint(decimals);
        balances[seller] -= amount * 10**uint(decimals);
        
        seller.transfer(tmpAmount);
        TransferSell(seller, amount * 10**uint(decimals), tmpAmount);
    }
    
    // set rate
    function setRate(uint _buyRate,uint _sellRate) public onlyOwner {
        require(_buyRate > 0);
        require(_sellRate > 0);
        require(_buyRate < _sellRate);
        buyRate = _buyRate;
        sellRate = _sellRate;
    }
    
    // lockAccount
    function lockStatus(address _add) public is_not_locked(_add)  validate_address(_add) onlyOwner {
        lockedAccounts[_add] = true;
        _lockAccount(_add);
    }

    /// @notice only the admin is allowed to unlock accounts.
    /// @param _add the address of the account to be unlocked
    function unlockStatus(address _add) public is_locked(_add) validate_address(_add) onlyOwner {
        lockedAccounts[_add] = false;
        _unlockAccount(_add);
    }
    
    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    //set lock position
    function setLockPostion(address _add,uint _count,uint _time,uint _releaseRate) public is_not_locked(_add) onlyOwner {
        require(lposition1[_add].count == 0);
        require(_time > now);
        require(_count > 0);
        require(_releaseRate > 0 && _releaseRate < 100);
        require(_releaseRate == 2 || _releaseRate == 4 || _releaseRate == 5 || _releaseRate == 10 || _releaseRate == 20 || _releaseRate == 25 || _releaseRate == 50);
        require(balances[_add] >= _count * 10**uint(decimals));
        lposition[_add].time = _time;
        lposition[_add].count = _count * 10**uint(decimals);
        lposition[_add].releaseRate = _releaseRate;
    }
    
    //get lockPosition info
    function getLockPosition(address _add) public view returns(uint time,uint count,uint rate,uint scount) {
        return (lposition[_add].time,lposition[_add].count,lposition[_add].releaseRate,positionScount(_add));
    }
    
    function positionScount(address _add) private view returns (uint count){
        uint _rate = safeDiv(100,lposition[_add].releaseRate);
        uint _time = lposition[_add].time;
        uint _tmpRate = lposition[_add].releaseRate;
        uint _tmpRateAll = 0;
        for(uint _a=1;_a<=_rate;_a++){
            if(now >= _time){
                _tmpRateAll = safeAdd(_tmpRateAll,_tmpRate);
                _time = safeAdd(_time,lockRate);
            }
        }
        
        return (lposition[_add].count - safeDiv(lposition[_add].count*_tmpRateAll,100));
    }
    
    
    //set lock position
    function setLockPostion1(address _add,uint _count,uint8 _typ,uint _time1,uint8 _releaseRate1,uint _time2,uint8 _releaseRate2,uint _time3,uint8 _releaseRate3,uint _time4,uint8 _releaseRate4) public is_not_locked(_add) onlyOwner {
        require(_count > 0);
        require(_time1 > now);
        require(_releaseRate1 > 0);
        require(_typ >= 1 && _typ <= 4);
        require(balances[_add] >= _count * 10**uint(decimals));
        require(safeAdd(safeAdd(_releaseRate1,_releaseRate2),safeAdd(_releaseRate3,_releaseRate4)) == 100);
        require(lposition[_add].count == 0);
        
        if(_typ == 1){
            require(_time2 == 0 && _releaseRate2 == 0 && _time3 == 0 && _releaseRate3 == 0);
        }
        if(_typ == 2){
            require(_time2 > _time1 && _releaseRate2 > 0 && _time3 == 0 && _releaseRate3 == 0);
        }
        if(_typ == 3){
            require(_time2 > _time1 && _releaseRate2 > 0 && _time3 > _time2 && _releaseRate3 > 0);
        }
        if(_typ == 4){
            require(_time2 > _time1 && _releaseRate2 > 0 && _releaseRate3 > 0 && _time3 > _time2 && _time4 > _time3 && _releaseRate4 > 0);
        }
        
        lockPostion1Add(_typ,_add,_count,_time1,_releaseRate1,_time2,_releaseRate2,_time3,_releaseRate3,_time4,_releaseRate4);
    }
    
    function lockPostion1Add(uint8 _typ,address _add,uint _count,uint _time1,uint8 _releaseRate1,uint _time2,uint8 _releaseRate2,uint _time3,uint8 _releaseRate3,uint _time4,uint8 _releaseRate4) private {
        lposition1[_add].typ = _typ;
        lposition1[_add].count = _count * 10**uint(decimals);
        lposition1[_add].time1 = _time1;
        lposition1[_add].releaseRate1 = _releaseRate1;
        lposition1[_add].time2 = _time2;
        lposition1[_add].releaseRate2 = _releaseRate2;
        lposition1[_add].time3 = _time3;
        lposition1[_add].releaseRate3 = _releaseRate3;
        lposition1[_add].time4 = _time4;
        lposition1[_add].releaseRate4 = _releaseRate4;
    }
    
    //get lockPosition1 info
    function getLockPosition1(address _add) public view returns(uint count,uint Scount) {
        return (lposition1[_add].count,positionScount1(_add));
    }
    
    function positionScount1(address _address) private view returns (uint count){
        
        uint _tmpRateAll = 0;
            
        if(lposition1[_address].typ == 2 && now < lposition1[_address].time2){
            if(now >= lposition1[_address].time1){
                _tmpRateAll = lposition1[_address].releaseRate1;
            }
        }
        
        if(lposition1[_address].typ == 3 && now < lposition1[_address].time3){
            if(now >= lposition1[_address].time1){
                _tmpRateAll = lposition1[_address].releaseRate1;
            }
            if(now >= lposition1[_address].time2){
                _tmpRateAll = safeAdd(lposition1[_address].releaseRate2,_tmpRateAll);
            }
        }
        
        if(lposition1[_address].typ == 4 && now < lposition1[_address].time4){
            if(now >= lposition1[_address].time1){
                _tmpRateAll = lposition1[_address].releaseRate1;
            }
            if(now >= lposition1[_address].time2){
                _tmpRateAll = safeAdd(lposition1[_address].releaseRate2,_tmpRateAll);
            }
            if(now >= lposition1[_address].time3){
                _tmpRateAll = safeAdd(lposition1[_address].releaseRate3,_tmpRateAll);
            }
        }
        
        if((lposition1[_address].typ == 1 && now >= lposition1[_address].time1) || (lposition1[_address].typ == 2 && now >= lposition1[_address].time2) || (lposition1[_address].typ == 3 && now >= lposition1[_address].time3) || (lposition1[_address].typ == 4 && now >= lposition1[_address].time4)){
            return 0;
        }
        
        if(_tmpRateAll > 0){
            return (safeSub(lposition1[_address].count,safeDiv(lposition1[_address].count*_tmpRateAll,100)));
        }else{
            return lposition1[_address].count;
        }
    }
}