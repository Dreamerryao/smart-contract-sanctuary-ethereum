pragma solidity 0.4.24;


library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract ContractReceiver {     
    struct TKN {
        address sender;
        uint256 value;
        bytes data;
        bytes4 sig;
    }    
    
    function tokenFallback(address _from, uint256 _value, bytes _data) public pure {
        TKN memory tkn;
        tkn.sender = _from;
        tkn.value = _value;
        tkn.data = _data;
        uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
        tkn.sig = bytes4(u);
    }
}

contract PetToken {
    using SafeMath for uint256;

    address public owner;
    address public ownerMaster;
    string public name;
    string public symbol;
    uint8 public decimals;

    address public adminAddress;
    address public auditAddress;
    address public marketMakerAddress;
    address public mintFeeReceiver;
    address public transferFeeReceiver;
    address public burnFeeReceiver; 

    uint256 public decimalpercent = 1000000;            //precis&#227;o da porcentagem + 2 casas para 100%   
    struct feeStruct {        
        uint256 abs;
        uint256 prop;
    }
    feeStruct public mintFee;
    feeStruct public transferFee;
    feeStruct public burnFee;
    uint256 public feeAbsMax;
    uint256 public feePropMax;

    struct approveMintStruct {        
        uint256 amount;
        address admin;
        address audit;
        address marketMaker;
    }
    mapping (address => approveMintStruct) public mintApprove;

    struct approveBurnStruct {
        uint256 amount;
        address admin;
    }    
    mapping (address => approveBurnStruct) public burnApprove;

    uint256 public transferWait;
    uint256 public transferMaxAmount;
    uint256 public lastTransfer;
    bool public speedBump;


    constructor(address _ownerMaster, string _name, string _symbol, uint8 _decimals,
            uint256 _feeAbsMax, uint256 _feePropMax,
            uint256 _transferWait, uint256 _transferMaxAmount
        ) public {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        feeAbsMax = _feeAbsMax;
        feePropMax = _feePropMax;        
        ownerMaster = _ownerMaster;
        transferWait = _transferWait;
        transferMaxAmount = _transferMaxAmount;
        lastTransfer = 0;        
        speedBump = false; 

    }


    /**
    * @dev Modifiers
    */
    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Only admin");
        _;
    }

    modifier onlyAudit() {
        require(msg.sender == auditAddress, "Only audit");
        _;
    }

    modifier onlyMarketMaker() {
        require(msg.sender == marketMakerAddress, "Only market maker");
        _;
    }

    modifier noSpeedBump() {
        require(!speedBump, "Speed bump activated");
        _;
    }

    modifier hasMintPermission(address _address) {
        require(mintApprove[_address].admin != 0x0, "Require admin approval");
        require(mintApprove[_address].audit != 0x0, "Require audit approval");
        require(mintApprove[_address].marketMaker != 0x0, "Require market maker approval"); 
        _;
    }   
     
    modifier hasBurnPermission(uint256 _amount) {
        require(burnApprove[msg.sender].admin != 0x0, "Require admin / owner approval");
        require(burnApprove[msg.sender].amount == _amount, "Amount is different");
        _;
    }

    /**
    * @dev AlfaPetToken functions
    */
    function mint(address _to, uint256 _amount) public hasMintPermission(_to) canMint noSpeedBump {
        uint256 fee = calcMintFee (_amount);
        uint256 toValue = _amount.sub(fee);
        _mint(mintFeeReceiver, fee);
        _mint(_to, toValue);
        _mintApproveClear(_to);
    }

    function transfer(address _to, uint256 _amount) public returns (bool success) {
        if (speedBump) 
        {
            //Verifica valor
            require (_amount <= transferMaxAmount, "Speed bump activated, amount exceeded");

            //Verifica frequencia
            require (now > (lastTransfer + transferWait), "Speed bump activated, frequency exceeded");
            lastTransfer = now;
        }
        uint256 fee = calcTransferFee (_amount);
        uint256 toValue = _amount.sub(fee);
        _transfer(transferFeeReceiver, fee);
        _transfer(_to, toValue);
        return true;
    }

    function burn(uint256 _amount) public hasBurnPermission (_amount) {
        uint256 fee = calcBurnFee (_amount);
        uint256 fromValue = _amount.sub(fee);
        _transfer(burnFeeReceiver, fee);
        _burn(msg.sender, fromValue);
        _burnApproveClear(msg.sender);
    }

    /*
    * @dev Calc Fees
    */
    function calcMintFee(uint256 _amount) public view returns (uint256) {
        uint256 fee = 0;
        fee = _amount.div(decimalpercent);
        fee = fee.mul(mintFee.prop);
        fee = fee.add(mintFee.abs);
        return fee;
    }

    function calcTransferFee(uint256 _amount) public view returns (uint256) {
        uint256 fee = 0;
        fee = _amount.div(decimalpercent);
        fee = fee.mul(transferFee.prop);
        fee = fee.add(transferFee.abs);
        return fee;
    }

    function calcBurnFee(uint256 _amount) public view returns (uint256) {
        uint256 fee = 0;
        fee = _amount.div(decimalpercent);
        fee = fee.mul(burnFee.prop);
        fee = fee.add(burnFee.abs);
        return fee;
    }


    /**
    * @dev Set variables
    */
    function setAdmin(address _address) public onlyOwner returns (address) {
        adminAddress = _address;
        return adminAddress;
    }
    function setAudit(address _address) public onlyOwner returns (address) {
        auditAddress = _address;
        return auditAddress;
    }
    function setMarketMaker(address _address) public onlyOwner returns (address) {
        marketMakerAddress = _address;    
        return marketMakerAddress;
    }

    function setMintFeeReceiver(address _address) public onlyOwner returns (bool) {
        mintFeeReceiver = _address;
        return true;
    }
    function setTransferFeeReceiver(address _address) public onlyOwner returns (bool) {
        transferFeeReceiver = _address;
        return true;
    }
    function setBurnFeeReceiver(address _address) public onlyOwner returns (bool) {
        burnFeeReceiver = _address;
        return true;
    }

    /**
    * @dev Set Fees
    */
    event SetFee(string action, string typeFee, uint256 value);

    function setMintFeeAbs(uint256 _value) external onlyOwner returns (bool) {
        require(_value < feeAbsMax, "Must be less then maximum");
        mintFee.abs = _value;
        emit SetFee("mint", "absolute", _value);
        return true;
    }

    function setMintFeeProp(uint256 _value) external onlyOwner returns (bool) {
        require(_value < feePropMax, "Must be less then maximum");
        mintFee.prop = _value;
        emit SetFee("mint", "proportional", _value);
        return true;
    }

    function setTransferFeeAbs(uint256 _value) external onlyOwner returns (bool) {
        require(_value < feeAbsMax, "Must be less then maximum");
        transferFee.abs = _value;
        emit SetFee("transfer", "absolute", _value);
        return true;
    }
 
    function setTransferFeeProp(uint256 _value) external onlyOwner returns (bool) {
        require(_value < feePropMax, "Must be less then maximum");
        transferFee.prop = _value;
        emit SetFee("transfer", "proportional", _value);
        return true;
    }

    function setBurnFeeAbs(uint256 _value) external onlyOwner returns (bool) {
        require(_value < feeAbsMax, "Must be less then maximum");
        burnFee.abs = _value;
        emit SetFee("burn", "absolute", _value);
        return true;
    }    

    function setBurnFeeProp(uint256 _value) external onlyOwner returns (bool) {
        require(_value < feePropMax, "Must be less then maximum");
        burnFee.prop = _value;
        emit SetFee("burn", "proportional", _value);
        return true;
    }

   
    /*
    * @dev Mint Approval
    */
    function mintApproveReset(address _address) public onlyOwner {
        _mintApproveClear(_address);
    }

    function _mintApproveClear(address _address) internal {
        mintApprove[_address].amount = 0;
        mintApprove[_address].admin = 0x0;
        mintApprove[_address].audit = 0x0;
        mintApprove[_address].marketMaker = 0x0;
    }

    function mintAdminApproval(address _address, uint256 _value) public onlyAdmin {
        if (mintApprove[_address].amount > 0) {
            require(mintApprove[_address].amount == _value, "Value is diferent");
        }
        else {
            mintApprove[_address].amount = _value;
        }        
        mintApprove[_address].admin = msg.sender;
        
        if ((mintApprove[_address].audit != 0x0) && (mintApprove[_address].marketMaker != 0x0))
            mint(_address, _value);
    }

    function mintAdminCancel(address _address) public onlyAdmin {
        require(mintApprove[_address].admin == msg.sender, "Only cancel if the address is the same admin");
        mintApprove[_address].admin = 0x0;
    }

    function mintAuditApproval(address _address, uint256 _value) public onlyAudit {
        if (mintApprove[_address].amount > 0) {
            require(mintApprove[_address].amount == _value, "Value is diferent");
        }
        else {
            mintApprove[_address].amount = _value;
        }        
        mintApprove[_address].audit = msg.sender;

        if ((mintApprove[_address].admin != 0x0) && (mintApprove[_address].marketMaker != 0x0))
            mint(_address, _value);
    }

    function mintAuditCancel(address _address) public onlyAudit {
        require(mintApprove[_address].audit == msg.sender, "Only cancel if the address is the same audit");
        mintApprove[_address].audit = 0x0;
    }

    function mintMarketMakerApproval(address _address, uint256 _value) public onlyMarketMaker {
        if (mintApprove[_address].amount > 0) {
            require(mintApprove[_address].amount == _value, "Value is diferent");
        }
        else {
            mintApprove[_address].amount = _value;
        }        
        mintApprove[_address].marketMaker = msg.sender;

        if ((mintApprove[_address].admin != 0x0) && (mintApprove[_address].audit != 0x0))
            mint(_address, _value);
    }

    function mintMarketMakerCancel(address _address) public onlyMarketMaker {
        require(mintApprove[_address].marketMaker == msg.sender, "Only cancel if the address is the same marketMaker");
        mintApprove[_address].marketMaker = 0x0;
    }

    /*
    * @dev Burn Approval
    */
    function burnApproveReset(address _address) public onlyOwner {
        _burnApproveClear(_address);
    }

    function _burnApproveClear(address _address) internal {
        burnApprove[_address].amount = 0;
        burnApprove[_address].admin = 0x0;
    }      

    function burnApproval(address _address, uint256 _value) public {
        require((msg.sender == adminAddress) || (msg.sender == owner) || (msg.sender == ownerMaster), "Only admin");
        burnApprove[_address].amount = _value;
        burnApprove[_address].admin = msg.sender;
    }

    function burnCancel(address _address) public {
        require(burnApprove[_address].admin == msg.sender, "Only cancel if the address is the same");
        burnApprove[_address].admin = 0x0;
    }

    /*
    * @dev SpeedBump
    */
    event SpeedBumpUpdated(bool value);
    function setSpeedBump (bool _value) public {
        require(msg.sender == ownerMaster, "Only ownerMaster");        
        speedBump = _value;
        emit SpeedBumpUpdated(_value);
    }

    /**
    * @dev Ownable 
    * ownerMaster can not be changed.
    */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);    

    modifier onlyOwner() {
        require((msg.sender == owner) || (msg.sender == ownerMaster), "Only owner");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "newOwner must be not 0x0");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }


    /**
    * @dev Mintable token
    */
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished, "Mint is finished");
        _;
    }

    function finishMinting() public onlyOwner canMint returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    function _mint(address _account, uint256 _amount) internal canMint {
        require(_account != 0, "Address must not be zero");
        totalSupply_ = totalSupply_.add(_amount);
        balances[_account] = balances[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
        emit Mint(_account, _amount);
    }


    /**
    * @dev Burnable Token
    */
    event Burn(address indexed burner, uint256 value);

    function _burn(address _account, uint256 _amount) internal {
        require(_account != 0);
        require(_amount <= balances[_account]);

        totalSupply_ = totalSupply_.sub(_amount);
        balances[_account] = balances[_account].sub(_amount);
        emit Transfer(_account, address(0), _amount);
        emit Burn(_account, _amount);
    }

    /**
    * @dev Standard ERC20 token
    */
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    uint256 private totalSupply_;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 value);

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }    
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    function approve(address spender, uint256 value) public returns (bool success){
        //Not implemented
        return false;
    }
    function transferFrom(address from, address to, uint256 value) public returns (bool success){
        //Not implemented
        return false;
    }

    /**
    * @dev ERC223 token
    */
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
  
    function _transfer(address _to, uint256 _value, bytes _data, string _custom_fallback) private returns (bool success) {                
        if (isContract(_to)) {
            if (balanceOf(msg.sender) < _value) revert("Insuficient funds");
            balances[msg.sender] = balanceOf(msg.sender).sub(_value);
            balances[_to] = balanceOf(_to).add(_value);
            assert(_to.call.value(0)(bytes4(keccak256(abi.encodePacked(_custom_fallback))), msg.sender, _value, _data));
            emit Transfer(msg.sender, _to, _value, _data);
            return true;
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }

    function _transfer(address _to, uint256 _value, bytes _data) private returns (bool success) {            
        if(isContract(_to)) {
            return transferToContract(_to, _value, _data);
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }

    function _transfer(address _to, uint256 _value) private returns (bool success) {            
        bytes memory empty;
        if(isContract(_to)) {
            return transferToContract(_to, _value, empty);
        }
        else {
            return transferToAddress(_to, _value, empty);
        }
    }

    function isContract(address _addr) private view returns (bool is_contract) {
        uint codeLength;
        assembly {
            codeLength := extcodesize(_addr)
        }
        return (codeLength>0);
    }

    function transferToAddress(address _to, uint256 _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);        
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
  
    function transferToContract(address _to, uint256 _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

}

contract PetDataControl {

    address public ownerMaster;
    mapping (address => bool) public owner;
    uint8 public quantOwner;
    mapping (address => uint256) public mapApproval;
    address[] public arrayApproval;
    uint8 public minApproval;
    uint256 public feeAbsMaxGlobal;
    uint256 public feePropMaxGlobal;

    constructor(address _addressOwnerMaster) public {
        ownerMaster = msg.sender;       //Criado pelo endere&#231;o do PetMaster
        owner[msg.sender] = true;       
        owner[_addressOwnerMaster] = true;  //O owner do Master deve ser owner do PetDataControl
        quantOwner = 2; 
        arrayApproval.push(0x0);        //O indice zero do array n&#227;o ser&#225; utilizado
        minApproval = 1;     
    }

    /*
    * @dev Events
    */
    event OwnerAdded(address indexed _address);
    event OwnerDeleted(address indexed _address);
    event MinApprovalChanged(uint8 _minBefore, uint8 _minActual);

    /**
    * @dev Modifiers
    */
    modifier onlyApproved() {
        require((arrayApproval.length - 1) >= minApproval, "DataControl current approvals is less then minimum");
        _;
    }

    modifier onlyOwner() {
        require(owner[msg.sender], "DataControl only owner");
        _;
    }

    modifier onlyMasterOwner() {
        require(ownerMaster == msg.sender, "DataControl only master owner");
        _;
    }    

    modifier notApproved() {
        require(mapApproval[msg.sender] <= 0, "DataControl already approved");
        _;
    }    

    modifier isApproved() {
        require(mapApproval[msg.sender] > 0, "DataControl not approved yet");
        _;
    }

    /*
    * @dev Controller Master functions
    */
    function changeMinApproval(uint8 _minApproval) public onlyMasterOwner onlyApproved {
        uint8 _minBefore = minApproval;
        minApproval = _minApproval;
        emit MinApprovalChanged(_minBefore, _minApproval);
        _clearAllApproval();        
    } 

    function addOwner(address _address) public onlyMasterOwner {
        owner[_address] = true;
        quantOwner += 1;
        emit OwnerAdded(_address);
    }    

    function delOwner(address _address) public onlyMasterOwner {
        require(quantOwner > minApproval, "quantOwner must be equal or greater than minApproval");
        require(msg.sender != _address, "Can not remove yourself");
        owner[_address] = false;
        quantOwner -= 1;
        emit OwnerDeleted(_address);
    }

    /*
    * @dev Address approvals
    */
    function doApproval() public onlyOwner notApproved {
        uint256 index = arrayApproval.push(msg.sender) - 1;
        mapApproval[msg.sender] = index;
    } 

    function cancelApproval() public onlyOwner isApproved {
        uint256 index = mapApproval[msg.sender];
        mapApproval[msg.sender] = 0;

        uint256 length_ = arrayApproval.length;
        if (index < length_) 
        {
            for (uint256 i = index; i < length_ - 1; i++) {
                arrayApproval[i] = arrayApproval[i+1];
            }
            delete arrayApproval[length_ - 1];
            arrayApproval.length--;
        }
    } 

    //Limpa as aprova&#231;&#245;es
    function resetAllApproval() public onlyOwner onlyApproved {
        _clearAllApproval();
    } 

    function _clearAllApproval() internal {
        uint256 length_ = arrayApproval.length;
        if (length_ > 1) {
            for (uint256 i = 1; i < length_; i++) {
                mapApproval[arrayApproval[i]] = 0;
            }
        }
        delete arrayApproval;
        arrayApproval.push(0x0);
    }

    //Verifica se determinado endere&#231;o aprovou
    function checkApproval(address _address) public view returns (uint256) {
        uint256 index = mapApproval[_address];
        return index;
    } 

    //Lista endere&#231;os que aprovaram
    function listApproval() public view returns (address[]) {
        return arrayApproval;
    }

    //Lista quantidade de aprova&#231;&#245;es
    function countApproval() public view returns (uint256) {
        return arrayApproval.length - 1;
    }    

    function lengthArrayApproval() public view returns (uint256) {
        return arrayApproval.length;
    }

    //Getters
    function getOwner(address _address) public view returns (bool) {      
        return owner[_address];
    }

    //Global max fees
    event SetFee(string typeFee, uint256 value);
    function setFeeAbsMaxGlobal(uint256 _value) public onlyMasterOwner onlyApproved {
        feeAbsMaxGlobal = _value;
        _clearAllApproval();
        emit SetFee("Absolute Max Global", _value);
    }
    function setFeePropMaxGlobal(uint256 _value) public onlyMasterOwner onlyApproved {
        feePropMaxGlobal = _value;
        _clearAllApproval();
        emit SetFee("Proportional Max Global", _value);
    }    
}

contract PetController {
    address public ownerMaster;
    PetDataControl public dataControl;

    constructor(address _addressDataControl) public {
        ownerMaster = msg.sender;       //Criado pelo endere&#231;o do Master
        dataControl = PetDataControl(_addressDataControl);
    }

    /**
    * @dev Modifiers
    */
    modifier onlyOwner() {
        //Somente alguem do array de owners do DataControl pode chamar
        require(dataControl.getOwner(msg.sender), "Only owner");
        _;
    }
    modifier onlyApproved() {
        require(dataControl.countApproval() >= dataControl.minApproval(), "Current approvals is less then minimum");
        _;
    }    


    /*
    * @dev Token
    */
    function tokenSetAdmin(address _addressToken, address _address) public onlyOwner onlyApproved {
        dataControl.resetAllApproval();
        PetToken token = PetToken(_addressToken);
        token.setAdmin(_address);
    }
    function tokenSetAudit(address _addressToken, address _address) public onlyOwner onlyApproved {
        dataControl.resetAllApproval();
        PetToken token = PetToken(_addressToken);
        token.setAudit(_address);
    }
    function tokenSetMarketMaker(address _addressToken, address _address) public onlyOwner onlyApproved {
        dataControl.resetAllApproval();
        PetToken token = PetToken(_addressToken);
        token.setMarketMaker(_address);
    }
    function tokenSetMintFeeReceiver(address _addressToken, address _address) public onlyOwner onlyApproved {
        dataControl.resetAllApproval();
        PetToken token = PetToken(_addressToken);
        token.setMintFeeReceiver(_address);
    }
    function tokenSetTransferFeeReceiver(address _addressToken, address _address) public onlyOwner onlyApproved {
        dataControl.resetAllApproval();
        PetToken token = PetToken(_addressToken);
        token.setTransferFeeReceiver(_address);
    }
    function tokenSetBurnFeeReceiver(address _addressToken, address _address) public onlyOwner onlyApproved {
        dataControl.resetAllApproval();
        PetToken token = PetToken(_addressToken);
        token.setBurnFeeReceiver(_address);
    }

    function tokenSetMintFeeAbs(address _addressToken, uint256 _value) public onlyOwner onlyApproved {
        dataControl.resetAllApproval();
        PetToken token = PetToken(_addressToken);
        token.setMintFeeAbs(_value);
    }
    function tokenSetMintFeeProp(address _addressToken, uint256 _value) public onlyOwner onlyApproved {
        dataControl.resetAllApproval();
        PetToken token = PetToken(_addressToken);
        token.setMintFeeProp(_value);
    }
    function tokenSetTransferFeeAbs(address _addressToken, uint256 _value) public onlyOwner onlyApproved {
        dataControl.resetAllApproval();
        PetToken token = PetToken(_addressToken);
        token.setTransferFeeAbs(_value);
    }
    function tokenSetTransferFeeProp(address _addressToken, uint256 _value) public onlyOwner onlyApproved {
        dataControl.resetAllApproval();
        PetToken token = PetToken(_addressToken);
        token.setTransferFeeProp(_value);
    }
    function tokenSetBurnFeeAbs(address _addressToken, uint256 _value) public onlyOwner onlyApproved {
        dataControl.resetAllApproval();
        PetToken token = PetToken(_addressToken);
        token.setBurnFeeAbs(_value);
    }
    function tokenSetBurnFeeProp(address _addressToken, uint256 _value) public onlyOwner onlyApproved {
        dataControl.resetAllApproval();
        PetToken token = PetToken(_addressToken);
        token.setBurnFeeProp(_value);
    }

}

contract PetMaster {

    /**
    * @dev Contract settings
    */
    mapping (address => bool) public owner;
    uint8 public quantOwner;
    mapping (address => uint256) public mapApproval;
    address[] public arrayApproval;
    uint8 public minApproval;
    address public addressController;  //address do smart contract Controller
    address public addressDataControl;  //address do smart contract DataControl

    constructor() public {
        arrayApproval.push(0x0);    //O indice zero do array n&#227;o ser&#225; utilizado
        minApproval = 1;
        owner[msg.sender] = true;
        quantOwner = 1;     
    }

    /*
    * @dev Modifiers
    */
    modifier onlyApproved() {
        require((arrayApproval.length - 1) >= minApproval, "Master current approvals is less then minimum");
        _;
    }
    modifier onlyOwner() {
        require(owner[msg.sender], "Master only owner");
        _;
    }
    modifier notApproved() {
        require(mapApproval[msg.sender] <= 0, "Master already approved");
        _;
    }
    modifier isApproved() {
        require(mapApproval[msg.sender] > 0, "Master not approved yet");
        _;
    }

    /*
    * @dev Master functions
    */
    event MasterOwnerAdded(address indexed _address);
    event MasterOwnerDeleted(address indexed _address);
    event MasterMinApprovalChanged(uint8 _minBefore, uint8 _minActual);

    function changeMinApproval(uint8 _minApproval) public onlyOwner onlyApproved {
        uint8 _minBefore = minApproval;
        minApproval = _minApproval;
        emit MasterMinApprovalChanged(_minBefore, _minApproval);
        _clearAllApproval();
    } 

    function addOwner(address _address) public onlyOwner onlyApproved {
        owner[_address] = true;
        quantOwner += 1;
        emit MasterOwnerAdded(_address);
        _clearAllApproval();
    }    

    function delOwner(address _address) public onlyOwner onlyApproved {
        require(quantOwner > minApproval, "quantOwner must be equal or greater than minApproval");
        require(msg.sender != _address, "Can not remove yourself");
        owner[_address] = false;
        quantOwner -= 1;
        emit MasterOwnerDeleted(_address);
        _clearAllApproval();
    }


    /*
    * @dev Address approvals
    */
    function doApproval() public onlyOwner notApproved {
        uint256 index = arrayApproval.push(msg.sender) - 1;
        mapApproval[msg.sender] = index;
    } 

    function cancelApproval() public onlyOwner isApproved {
        uint256 index = mapApproval[msg.sender];
        mapApproval[msg.sender] = 0;
        uint256 length_ = arrayApproval.length;
        if (index < length_) 
        {
            for (uint256 i = index; i < length_ - 1; i++) {
                arrayApproval[i] = arrayApproval[i+1];
            }
            delete arrayApproval[length_ - 1];
            arrayApproval.length--;
        }
    } 

    //Limpa as aprova&#231;&#245;es
    function resetAllApproval() public onlyOwner onlyApproved {
        _clearAllApproval();
    } 

    function _clearAllApproval() internal {
        uint256 length_ = arrayApproval.length;
        if (length_ > 1) {
            for (uint256 i = 1; i < length_; i++) {
                mapApproval[arrayApproval[i]] = 0;
            }
        }
        delete arrayApproval;
        arrayApproval.push(0x0);
    }

    //Verifica se determinado endere&#231;o aprovou
    function checkApproval(address _address) public view returns (uint256) {
        uint256 index = mapApproval[_address];
        return index;
    } 

    //Lista endere&#231;os que aprovaram
    function listApproval() public view returns (address[]) {
        return arrayApproval;
    }

    //Lista quantidade de aprova&#231;&#245;es
    function countApproval() public view returns (uint256) {
        return arrayApproval.length - 1;
    }
    
    /*
    * @dev DataControl
    */
    function createDataControl() public onlyOwner onlyApproved returns (address) {
        _clearAllApproval();
        address auxAddress = new PetDataControl (msg.sender);
        addressDataControl = auxAddress;
        return address(auxAddress);
    }

    function dataControlChangeMinApproval(uint8 _minApproval) public onlyOwner onlyApproved {
        _clearAllApproval();
        PetDataControl dataControl = PetDataControl(addressDataControl);
        dataControl.changeMinApproval(_minApproval);
    } 

    function dataControlAddOwner(address _address) public onlyOwner onlyApproved {
        _clearAllApproval();
        PetDataControl dataControl = PetDataControl(addressDataControl);
        dataControl.addOwner(_address);
    }    

    function dataControlDelOwner(address _address) public onlyOwner onlyApproved {
        _clearAllApproval();
        PetDataControl dataControl = PetDataControl(addressDataControl);
        dataControl.delOwner(_address);
    }

    function dataControlSetFeeAbsMaxGlobal(uint256 _value) public onlyOwner onlyApproved {
        _clearAllApproval();
        PetDataControl dataControl = PetDataControl(addressDataControl);
        dataControl.setFeeAbsMaxGlobal(_value);
    }
    function dataControlSetFeePropMaxGlobal(uint256 _value) public onlyOwner onlyApproved {
        _clearAllApproval();
        PetDataControl dataControl = PetDataControl(addressDataControl);
        dataControl.setFeePropMaxGlobal(_value);
    } 

    /*
    * @dev Controller
    */
    function createController() public onlyOwner onlyApproved returns (address) {
        _clearAllApproval();
        require(addressDataControl != address(0), "addressDataControl must be set");
        address auxAddress = new PetController(addressDataControl);
        addressController = auxAddress;
        return address(auxAddress);
    }

    /*
    * @dev Token
    */
    function tokenSetAdmin(address _addressToken, address _address) public onlyOwner onlyApproved {
        _clearAllApproval();
        PetToken token = PetToken(_addressToken);
        token.setAdmin(_address);
    }
    function tokenSetAudit(address _addressToken, address _address) public onlyOwner onlyApproved {
        _clearAllApproval();
        PetToken token = PetToken(_addressToken);
        token.setAudit(_address);
    }
    function tokenSetMarketMaker(address _addressToken, address _address) public onlyOwner onlyApproved {
        _clearAllApproval();
        PetToken token = PetToken(_addressToken);
        token.setMarketMaker(_address);
    }
    function tokenSetMintFeeReceiver(address _addressToken, address _address) public onlyOwner onlyApproved {
        _clearAllApproval();
        PetToken token = PetToken(_addressToken);
        token.setMintFeeReceiver(_address);
    }
    function tokenSetTransferFeeReceiver(address _addressToken, address _address) public onlyOwner onlyApproved {
        _clearAllApproval();
        PetToken token = PetToken(_addressToken);
        token.setTransferFeeReceiver(_address);
    }
    function tokenSetBurnFeeReceiver(address _addressToken, address _address) public onlyOwner onlyApproved {
        _clearAllApproval();
        PetToken token = PetToken(_addressToken);
        token.setBurnFeeReceiver(_address);
    }

    function tokenSetMintFeeAbs(address _addressToken, uint256 _value) public onlyOwner onlyApproved {
        _clearAllApproval();
        PetToken token = PetToken(_addressToken);
        token.setMintFeeAbs(_value);
    }
    function tokenSetMintFeeProp(address _addressToken, uint256 _value) public onlyOwner onlyApproved {
        _clearAllApproval();
        PetToken token = PetToken(_addressToken);
        token.setMintFeeProp(_value);
    }
    function tokenSetTransferFeeAbs(address _addressToken, uint256 _value) public onlyOwner onlyApproved {
        _clearAllApproval();
        PetToken token = PetToken(_addressToken);
        token.setTransferFeeAbs(_value);
    }
    function tokenSetTransferFeeProp(address _addressToken, uint256 _value) public onlyOwner onlyApproved {
        _clearAllApproval();
        PetToken token = PetToken(_addressToken);
        token.setTransferFeeProp(_value);
    }
    function tokenSetBurnFeeAbs(address _addressToken, uint256 _value) public onlyOwner onlyApproved {
        _clearAllApproval();
        PetToken token = PetToken(_addressToken);
        token.setBurnFeeAbs(_value);
    }
    function tokenSetBurnFeeProp(address _addressToken, uint256 _value) public onlyOwner onlyApproved {
        _clearAllApproval();
        PetToken token = PetToken(_addressToken);
        token.setBurnFeeProp(_value);
    }
    function tokenSetSpeedBump (address _addressToken, bool _value) public onlyOwner onlyApproved {
        _clearAllApproval();
        PetToken token = PetToken(_addressToken);
        token.setSpeedBump(_value);
    }

}

contract PetCreator {
    address public owner;
    address public ownerMaster;
    address public addresController;
    PetDataControl public dataControl;
    address[] public arrayTokens;

    constructor(address _ownerMaster, address _addressDataControl, address _addresController) public {
        owner = msg.sender;
        ownerMaster = _ownerMaster;
        dataControl = PetDataControl(_addressDataControl);
        addresController = _addresController;
    }

    /*
    * @dev Token functions
    */
    function createToken (
        string _name, string _symbol, uint8 _decimals,
        uint256 _feeAbsMax, uint256 _feePropMax,
        uint256 _transferWait, uint256 _transferMaxAmount
    ) public returns (address)     
    {
        require(dataControl.getOwner(msg.sender), "CreateToken only owner");
        require(dataControl.countApproval() >= dataControl.minApproval(), "CreateToken current approvals is less then minimum");
        require (_feeAbsMax <= dataControl.feeAbsMaxGlobal(), "CreateToken feeAbsMax must be <= globalMintFeeAbsMax");
        require (_feePropMax <= dataControl.feePropMaxGlobal(), "CreateToken feePropMax must be <= globalTransferFeeAbsMax");
        dataControl.resetAllApproval(); 

        address tokenAddress = new PetToken (
            ownerMaster, _name, _symbol, _decimals, _feeAbsMax, _feePropMax, _transferWait, _transferMaxAmount);
        arrayTokens.push(tokenAddress);
        //Transfere ownership para controller
        PetToken token = PetToken(tokenAddress);
        token.transferOwnership(addresController);
        return tokenAddress;

    }

}