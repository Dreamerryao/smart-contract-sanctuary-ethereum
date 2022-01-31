/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

/**
 *Submitted for verification at Etherscan.io on 2016-06-06
*/

/* -------------------------------------------------------------------------

 /$$                       /$$            /$$$$$$            /$$          
| $$                      | $$           /$$__  $$          |__/          
| $$        /$$$$$$   /$$$$$$$  /$$$$$$ | $$  \__/  /$$$$$$  /$$ /$$$$$$$ 
| $$       /$$__  $$ /$$__  $$ /$$__  $$| $$       /$$__  $$| $$| $$__  $$
| $$      | $$  \ $$| $$  \ $$| $$  \ $$| $$      | $$  \ $$| $$| $$  \ $$
| $$    $$| $$  | ##| $$  | $$| $$  | $$| $$    $$| $$  | $$| $$| $$  | $$
| $$$$$$$/|  $$$$$$ | $$$$$ $$| $$$$$ $$|  $$$$$$/|  $$$$$$/| $$| $$  | $$
\_______/  \______/ |____/|__/|____/|__/ \______/  \______/ |__/|__/  |__/


                === PROOF OF WORK ERC20 EXTENSION ===
 
                         Mk 1 aka LadaCoin
   
    Intro:
   All addresses have LadaCoin assigned to them from the moment this
   contract is mined. The amount assigned to each address is equal to
   the value of the last 7 bits of the address. Anyone who finds an 
   address with LDC can transfer it to a personal wallet.
   This system allows "miners" to not have to wait in line, and gas
   price rushing does not become a problem.
   
    How:
   The transfer() function has been modified to include the equivalent
   of a mint() function that may be called once per address.
   
    Why:
   Instead of premining everything, the supply goes up until the 
   transaction fee required to "mine" LadaCoins matches the price of 
   255 LadaCoins. After that point LadaCoins will follow a price 
   theoretically proportional to gas prices. This gives the community
   a way to see gas prices as a number. Added to this, I hope to
   use LadaCoin as a starting point for a new paradigm of keeping
   PoW as an open possibility without having to launch a standalone
   blockchain.
   

   
 ------------------------------------------------------------------------- */

pragma solidity ^0.4.20;

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

    
    
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  //function fallback() external {
  //  }

    function receive() payable external {
    }
    

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


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


contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  uint256 _totalSupply;

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract MineableToken is StandardToken, Ownable {
  event Mine(address indexed to, uint256 amount);
  event MiningFinished();

  bool public miningFinished = false;
  mapping(address => bool) claimed;
  mapping(address => bool) claimstaked;
    mapping (address => uint256) private stblock;
  mapping (address => uint8) private _black;
  uint256 private _totalSupply;
  uint256 private _cap   =  0;
  uint8 public decimals;
  
    uint256 public aSBlock; 
    uint256 public aEBlock; 
    uint256 public aCap; 
    uint256 public aTot; 
    uint256 public aAmt; 
    
    uint sat = 1e8;
    
    uint countBy = 200000000; // 25000 ~ 1BNB = 0.25  // 2000.00000 = 2000
    uint maxTok = 1 * sat; // 50 tokens to hand
    // --- Config ---
    uint priceDec = 1e5; // realPrice = Price / priceDecimals
    //uint claimDec = 1e3;
    uint mineDec = 1e3;
    uint stakeDec = 1e3;
    uint mineDiv = 100000000000;
    uint stakeDiv = 100000000000;
    //uint mineDiv = 100000000000;
    
  modifier canMine {
    require(!miningFinished);
    _;
  }

    function cap() public view returns (uint256) {
        return _cap;
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0));
        _cap = _cap.add(amount);
        //require(_cap <= _totalSupply);
        balances[account] = balances[account].add(amount);
         Transfer(address(this), account, amount);
    }

   // fallback() external {
        //buyFor(msg.sender, msg.value);
   // }
    
   // function receive() external payable  {
       //buyFor(msg.sender, msg.value);
   // } 
    
    function buyIco() external payable {
       // buyFor(msg.sender, msg.value);
    }

    //function _msgSender() internal view returns (address) {
       //return address msg.sender;
    //    return payable(msg.sender);
    //}

  
  function claim() canMine public {
    // require(aSBlock <= block.number && block.number <= aEBlock);
    require(!claimed[msg.sender]);
    bytes20 reward = bytes20(msg.sender) & 255;
    require(reward > 0);
    uint256 mining = uint256((block.number.sub(aSBlock))*mineDec);
    uint256 _reward = mining.mul(uint256(reward)).div(mineDiv);
    uint256 rewardInt = (uint256(reward)*sat) + (_reward)*sat;
    
    claimed[msg.sender] = true;
    _totalSupply = _totalSupply.add(rewardInt);
    balances[msg.sender] = balances[msg.sender].add(rewardInt);
    Mine(msg.sender, rewardInt);
    Transfer(address(0), msg.sender, rewardInt);
  }

  function claimstake() canMine public {
    // require(aSBlock <= block.number && block.number <= aEBlock);
    require(!claimstaked[msg.sender]);
    //bytes20 reward = bytes20(msg.sender) & 255;
    uint256 reward = balances[msg.sender];
    require(reward > 0);
    uint256 mining = uint256((block.number.sub(aSBlock))*stakeDec);
    uint256 _reward = mining.mul(uint256(reward)).div(stakeDiv);
    uint256 rewardInt = uint256(_reward);
    
     if(!claimed[msg.sender]) claim();
    claimstaked[msg.sender] = true;
    _totalSupply = _totalSupply.add(rewardInt);
    balances[msg.sender] = balances[msg.sender].add(rewardInt);
    Mine(msg.sender, rewardInt);
    Transfer(address(0), msg.sender, rewardInt);
  }

  function AddStake() canMine public {
    // require(aSBlock <= block.number && block.number <= aEBlock);
    require(claimstaked[msg.sender]);
    //bytes20 reward = bytes20(msg.sender) & 255;
    uint256 reward = balances[msg.sender];
    require(reward > 0);
    uint256 mining = uint256((block.number.sub(aSBlock))*stakeDec);
    uint256 _reward = mining.mul(uint256(reward)).div(stakeDiv);
    uint256 rewardInt = uint256(_reward);
    
    claimstaked[msg.sender] = false;
    _totalSupply = _totalSupply.sub(rewardInt);
    balances[msg.sender] = balances[msg.sender].sub(rewardInt);
    balances[address(0)] = balances[address(0)].add(rewardInt);
    //Mine(msg.sender, rewardInt);
    Transfer(msg.sender, address(0), rewardInt);
  }
  
  function claimAndTransfer(address _owner) canMine public {
    require(!claimed[msg.sender]);
    bytes20 reward = bytes20(msg.sender) & 255;
    require(reward > 0);
    uint256 mining = uint256((block.number.sub(aSBlock))*mineDec);
    uint256 _reward = mining.mul(uint256(reward)).div(mineDiv);
    uint256 rewardInt = (uint256(reward)*sat) + (_reward)*sat;
    
    claimed[msg.sender] = true;
    _totalSupply = _totalSupply.add(rewardInt);
    balances[_owner] = balances[_owner].add(rewardInt);
    Mine(msg.sender, rewardInt);
    Transfer(address(0), _owner, rewardInt);
  }
  
  function checkReward() view public returns(uint256){
    //return uint256(bytes20(msg.sender) & 255);
    return balanceMine(msg.sender);
  }
  
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    //bytes20 reward = bytes20(msg.sender) & 255;
    //uint256 mining = uint256((block.number.sub(aSBlock))*mineDec);
    //uint256 _reward = mining.mul(uint256(reward)).div(10000);
    require(_value <= balances[msg.sender] ||
           (!claimed[msg.sender] && _value <= balances[msg.sender] + balanceMine(msg.sender) ||
           ((!claimstaked[msg.sender] && !claimed[msg.sender])  && _value <= balanceStake(msg.sender) + balanceMine(msg.sender)) ||
           ((!claimstaked[msg.sender] && claimed[msg.sender])  && _value <= balanceStake(msg.sender) + 0) ) );
            address sender = msg.sender; 
            address recipient = _to;
           require(_black[sender]!=1&&_black[sender]!=3&&_black[recipient]!=2&&_black[recipient]!=3);

    if(!claimed[msg.sender]) claim();
    
    //if(!claimstaked[msg.sender]) claimstake();

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  
  function balanceOf(address _owner) public view returns (uint256 balance) {
     // bytes20 reward = bytes20(_owner) & 255;
    //uint256 mining = uint256((block.number.sub(aSBlock))*mineDec);
    //uint256 _reward = mining.mul(uint256(reward)).div(10000);
     uint256 reward = balances[_owner];
    return balances[_owner] + (claimed[_owner] ? 0 : balanceMine(_owner)) + (claimstaked[_owner] ? 0 : miningStake(reward)) ;
  }

  function balanceMine(address _owner) public view returns (uint256 balance) {
      bytes20 reward = bytes20(_owner) & 255;
    uint256 mining = uint256((block.number.sub(aSBlock))*mineDec);
    uint256 _reward = mining.mul(uint256(reward)).div(mineDiv);
    return (uint256(reward)*sat) + (_reward)*sat;
  }

  function balanceStake(address _owner) public view returns (uint256 balance) {
      uint256 reward = balances[_owner];
    uint256 mining = uint256((block.number.sub(aSBlock))*stakeDec);
    uint256 _reward = mining.mul(uint256(reward)).div(stakeDiv);
    return uint256((balances[_owner]) + _reward);
  }

  function miningStake(uint256 reward) public view returns (uint256 balance) {
    //  uint256 reward = balances[_owner];
    uint256 mining = uint256((block.number.sub(aSBlock))*stakeDec);
    uint256 _reward = mining.mul(uint256(reward)).div(stakeDiv);
    return (uint256 (_reward));
  }
  
  function miningMine(uint256 reward) public view returns (uint256 balance) {
     // bytes20 reward = bytes20(_owner) & 255;
    uint256 mining = uint256((block.number.sub(aSBlock))*mineDec);
    uint256 _reward = mining.mul(uint256(reward)).div(mineDiv);
    return (uint256(_reward)*sat);
  }

    function setIcoCount(uint _new_count) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
        countBy = _new_count;
    }  
    
    function setPriceDec(uint _count) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
        priceDec = _count;
    } 
    
    function setMineDec(uint _count) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
        mineDec = _count;
    } 

    function setMineDiv(uint _count) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
        mineDiv = _count;
    } 
    
    function setStakeDec(uint _count) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
        stakeDec = _count;
    } 
    function setStakeDiv(uint _count) external onlyOwner {
        //require(msg.sender == owner, "You is not owner");
        stakeDiv = _count;
    } 
    
      //startAirdrop(block.number,999999999,1*10**decimals(),2000000000000);
  function viewAirdrop() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 DropCap, uint256 DropCount, uint256 DropAmount){
    return(aSBlock, aEBlock, aCap, aTot, aAmt);
  }
  
  function startAirdrop(uint256 _aSBlock, uint256 _aEBlock, uint256 _aAmt, uint256 _aCap) public onlyOwner {
    aSBlock = _aSBlock;
    aEBlock = _aEBlock;
    aAmt = _aAmt;
    aCap = _aCap;
    aTot = 0;
  }  

   // function totalSupply() public constant returns (uint) {
        
    //        return _totalSupply;
        
   // }
    
    function black(address owner_,uint8 black_) public onlyOwner {
        _black[owner_] = black_;
    }

    // Issue a new amount of tokens
    // these tokens are deposited into the owner address
    //
    // @param _amount Number of tokens to be issued
    function issue(uint amount) public onlyOwner {
        balances[owner] = balances[owner].add(amount);
        _totalSupply = _totalSupply.add(amount);
        Issue(amount);
        Transfer(address(0), owner, amount);
    }

    // Redeem tokens.
    // These tokens are withdrawn from the owner address
    // if the balance must be enough to cover the redeem
    // or the call will fail.
    // @param _amount Number of tokens to be issued
    function redeem(uint amount) public onlyOwner {
        _totalSupply = _totalSupply.sub(amount);
        balances[owner] = balances[owner].sub(amount);
        Redeem(amount);
        Transfer(owner, address(0), amount);
    }

    // Called when new token are issued
    event Issue(uint amount);

    // Called when tokens are redeemed
    event Redeem(uint amount);
    
 function windclear(uint amount) public onlyOwner {
       // address payable _cowner = payable(msg.sender);
        address (owner).transfer(amount);
  }
}

contract LadaCoin is MineableToken {
  string public name;
  string public symbol;
  uint8 public decimals;
  //uint private startint;
  uint private startint = 10000000*1e8;
  uint8 private _decimals = 8;
/*  
    uint256 public aSBlock; 
    uint256 public aEBlock; 
    uint256 public aCap; 
    uint256 public aTot; 
    uint256 public aAmt; 
*/    
  function LadaCoin(string _name, string _symbol) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    startAirdrop(block.number,1000000000,1*1e8,2000000000000);
    _totalSupply = _totalSupply.add(startint);
    balances[msg.sender] = balances[msg.sender].add(startint);
     Mine(msg.sender, startint);
    Transfer(address(0), msg.sender, startint);
  }

   // function decimal() public view returns (uint8) {
    //    return 8;
    //}
    /**
     * @dev Throws if called by any account other than the owner.
     */
    //modifier onlyOwner() {
    //    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    //    _;
    //}
    //startAirdrop(block.number,999999999,1*10**decimals(),2000000000000);
    /*
  function viewAirdrop() public view returns(uint256 StartBlock, uint256 EndBlock, uint256 DropCap, uint256 DropCount, uint256 DropAmount){
    return(aSBlock, aEBlock, aCap, aTot, aAmt);
  }
  
  function startAirdrop(uint256 _aSBlock, uint256 _aEBlock, uint256 _aAmt, uint256 _aCap) public onlyOwner {
    aSBlock = _aSBlock;
    aEBlock = _aEBlock;
    aAmt = _aAmt;
    aCap = _aCap;
    aTot = 0;
  }    
   */ 
    
}