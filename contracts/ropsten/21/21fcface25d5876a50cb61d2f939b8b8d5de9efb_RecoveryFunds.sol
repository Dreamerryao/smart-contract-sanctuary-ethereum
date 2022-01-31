pragma solidity 0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


contract AccountRoles {
    bytes32 public constant ROLE_TRANSFER_ETHER = keccak256("transfer_ether");
    bytes32 public constant ROLE_TRANSFER_TOKEN = keccak256("transfer_token");
    bytes32 public constant ROLE_TRANSFER_OWNERSHIP = keccak256("transfer_ownership");	
    
    /**
    * @dev modifier to validate the roles 
    * @param roles to be validated
    * // reverts
    */
    modifier validAccountRoles(bytes32[] roles) {
        for (uint8 i = 0; i < roles.length; i++) {
            require(roles[i] == ROLE_TRANSFER_ETHER 
            || roles[i] == ROLE_TRANSFER_TOKEN
            || roles[i] == ROLE_TRANSFER_OWNERSHIP, "Invalid account role");
        }
        _;
    }
}


contract ISmartAccount {
    function transferOwnership(address _newOwner) public;
    function executeCall(address _destination, uint256 _value, uint256 _gasLimit, bytes _data) public;
}


contract UIExtension {
    string public uiExtensionVersion = "0.0.1";
	
    uint256 constant INTEGER = 1;
    uint256 constant FLOAT = 2;
    uint256 constant ADDRESS = 3;
    uint256 constant BOOL = 4;
    uint256 constant DATE = 5;
    uint256 constant STRING = 6;
    uint256 constant BYTE = 7;
    uint256 constant SMARTACCOUNTADDRESS = 8;
	
    struct Parameter {
        bool isArray;
        bool isOptional;
        uint256 typeReference;
        uint256 decimals; //only for INTEGER and FLOAT types (the value that will be multiplied, default 1, not defined or zero is equal 1 too)
        string description;
    }

    struct ConfigParameter {
        bool isEditable;
        Parameter parameter;
    }
    
    struct Setup {
        bytes4 createFunctionSignature; //function signature to create new configurable instance (view notes below)
        bytes4 updateFunctionSignature; //function signature to update existing configurable instance (view notes below)
        ConfigParameter[] parameters;
    }
    
    struct Action {
        bytes4 functionSignature;
        string description;
        Parameter[] parameters;
    }
    
    struct ViewData {
        bytes4 functionSignature;
        Parameter output;
    }
    
    struct BaseStorage {
        bytes4 functionSignature;
        uint256 parametersCount;
        string description;
    }
    
    struct Storage {
        BaseStorage baseData;
        mapping(uint256 => Parameter) parameters;
    }
    
    struct ConfigStorage {
        bytes4 createFunctionSignature;
        bytes4 updateFunctionSignature;
        uint256 parametersCount;
        mapping(uint256 => ConfigParameter) parameters;
    }
    
    ConfigStorage private setupParameters;
    Storage[] private viewDatas;
    Storage[] private actions;
    
    constructor() public {
        addConfigurableParameters(getSetupParameters());
        addViewDatas(getViewDatas());
        addActions(getActions());
    }
    
    function getName() pure external returns(string);
    function getDescription() pure external returns(string);
    function getSetupParameters() pure internal returns(Setup);
    function getActions() pure internal returns(Action[]);
    function getViewDatas() pure internal returns(ViewData[]);
    
    // IMPORTANT NOTES
    
    /* All view data functions must receive as arguments an address and a bytes32 (address,bytes32)
     * the arguments are smart account address and the respective identifier
     */
    
    /* Function to create new configurable instance must receive all setup parameters
     * using the same order defined in getSetupParameters() function 
     */
     
    /* Function to update existing configurable instance must receive 
     * respective identifier + all setup parameters (bytes32, [setup parameters])
     * setup parameters must use the same order defined in getSetupParameters() function 
     */
    
    /* Extension must always implement a function with the signature getSetup(address,bytes32)
     * the arguments are smart account address and respective identifier
     * the returns must be the value for all setup parameters 
     * using the same order defined in getSetupParameters() function 
     */ 
    
    function getSetupParametersCount() 
        view 
        public 
        returns(uint256) 
    {
        return setupParameters.parametersCount;
    }
    
    function getViewDatasCount() 
        view 
        public 
        returns(uint256) 
    {
        return viewDatas.length;
    }
    
    function getActionsCount() 
        view 
        public 
        returns(uint256) 
    {
        return actions.length;
    }
    
    function getSetupFunctions() 
        view 
        public 
        returns(bytes4, bytes4) 
    {
        return (setupParameters.createFunctionSignature, setupParameters.updateFunctionSignature);
    }
    
    function getSetupParametersByIndex(uint256 _index) 
        view 
        public 
        returns(bool, bool, bool, uint256, uint256, string) 
    {
        bool isArray;
        bool isOptional;
        uint256 typeReference; 
        uint256 decimals;
        string memory description;
        (isArray, isOptional, typeReference, decimals, description) = getParameter(setupParameters.parameters[_index].parameter);
        return (setupParameters.parameters[_index].isEditable, isArray, isOptional, typeReference, decimals, description);
    }
    
    function getViewDataByIndex(uint256 _index) 
        view 
        public 
        returns(bytes4, bool, bool, uint256, uint256, string) 
    {
        bool isArray;
        bool isOptional;
        uint256 typeReference;
        uint256 decimals;
        string memory description;
        (isArray, isOptional, typeReference, decimals, description) = getParameter(viewDatas[_index].parameters[0]);
        return (viewDatas[_index].baseData.functionSignature, isArray, isOptional, typeReference, decimals, description);
    }
    
    function getActionByIndex(uint256 _index) 
        view 
        public 
        returns(bytes4, string, uint256) 
    {
        return (actions[_index].baseData.functionSignature, actions[_index].baseData.description, actions[_index].baseData.parametersCount);
    }
    
    function getActionParametersCountByIndex(uint256 _index) 
        view 
        public 
        returns(uint256) 
    {
        return actions[_index].baseData.parametersCount;
    }
    
    function getActionParameterByIndexes(uint256 _actionIndex, uint256 _parameterIndex) 
        view 
        public 
        returns(bool, bool, uint256, uint256, string) 
    {
        return getParameter(actions[_actionIndex].parameters[_parameterIndex]);
    }

    function getParameter(Parameter _parameter)
        pure
        private
        returns(bool, bool, uint256, uint256, string)
    {
        return (_parameter.isArray, _parameter.isOptional, _parameter.typeReference, _parameter.decimals, _parameter.description);
    }
    
    function validateTypeReference(uint256 _typeReference, bool _isArray) 
        pure 
        private 
    {
        require (_typeReference == INTEGER
            || _typeReference == FLOAT 
            || _typeReference == ADDRESS 
            || _typeReference == BOOL
            || _typeReference == DATE
            || (_typeReference == SMARTACCOUNTADDRESS && !_isArray)
            || (_typeReference == STRING && !_isArray)
            || (_typeReference == BYTE && !_isArray));
    }
    
    function validateDescription(string _description) 
        pure 
        private 
    {
        bytes memory description = bytes(_description);
        require(description.length > 0);
    }
    
    function addConfigurableParameters(Setup _setup) 
        private 
    {
        require(_setup.createFunctionSignature != _setup.updateFunctionSignature);
        require(_setup.createFunctionSignature != "" && _setup.updateFunctionSignature != "");
            
        setupParameters.createFunctionSignature = _setup.createFunctionSignature;
        setupParameters.updateFunctionSignature = _setup.updateFunctionSignature;
        setupParameters.parametersCount = _setup.parameters.length;
        for(uint256 i = 0; i < _setup.parameters.length; i++) {
            validateTypeReference(_setup.parameters[i].parameter.typeReference, _setup.parameters[i].parameter.isArray);
            setupParameters.parameters[i] = _setup.parameters[i];
        }
    }
    
    function addActions(Action[] _actions) 
        private 
    {
        require(_actions.length > 0);
        
        for(uint256 i = 0; i < _actions.length; i++) {
            validateDescription(_actions[i].description);
            Storage memory s;
            s.baseData = setBaseStorage(_actions[i].functionSignature, _actions[i].parameters.length, _actions[i].description);
            actions.push(s);
            for(uint256 j = 0; j < _actions[i].parameters.length; j++) {
                validateTypeReference(_actions[i].parameters[j].typeReference, _actions[i].parameters[j].isArray);
                validateDescription(_actions[i].parameters[j].description);
                actions[i].parameters[j] = _actions[i].parameters[j];
            }
        }
    }
    
    function addViewDatas(ViewData[] _viewDatas) private {
        for(uint256 i = 0; i < _viewDatas.length; i++) {
            validateTypeReference(_viewDatas[i].output.typeReference, _viewDatas[i].output.isArray);
            validateDescription(_viewDatas[i].output.description);
            Storage memory s;
            s.baseData = setBaseStorage(_viewDatas[i].functionSignature, 1, "");
            viewDatas.push(s);
            viewDatas[i].parameters[0] = _viewDatas[i].output;
        }
    }
    
    function setBaseStorage(
        bytes4 _functionSignature, 
        uint256 _parametersCount, 
        string _description
    ) 
        private 
        pure 
        returns (BaseStorage) 
    {
        require(_functionSignature != "");
        BaseStorage memory s;
        s.functionSignature = _functionSignature;
        s.parametersCount = _parametersCount;
        s.description = _description;
        return s;
    }
}


contract ManagerExtension {
    string public managerExtensionVersion = "0.0.1";

    mapping(address => bytes32[]) private identifier; //all extensions should define the identifier, it is necessary because the smart account can add the extension more than once
    mapping(bytes32 => uint256) private indexes;
    
    event SetIdentifier(address sender, address smartAccount, bytes32 identifier);
      event RemoveIdentifier(address sender, address smartAccount, bytes32 identifier);
    
    // Options are ROLE_TRANSFER_ETHER, ROLE_TRANSFER_TOKEN and/or ROLE_TRANSFER_OWNERSHIP
    function getRoles() pure public returns(bytes32[]);
	
    function setIdentifier(address _smartAccount, bytes32 _identifier) internal {
        bool alreadyExist = false;
        for (uint256 i = 0; i < identifier[_smartAccount].length; ++i) {
            if (identifier[_smartAccount][i] == _identifier) {
                alreadyExist = true;
                break;
            }
        }
        if (!alreadyExist) {
            indexes[keccak256(abi.encodePacked(_smartAccount, _identifier))] = identifier[_smartAccount].push(_identifier) - 1;
            emit SetIdentifier(msg.sender, _smartAccount, _identifier);
        }
    }
    
    function removeIdentifier(address _smartAccount, bytes32 _identifier) internal {
        require(getIdentifiersCount(_smartAccount) > 0);
        uint256 index = indexes[keccak256(abi.encodePacked(_smartAccount, _identifier))];
        bytes32 indexReplacer = identifier[_smartAccount][identifier[_smartAccount].length - 1];
        identifier[_smartAccount][index] = indexReplacer;
        indexes[keccak256(abi.encodePacked(_smartAccount, indexReplacer))] = index;
        identifier[_smartAccount].length--;
        emit RemoveIdentifier(msg.sender, _smartAccount, _identifier);
    }
    
    function getIdentifiers(address _smartAccount) 
        view 
        public 
        returns(bytes32[]) 
    {
        return identifier[_smartAccount];
    }
    
    function getIdentifiersCount(address _smartAccount) 
        view 
        public 
        returns(uint256) 
    {
        return identifier[_smartAccount].length;
    }
    
    function getIdentifierByIndex(address _smartAccount, uint256 _index) view public returns(bytes32) {
        return identifier[_smartAccount][_index];
    }
    
    function transferTokenFrom(address _smartAccount, address _tokenAddress, address _to, uint256 _amount) internal {
        bytes memory data = abi.encodePacked(bytes4(keccak256("transfer(address,uint256)")), bytes32(_to), _amount);
        ISmartAccount(_smartAccount).executeCall(_tokenAddress, 0, 0, data);
    }
    
    function transferEtherFrom(address _smartAccount, address _to, uint256 _amount) internal {
        ISmartAccount(_smartAccount).executeCall(_to, _amount, 0, "");
    }
}


contract IExtension is UIExtension, ManagerExtension, AccountRoles {
}


//Example 1
//TODO: add comments and events
contract RecoveryFunds is IExtension {
    using SafeMath for uint256;
    
    struct Configuration {
        uint256 delayTime;
        uint256 numberOfConfirmations;
        address[] providers;
    }
    
    struct Data {
        address destination;
        uint256 start;
        address[] confirmedAddresses;
    }
    
    mapping(address => Configuration) private configuration;
    mapping(address => Data) private recoveryProcess;
    
    modifier isProvider(address _smartAccount) {
        bool provider = false;
        for (uint256 i = 0; i < configuration[_smartAccount].providers.length; ++i) {
            if (configuration[_smartAccount].providers[i] == msg.sender) {
                provider = true;
                break;
            }
        }
        require(provider);
        _;
    }
    
    function getName() pure external returns(string) {
        return "Recovery Funds";
    }
    
    function getDescription() pure external returns(string) {
        return "Define a list of providers to recover your funds from a lost smart account.";
    }
    
    function getSetupParameters() pure internal returns(Setup) {
        ConfigParameter[] memory parameters = new ConfigParameter[](3);
        parameters[0] = ConfigParameter(true, Parameter(false, false, INTEGER, 86400, "Time to disprove in days"));
        parameters[1] = ConfigParameter(true, Parameter(false, false, INTEGER, 1, "Number of confirmations"));
        parameters[2] = ConfigParameter(true, Parameter(true, false, ADDRESS, 0, "Providers addresses"));
        return Setup(bytes4(keccak256("createSetup(uint256,uint256,address[])")),
            bytes4(keccak256("updateSetup(bytes32,uint256,uint256,address[])")), parameters);
    }
    
    function getActions() pure internal returns(Action[]) {
        Parameter[] memory parameters1 = new Parameter[](2);
        parameters1[0] = Parameter(false, false, SMARTACCOUNTADDRESS, 0, "Smart account");
        parameters1[1] = Parameter(false, false, ADDRESS, 0, "Destination");
        Parameter[] memory parameters2 = new Parameter[](1);
        parameters2[0] = Parameter(false, false, SMARTACCOUNTADDRESS, 0, "Smart account");
        Action[] memory action = new Action[](5);
        action[0].description = "Start recovery process";
        action[0].parameters = parameters1;
        action[0].functionSignature = bytes4(keccak256("startRecovery(address,address)"));
        action[1].description = "Confirm recovery";
        action[1].parameters = parameters2;
        action[1].functionSignature = bytes4(keccak256("confirm(address)"));
        action[2].description = "Cancel recovery";
        action[2].parameters = parameters2;
        action[2].functionSignature = bytes4(keccak256("cancel(address)"));
        action[3].description = "Disprove recovery process";
        action[3].functionSignature = bytes4(keccak256("disprove()"));
        action[4].description = "Complete recovery";
        action[4].parameters = parameters2;
        action[4].functionSignature = bytes4(keccak256("complete(address)"));
        return action;
    }
    
    function getViewDatas() pure internal returns(ViewData[]) {
        ViewData[] memory viewData = new ViewData[](4);
        viewData[0].functionSignature = bytes4(keccak256("isStarted(address,bytes32)"));
        viewData[0].output = Parameter(false, false, BOOL, 0, "Recovery process is started");
        viewData[1].functionSignature = bytes4(keccak256("destinationAddress(address,bytes32)"));
        viewData[1].output = Parameter(false, true, ADDRESS, 0, "Destination address");
        viewData[2].functionSignature = bytes4(keccak256("getConfirmations(address,bytes32)"));
        viewData[2].output = Parameter(true, true, ADDRESS, 0, "Confirmations");
        viewData[3].functionSignature = bytes4(keccak256("timeToDisprove(address,bytes32)"));
        viewData[3].output = Parameter(false, true, INTEGER, 86400, "Time in seconds to disprove");
        return viewData;
    }
    
    function getRoles() pure public returns(bytes32[]) {
        bytes32[] memory roles = new bytes32[](1); 
        roles[0] = ROLE_TRANSFER_OWNERSHIP;
        return roles;
    }
    
    function createSetup(uint256 _delay,  uint256 _confirmations, address[] _providers) public {
        require(configuration[msg.sender].numberOfConfirmations == 0 || recoveryProcess[msg.sender].start == 0);
        require(_providers.length > 0);
        require(_confirmations > 0);
        require(_confirmations <= _providers.length);
        for(uint256 i = 0; i < _providers.length; ++i) {
            require(_providers[i] != address(0) && _providers[i] != msg.sender);
            for (uint256 j = 0; j < i; ++j) {
                require(_providers[j] != _providers[i]);
            }
        }
        configuration[msg.sender] = Configuration(_delay, _confirmations, _providers);
        setIdentifier(msg.sender, bytes32(0));
    }
    
    function updateSetup(bytes32, uint256 _delay,  uint256 _confirmations, address[] _providers) external {
        createSetup(_delay, _confirmations, _providers);
    }
        
    function getSetup(address _reference, bytes32) 
        view 
        external 
        returns (uint256, uint256, address[]) 
    {
        return (configuration[_reference].delayTime, 
            configuration[_reference].numberOfConfirmations, 
            configuration[_reference].providers);
    }

    function isStarted(address _reference, bytes32) view external returns(bool) {
        return recoveryProcess[_reference].start > 0;
    }

    function destinationAddress(address _reference, bytes32) view external returns(address) {
        return recoveryProcess[_reference].destination;
    }

    function getConfirmations(address _reference, bytes32) view external returns(address[]) {
        return recoveryProcess[_reference].confirmedAddresses;
    }
    
    function timeToDisprove(address _reference, bytes32) view external returns(uint256) {
        if (recoveryProcess[_reference].start == 0) {
            return 0;
        } else {
            uint256 timePassed = now.sub(recoveryProcess[_reference].start);
            return timePassed > configuration[_reference].delayTime ? 0 : 
                configuration[_reference].delayTime.sub(timePassed);
        }
    }
    
    function startRecovery(address _smartAccount, address _destination) isProvider(_smartAccount) external { 
        require(recoveryProcess[_smartAccount].start == 0);
        require(_destination != address(0));
        require(_destination != _smartAccount);
        address[] memory confirmed = new address[](1);
        confirmed[0] = msg.sender;
        recoveryProcess[_smartAccount] = Data(_destination, now, confirmed);
    }
    
    function confirm(address _smartAccount) isProvider(_smartAccount) external { 
        require(recoveryProcess[_smartAccount].start > 0);
        for (uint256 i = 0; i < recoveryProcess[_smartAccount].confirmedAddresses.length; ++i) {
            require(recoveryProcess[_smartAccount].confirmedAddresses[i] != msg.sender);
        }
        recoveryProcess[_smartAccount].confirmedAddresses.push(msg.sender);
    }
    
    function cancel(address _smartAccount) isProvider(_smartAccount) external {  
        require(recoveryProcess[_smartAccount].start > 0);
        bool canCancel = false;
        uint256 index;
        for (uint256 i = 0; i < recoveryProcess[_smartAccount].confirmedAddresses.length; ++i) {
            if (recoveryProcess[_smartAccount].confirmedAddresses[i] == msg.sender) {
                canCancel = true;
                index = i;
                break;
            }
        }
        require(canCancel);
        recoveryProcess[_smartAccount].confirmedAddresses[index] = 
            recoveryProcess[_smartAccount].confirmedAddresses[recoveryProcess[_smartAccount].confirmedAddresses.length - 1];
        recoveryProcess[_smartAccount].confirmedAddresses.length--;
    }
    
    function complete(address _smartAccount) external {  
        require(recoveryProcess[_smartAccount].start > 0);
        require(now.sub(recoveryProcess[_smartAccount].start) > configuration[_smartAccount].delayTime);
        ISmartAccount(_smartAccount).transferOwnership(recoveryProcess[_smartAccount].destination);
        configuration[_smartAccount] = Configuration(0, 0, new address[](0));
        recoveryProcess[_smartAccount] = Data(address(0), 0, new address[](0));
    }
    
    function disprove() external {
        require(recoveryProcess[msg.sender].start > 0);
        require(now.sub(recoveryProcess[msg.sender].start) <= configuration[msg.sender].delayTime);
        recoveryProcess[msg.sender] = Data(address(0), 0, new address[](0));
    }
}