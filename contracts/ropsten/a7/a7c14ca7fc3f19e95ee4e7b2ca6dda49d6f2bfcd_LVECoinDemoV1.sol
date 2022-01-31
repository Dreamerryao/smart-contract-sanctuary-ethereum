pragma solidity ^0.4.24;

// *-----------------------------------------------------------------------*
//       __ _    ________   __________  _____   __
//      / /| |  / / ____/  / ____/ __ \/  _/ | / /
//     / / | | / / __/    / /   / / / // //  |/ / 
//    / /__| |/ / /___   / /___/ /_/ // // /|  /  
//   /_____/___/_____/   \____/\____/___/_/ |_/  
// *-----------------------------------------------------------------------*


/**
 * @title SafeMath
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
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
 * @title Ownable
 */
contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public{
        owner = msg.sender;
    }

    // Modifier onlyOwner
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    // Transfer owner
    function transferOwnership(address _newOwner) public onlyOwner {
        // not invalid address
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}



/**
 * @title Pausable
 */
contract Pausable is Ownable {

    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused {
        require(!paused);
        _;
    }
    modifier whenPaused {
        require(paused);
        _;
    }

    // Pause contract
    function pause() public onlyOwner whenNotPaused returns (bool) {
        paused = true;
        emit Pause();
        return true;
    }

    // Unpause contract
    function unpause() public onlyOwner whenPaused returns (bool) {
        paused = false;
        emit Unpause();
        return true;
    }

}


/**
 * @title Dealershipable
 */
contract Dealershipable is Ownable {

    mapping(address => bool) public dealerships;

    // Add new dealer event
    event TrustDealer(address dealer);
    // remove dealer event
    event DistrustDealer(address dealer);


    // Different contract onlyDealer
    modifier onlyDealers() {
        require(dealerships[msg.sender]);
        _;
    }

    // Add new dealer address dealer
    function trustDealer(address _newDealer) public onlyOwner {
        // not invalid address
        require(_newDealer != address(0));
        require(!dealerships[_newDealer]);
        dealerships[_newDealer] = true;
        emit TrustDealer(_newDealer);
    }

    // Remove dealer address dealer
    function disTrustDealer(address _dealer) public onlyOwner {
        // not invalid address
        require(_dealer != address(0));
        require(dealerships[_dealer]);
        dealerships[_dealer] = false;
        emit DistrustDealer(_dealer);
    }

}



/**
 * @title ERC20 interface
 */
contract ERC20 {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
}


/**
 * @title ERC20Token
 */
contract ERC20Token is ERC20 {

    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    uint256 public totalToken;

    function totalSupply() public view returns (uint256) {
        return totalToken;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }


    // Transfer token by internal
    function _transfer(address _from, address _to, uint256 _value) internal {
        // not invalid address
        require(_from != address(0));
        require(_to != address(0));
        require(balances[_from] >= _value);
        // TODO: // Check for overflows => 待確認(ALLN.sol)
        require(balances[_to] + _value > balances[_to]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // // not invalid address 
        // require(_to != address(0));
        // require(balances[msg.sender] >= _value);
        // balances[msg.sender] = balances[msg.sender].sub(_value);
        // balances[_to] = balances[_to].add(_value);
        // emit Transfer(msg.sender, _to, _value);

        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    // 副卡轉帳
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        // not invalid address 
        require(_from != address(0));
        require(_to != address(0));
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    // 副卡授權
    function approve(address _spender, uint256 _value) public returns (bool){
        // not invalid address
        require(_spender != address(0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256){
        // not invalid address
        require(_owner != address(0));
        require(_spender != address(0));

        return allowed[_owner][_spender];
    }

}



/**
 * @title LVECoin
 */
contract LVECoinDemoV1 is ERC20Token, Pausable, Dealershipable {

    string public  constant name        = "LVECoinDemoV1";
    string public  constant symbol      = "LVEDemoV1";
    uint256 public constant decimals    = 18;
    // issue all token(20億)
    uint256 public initialToken         = 2000000000 * (10 ** decimals);

    event Mint(address indexed _dealer, address indexed _to, uint256 _value);
    event Burn(address indexed _burner, uint256 _value);
    event Lock(address indexed _locker, uint256 _value, uint _endTime);
    event UnLock(address indexed _unlocker, uint256 _value);
    event Freeze(address indexed _freezeAddr);
    event Unfreeze(address indexed _unfreezeAddr);


    // 鎖倉狀態
    struct LockedAccount{
        uint256 endTime;    //token locked end time
        address addr;       //locked address
        bool isLocked;      //is lock address
        uint256 lockAmount; // locked token amount
    }


    // locked address end time mapping
    mapping(address => uint256) public lockedEndTimeMap;
    // locked address true/false mapping
    mapping(address => bool) public isLockedMap;
    // locked address struct mapping
    mapping(address => LockedAccount) public lockedAccountMap;
    // freeze account mapping
    mapping(address => bool) public freezeAccountMap;
    
    // FoundingTeam Percent(10%)
    uint256 public foundingTeamToken;
    // Company Percent(90%)
    uint256 public companyToken;
    
    // FoundingTeam Address
    address public foundingTeamAddr;
    // Company Address
    address public companyAddr;


    constructor() public{
        // 發行量
        totalToken = initialToken;
        
        // TODO:上線後要再調整
        // FoundingTeam Percent(10%)
        foundingTeamToken = totalToken.mul(100).div(1000);
        // Company Percent(90%)
        companyToken = totalToken.mul(900).div(1000);

        // TODO:上線後要再調整
        // FoundingTeam Address
        foundingTeamAddr = 0xbfdF7e215ff6e5aC382bebAd3406527933cE56E7;
        // Company Address
        companyAddr = msg.sender;


        // Distribution Token
        // FoundingTeam Token
        balances[foundingTeamAddr] = foundingTeamToken;
        // Company Token
        balances[companyAddr] = companyToken;

        // TODO:上線後要再調整
        // Locked warehouse
        uint256 endTime = now + 0.5 hours;
        setNewlockAccount(foundingTeamAddr, endTime, foundingTeamToken);

        emit Transfer(0x0, foundingTeamAddr, foundingTeamToken);
        emit Transfer(0x0, companyAddr, companyToken);
    }

    // Distribution token
    function distributeToken(address _to, uint256 _amount) public onlyOwner {
        require(_amount > 0);
        _transfer(msg.sender, _to, _amount);
    }

    // Transfer token and lock to release time
    function distributeTokenAndLock(address _to, uint256 _amount, uint256 _endTime) public onlyOwner returns(bool){
        require(_amount > 0);
        // transfer token
        _transfer(msg.sender, _to, _amount);
        // Locked warehouse
        setNewlockAccount(_to, _endTime, _amount);
        return true;
    }



    // Is exceed lockEnd time
    modifier transferable(address _addr) {
        //判斷是否可以解鎖
        LockedAccount memory lockedAccount = lockedAccountMap[_addr];
        //  被鎖倉
        if (lockedAccount.isLocked && now > lockedAccount.endTime) {
            lockedAccount.endTime = 0;
            lockedAccount.isLocked = false;
            lockedAccount.lockAmount = 0;
            lockedAccountMap[_addr] = lockedAccount;
        }
        require(!lockedAccount.isLocked);
        _;
    }



    // Locked warehouse function 
    function setNewlockAccount(address _lockAddr, uint256 _endTime, uint256 _lockAmount) internal returns(bool){
        
        require(_lockAddr != address(0));
        require(_endTime >= now);
        require(_lockAmount > 0);

        LockedAccount memory lockedAccount;
        lockedAccount.endTime = _endTime;
        lockedAccount.addr = _lockAddr;
        lockedAccount.isLocked = true;
        lockedAccount.lockAmount = lockedAccount.lockAmount.add(_lockAmount);
        lockedAccountMap[_lockAddr] = lockedAccount;

        emit Lock(_lockAddr, _lockAmount, _endTime);
        return true;
    }


    // Is exceed lockEnd time
    modifier freezeable(address _addr) {
        require(!freezeAccountMap[_addr]);
        _;
    }


    function transfer(address _to, uint256 _value) public whenNotPaused transferable(msg.sender) freezeable(msg.sender) returns (bool) {
        return super.transfer(_to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) public transferable(msg.sender) freezeable(msg.sender) returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
    function approve(address _spender, uint256 _value) public whenNotPaused transferable(msg.sender) freezeable(msg.sender) returns (bool) {
        return super.approve(_spender, _value);
    }


    

    // Get locked account token end time
    function getLockerInfo(address _addr) public view returns (uint256 _rendTime, address _raddr, bool _risLocked, uint256 _rlockAmount) {
        LockedAccount memory locker = lockedAccountMap[_addr];
        return (locker.endTime, locker.addr, locker.isLocked, locker.lockAmount);
    }    

    // freeze account
    function freezeAccount(address _freezeAddr) public onlyOwner returns (bool) {
        require(_freezeAddr != address(0));
        freezeAccountMap[_freezeAddr] = true;
        emit Freeze(_freezeAddr);
        return true;
    }
    
    // unfreeze account
    function unfreezeAccount(address _freezeAddr) public onlyOwner returns (bool) {
        require(_freezeAddr != address(0));
        freezeAccountMap[_freezeAddr] = false;
        emit Unfreeze(_freezeAddr);
        return true;
    }




    // batch unlock address
    function unlockAddr(address _unlockAddr) public onlyOwner returns (bool){
        require(_unlockAddr != address(0));

        LockedAccount memory locker = lockedAccountMap[_unlockAddr];
        // require(locker.addr != address(0));
        if (locker.isLocked && now > locker.endTime) {
            locker.endTime = 0;
            locker.isLocked = false;
            locker.lockAmount = 0;
            lockedAccountMap[locker.addr] = locker;
            emit Unfreeze(locker.addr);
        }

        return true;
    }

  
   
    
    // if send ether then send ether to owner
    function() public payable {
        owner.transfer(msg.value);
    }


}