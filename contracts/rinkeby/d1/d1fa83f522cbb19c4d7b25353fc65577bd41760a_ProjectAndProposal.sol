/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

pragma solidity ^0.8.0;

// import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


pragma solidity ^0.8.0;

// import "./IERC20.sol";
// import "./extensions/IERC20Metadata.sol";
// import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


pragma solidity 0.8.0;

contract Factory {

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    mapping(bytes32 => RoleData) private _roles;

    function getRoleAdmin(bytes32 role) private view returns (bytes32) {
        return _roles[role].adminRole;
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members[account];
    }

    function _msgSender() private view returns (address) {
        return msg.sender;
    }

    function _grantRole(bytes32 role, address account) private{
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _setupRole(bytes32 role, address account) private{
        _grantRole(role, account);
    }

    bytes32 public constant VALIDATORS = keccak256("validator");
    address[] private allValidatorsArray;
    mapping(address => bool) private validatorBoolean;
    
    function addValidators(address _ad) public {
        require(msg.sender == _ad,"please use the address of connected wallet");
        allValidatorsArray.push(_ad);
        validatorBoolean[_ad] = true;
        _setupRole(VALIDATORS, _ad);
    }

    function returnArray() public view returns(address[] memory){ 
        return allValidatorsArray;
    }

    function checkValidatorIsRegistered(address _ad) public view returns(bool condition){
        if(validatorBoolean[_ad] == true){
            return true;
        }else{
            return false;
        }
    }
}


pragma solidity ^0.8.0;

contract Founder{
    
    mapping(address => bool) private isFounder;
    address[] private pushFounders;

    function addFounder(address _ad) public{
        require(msg.sender == _ad,"Connect same wallet to add founder address");
        isFounder[_ad] = true;
        pushFounders.push(_ad);
    }

    function verifyFounder(address _ad) public view returns(bool condition){
        if(isFounder[_ad] == true){
            return true;
        }else{
            return false;
        }
    }

    function getAllFounderAddress() public view returns(address[] memory){
        return pushFounders;
    }    
}

/*
Here starts the ProjectAndProposal 
*/

contract ProjectAndProposal{

    uint private totalValueForProject;               // initial
    uint private totalDepositedStableCoinsInThePot;  // sub
    uint private TenPercentBalanceOfStableCoin;      // initial
    
    address[] private validatorWhoApproved;
    address[] private validatorWhoRejected;
    address[] private allValidators;

    bool private proposalCancelledRevertWithdrawlToInvestors;
  
// MAPPINGS: LINKING ID TO INITIAL AND SUBSEQUENT:
    mapping(bytes32 => address) private whitelistedTokens;
    // mapping(address => uint) public getInvestorsId;
    mapping(uint => address[]) private arrApprovedValidator;
    mapping(uint => address[]) private arrRejectedValidator;

// MAPPINGS: GETTING THE BALANCE DATA:
    mapping(address => mapping(uint => uint)) public subsequentBalanceOfFounder;
    mapping(address => mapping(uint => uint)) public subsequentBalanceOfInvestor;
    mapping(uint => mapping(address => uint)) public initialTenPercentOfInvestor;
    mapping(address => mapping(uint => uint)) public initialBalanceOfFounder;


// MAPPINGS: LINKING ID'S TO FOUNDER AND SUBSEQUENT PROPOSALS:
    mapping(uint => mapping(address => address)) public initialfounderId;
    mapping(uint => mapping(address => address)) public subsfounderId;
    mapping(uint => mapping(address => address)) public initialInvestorId;
    mapping(uint => mapping(address => address)) public subsInvestorId;

    mapping(uint => mapping(address => address)) public founderAndInvestorConnection;
    mapping(address => mapping(uint => uint)) public totalValueExpectedRespectiveToFounder;

    function returnFounderAndInvestorConnection(uint _initialId, address _founder, address _investor) public view returns(bool){
        bool status;
        if(founderAndInvestorConnection[_initialId][_founder] == _investor){
            status = true;
            return status;
        }else{
            revert("The connection is mismatch");
        }
    }

// MATCHING FOUNDER AND TOTAL VALUE FOR PROJECT:

/*
    mapping(address => uint) public 
*/

    struct founderLink{
        uint projectId;
        uint cycles;
        // uint projectExpectedValue;
    }  

    mapping(uint => founderLink) projectCycle;

    mapping(address => uint) public projectIdAndFounder; // This outputs project id, when correct address is passed.
    // mapping(uint => uint) public balanceOfEscrowBasedOnId;   // This records the balance according to projectid.
    mapping(uint => mapping(address => uint)) private es; // This records total balance that the escrow uses.

    function escrowBalanceOfStableCoins(uint _projectId, address _investor) public view returns(uint Balance){
        return es[_projectId][_investor];
    }

    function setFounderAndCycleForTheProject(address _founderSmartContractAd, address _founderAd, uint _projectId, uint _cycles) public{
        require(msg.sender == _founderAd,"The connected wallet and the founder is mismatching");    // Security level 1
        Founder f = Founder(_founderSmartContractAd);   // Instance from the founder smart contract.
        if(f.verifyFounder(_founderAd) == true){    // Verifying whether the founder is already registered in founder smart contract.
            projectIdAndFounder[_founderAd] = _projectId;   // Regular mapping
            projectCycle[_projectId].cycles = _cycles;  // dynamic
            getProjectCycles[_projectId] = _cycles; // static
            getProjectCurrentCycle[_projectId] =  projectCycle[_projectId].cycles;
            getProjectStatus[_projectId] = "On going";
        }else{
            revert("The address is not registered in the founders contract");
        }
    }

    // function returnFounderAndCycle(uint _projectId) public view returns(uint){
    //     return(projectCycle[_projectId].cycles);
    // }

    mapping(address => uint) private founderAndInitialId;
    mapping(address => uint) private founderAndSubsequentId;
   

    function returnFounderAndInitialId(address _ad, uint _initialId) public view returns(uint){
        require(founderAndInitialId[_ad] == _initialId, "The id is a mismatch");
        return founderAndInitialId[_ad];
    }

/* -------------------------------x
 FOUNDER ACTION: INITIAL ID SETUP:

 require(subs1[_projectId][_subsId]._investorSetup == _investor
   -------------------------------x
*/

    struct founderSettingInvestorToTheProposal{
        uint _initialId;    // founder + projectid must == initialid
        uint _amountForProposal;    // founder + _ initialid must == totalValue For project 
        address _investor;      // founder + initialid must == investor
        uint _initial10PercentOfInvestor;
    }

    struct initialAndInvestor{
        uint _initialId;
        address _investor;
    }

    mapping(address => mapping(uint => founderSettingInvestorToTheProposal)) founderLinkInvestorInitialProposal;
    mapping(uint => mapping(uint => founderSettingInvestorToTheProposal)) initialAndProjLinkInvestor;
    mapping(uint => mapping(address => initialAndInvestor[])) justInvestor;
    uint[] private ids;


    function setInitialId(address _founder,address _investor, uint _initialId, uint _projectId, uint _totalValProposal) public {
        require(msg.sender == _founder,"The connected wallet is not a founder wallet");
        require(projectIdAndFounder[_founder] == _projectId,"The founder address is not matched with project id");
        ids.push(_initialId);
        uint i;
        for(i = 0; i < ids.length-1; i++){
            if(ids[i] == _initialId){
                revert("The id is already taken, please use different id");
            }
        }

        initialAndInvestor memory iI;
        iI = initialAndInvestor(_initialId, _investor);
        justInvestor[_projectId][_founder].push(iI);

        founderLinkInvestorInitialProposal[_investor][_projectId]._initialId = _initialId;
        founderLinkInvestorInitialProposal[_investor][_initialId]._amountForProposal = _totalValProposal;  
        founderLinkInvestorInitialProposal[_founder][_initialId]._investor = _investor;   
     
        initialAndProjLinkInvestor[_initialId][_projectId]._investor = _investor;
        founderAndInitialId[_founder] = _initialId;
        getInitialProposalRequestedFund[_projectId][_initialId] = _totalValProposal;
    }

    function returnFounderInitialAndInvestor(address _founder,address _investor, uint _initialId, uint _projectId) public view returns(
        uint initialId, uint proposalValueForInvestor, address investorAddress, uint initial10PercentOfInvestor){
        return(
            founderLinkInvestorInitialProposal[_investor][_projectId]._initialId,
            founderLinkInvestorInitialProposal[_investor][_initialId]._amountForProposal,
            founderLinkInvestorInitialProposal[_founder][_initialId]._investor,
            founderLinkInvestorInitialProposal[_investor][_initialId]._initial10PercentOfInvestor
        );
    }

    function initial_prop_info(uint _projectId, uint initial_id, address _founder) public view returns (initialAndInvestor memory) {
        initialAndInvestor memory iI;
        if (justInvestor[_projectId][_founder].length > 0) {
            for (uint i = 0; i < justInvestor[_projectId][_founder].length; i++) {
                if (justInvestor[_projectId][_founder][i]._initialId == initial_id) {
                    iI = justInvestor[_projectId][_founder][i];
                }
            }
            return iI;
        } else {
            revert("there is no initial proposal");
        }
    }

/* -----------------------------------x
   FOUNDER ACTION: SUBSEQUENT ID SETUP:
   -----------------------------------x
*/
    uint[] private idsSub;

    struct getSubsequentData{
        uint subsequentId;
        uint subsequentBalance;
        address[] investors;
    }

    mapping (uint => mapping(address => getSubsequentData[])) SUBS; // struct used array
    address[] private Subinvestors;
    mapping(uint => mapping(uint => uint)) private subsCycleBalance;

    function setSubsequentId(address _founder, uint _subsId, uint _projectId) public {
        require(msg.sender == _founder,"you are not founder");
        idsSub.push(_subsId);
        uint i;
        for(i = 0; i < idsSub.length-1; i++){
            if(idsSub[i] == _subsId){
                revert("The id is already taken, please use different id");
            }
        }
        subsCycleBalance[_projectId][_subsId] = es[_projectId][_founder] / projectCycle[_projectId].cycles;
        Subinvestors = AI[_projectId].allInvestors;

        getSubsequentData memory s;
        s = getSubsequentData(_subsId, subsCycleBalance[_projectId][_subsId], Subinvestors);
        SUBS[_projectId][_founder].push(s);
        isSubsequentCreatedOrNot[_projectId][_subsId] = true;
        getSubsequentProposalFund[_projectId][_subsId] = subsCycleBalance[_projectId][_subsId];
    }

    function subsequent_prop_info(uint proj_id, uint subs_id, address founder) public view returns (getSubsequentData memory) {
        getSubsequentData memory s;
        if (SUBS[proj_id][founder].length > 0) {
            for (uint i = 0; i < SUBS[proj_id][founder].length; i++) {
                if (SUBS[proj_id][founder][i].subsequentId == subs_id) {
                    s = SUBS[proj_id][founder][i];
                }
            }
            return s;
        } else {
            revert("there is no initial proposal");
        }
    }

/*
-----------------------x
Validation Function:
-----------------------x
1. Validation can be done in bulk understanding the addresses in the array and then making the setup.
*/
    mapping(uint => mapping(uint => address[])) public approvals;
    mapping(uint => mapping(uint => address[])) public rejections;
    mapping(uint => mapping(uint => string)) private subStatus;
    mapping(uint => mapping(uint => bool)) isSubsequentCreatedOrNot;


    mapping(uint => mapping(uint => uint)) private withdrawlSetup;
    bool public projectRejectionStatus;
    // mapping(uint => uint) private getRejectedSubsequentProposalsCounts;


    // function Validate(bool _choice, address _validator, address _contractad, uint _subsId, uint _projectId) public returns (bool voted){

    //     Factory f = Factory(_contractad);
    //     require(f.checkValidatorIsRegistered(_validator) == true,"The address is not registered as validators");
    //     require(msg.sender == _validator,"The connected wallet is not a validator address");
    //     require(isSubsequentCreatedOrNot[_projectId][_subsId] == true,"The subsequent is not yet created");
    //     if(_choice == true){
    //         approvals[_projectId][_subsId].push(_validator);
    //     }
    //     if(_choice == false){
    //         rejections[_projectId][_subsId].push(_validator);
    //     }
    //     if(approvals[_projectId][_subsId].length >= 3){
    //         subStatus[_projectId][_subsId] = "Approved";
    //     }
    //     if(rejections[_projectId][_subsId].length >= 3){
    //         subStatus[_projectId][_subsId] = "Rejected";
    //     }
    //     if(rejections[_projectId][_subsId].length == 3){
    //         getRejectedSubsequentProposalsCount[_projectId] += 1;
    //     }
        
        
    //     else if(getRejectedSubsequentProposalsCounts[_projectId] >= 3){
    //         withdrawlSetup[_projectId][_subsId] = 3;
    //     }   
    //     return true;
	// }


    function Validate(bool _choice, address _validator, address _contractad, uint _subsId, uint _projectId) public returns (bool voted){
    Factory f = Factory(_contractad);
    require(f.checkValidatorIsRegistered(_validator) == true,"The address is not registered as validators");
    require(msg.sender == _validator,"The connected wallet is not a validator address");
    require(isSubsequentCreatedOrNot[_projectId][_subsId] == true,"The subsequent is not yet created");
    if(_choice == true){
        approvals[_projectId][_subsId].push(_validator);
    } else if(_choice == false){
        rejections[_projectId][_subsId].push(_validator);
    }
    if(approvals[_projectId][_subsId].length >= 3){
        subStatus[_projectId][_subsId] = "Approved";
    } else if (rejections[_projectId][_subsId].length >= 3){
        subStatus[_projectId][_subsId] = "Rejected";
        if(rejections[_projectId][_subsId].length == 3) {
            getRejectedSubsequentProposalsCounts[_projectId] += 1;
        }
    }
    if(getRejectedSubsequentProposalsCounts[_projectId] >= 3){
        // withdrawlSetup[_projectId][_subsId] = 3;
        getProjectStatus[_projectId] = "Rejected";
    }
    return true;
}


    function getSubsequentStatusAfterValidation(uint _projectId, uint _subsId) public view returns(string memory statusOfProjectAndSubsequent){
        return subStatus[_projectId][_subsId];  // This can be used in the withdraw function 
    }

    function getWhitelistedTokenAddresses(bytes32 token) external view returns(address) {
        return whitelistedTokens[token];
    }


    // MAPPINGS-NEW: GETTING THE BALANCE DATA FOR INITIAL DATA:
    mapping(uint => mapping(address => uint)) public initialNinentyInvestor;
    mapping(address => mapping(uint => uint)) public initialNinentyFounder;


    struct allInvestorBool{
        address[] allInvestors;
        mapping(address => bool) validator;
        bool _state;
        address _investor;
    }

    mapping(uint => allInvestorBool) AI;
    mapping(bool => allInvestorBool) AIBOOL;
    mapping(uint => mapping(uint => address)) private projectSubsAndInvestor;

    address[] private ALLinvestors;



    // INVESTOR DEPOSIT:
    function depositStableTokens(address _investor, address _founder, uint256 _amount, bytes32 symbol, address tokenAddress, uint _initialId, uint _projectId) external {
        require(msg.sender == _investor,"The connected wallet is not matching");           
        require(_amount == founderLinkInvestorInitialProposal[_investor][_initialId]._amountForProposal,"The amount is a mismatching or id's are mismatching");
        require(initialAndProjLinkInvestor[_initialId][_projectId]._investor == _investor,"The investor is not linked to the founder and initialId");
            
        whitelistedTokens[symbol] = tokenAddress;            
        ERC20(whitelistedTokens[symbol]).transferFrom(_investor, address(this), _amount);
        initialInvestorId[_projectId][_investor] = msg.sender;

        AI[_projectId].allInvestors.push(_investor);
        ALLinvestors.push(_investor);

        initialNinentyInvestor[_projectId][_investor] = _amount;
        getProjectEscrowBalance[_projectId][_founder] += _amount;
        getInvestorInvestedBalance[_projectId][_investor] += _amount;
        getInvestorCurrentBalance[_projectId][_investor] += _amount;

        uint sendOnly10Percent = _amount * 10/100;
        initialTenPercentOfInvestor[_projectId][_investor] += sendOnly10Percent;
        initialNinentyInvestor[_projectId][_investor] -= initialTenPercentOfInvestor[_projectId][_investor];
        founderLinkInvestorInitialProposal[_investor][_initialId]._initial10PercentOfInvestor = initialTenPercentOfInvestor[_projectId][_investor]; // This reads 10% of investor
        es[_projectId][_founder] += initialNinentyInvestor[_projectId][_investor]; // This reads total 90% balance of different investors
        getTotalProjectValue[_projectId] = es[_projectId][_founder];
    }

    function returnAllInvestors(uint _projectId) public view returns(address[] memory){
        return(AI[_projectId].allInvestors);
    }

    function TOTALBALANCE(address _founder, uint _projectId) public view returns(uint escrowBalance){
        return es[_projectId][_founder];
    }     


   /*----------------------------x
    WithdrawStableCoin by Founder:
    -----------------------------x
   */

    function withdrawSubsequentStableCoins(uint subs_Id, address _founder, bytes32 symbol, uint _projectId) external returns (bool withdrawStatus){
    
        require(msg.sender == _founder,"The connected wallet is not a founder wallet"); 
        if(getRejectedSubsequentProposalsCounts[_projectId] >= 3){
            revert("The project is closed, due to three subsequence validation failure");
        }
        if(approvals[_projectId][subs_Id].length >= 3){
            uint i;
            for(i = 0; i < justInvestor[_projectId][_founder].length; i++){  
                address investor = justInvestor[_projectId][_founder][i]._investor; 
                uint Investorbalance = initialNinentyInvestor[_projectId][investor];
                uint escrowBalance = es[_projectId][_founder];
                uint share = (Investorbalance * subsCycleBalance[_projectId][subs_Id]) / escrowBalance;
                initialNinentyInvestor[_projectId][investor] -= share;
                getInvestorCurrentBalance[_projectId][investor] -= share;
            }
            es[_projectId][_founder] -= subsCycleBalance[_projectId][subs_Id];
            ERC20(whitelistedTokens[symbol]).transfer(msg.sender, subsCycleBalance[_projectId][subs_Id]);
            getTotalReleasedFundsToFounderFromEscrow[_projectId][_founder] += subsCycleBalance[_projectId][subs_Id];
            projectCycle[_projectId].cycles -= 1;   // dynamic
            getProjectCurrentCycle[_projectId] = projectCycle[_projectId].cycles;
            getTotalProjectValue[_projectId] = es[_projectId][_founder];
            if(projectCycle[_projectId].cycles <= 0){
                getProjectStatus[_projectId] = "Completed";
            }
            getTheSubsequentProposalWithdrawalStatus[_projectId][subs_Id] = true;
            return true;
        }else{
            revert("The withdrawl is not possible by the founder");
        }          
    }

    // INVESTOR CAN WITHDRAW FOUNDER SUBSEQUENT BALANCE:

    // function withdrawAllFounderTokenFromThePool(address _founder, address _investor, uint256 amount, bytes32 symbol, uint _subsId, uint _initialId) external  returns(bool condition) {
    //     bool status = false;
    //     require(arrApprovedValidator[_subsId].length >= 3,"maximum validators has not voted yet");
    //     if(arrApprovedValidator[_subsId].length >= 3){
    //         status = true;
    //     }
    //     if(arrRejectedValidator[_subsId].length >= 3){
    //         revert("validation is rejected");
    //     }
    //     if(subsInvestorId[_subsId][_investor] == msg.sender){
    //         initialNinentyFounder[_founder][_initialId] = subsequentBalanceOfFounder[_founder][_subsId];
    //         subsequentBalanceOfFounder[_founder][_subsId] -= amount;
    //         ERC20(whitelistedTokens[symbol]).transfer(msg.sender, amount);
    //         return status;
    //     }
    // }

    function whoApprovedSubsequentProposalBasedOnId(uint256 subs_id) public view returns (address[] memory) {
        return arrApprovedValidator[subs_id];
    }

    function whoRejectedSubsequentProposalBasedOnId(uint256 subs_id) public view returns (address[] memory) {
        return arrRejectedValidator[subs_id];
    }

    // INVESTOR WITHDRAW TOKENS WHEN 3 SUBSEQUENT PROPOSALS HAVE FAILED
    function withdrawTokensByInvestor(address _investor, bytes32 symbol, uint _subsId, uint _projectId) external  {
        require(msg.sender == _investor,"The connected wallet is not investor wallet");
        require(initialInvestorId[_projectId][_investor] == msg.sender,"investor address is mismatch with subsequent id");
        if(withdrawlSetup[_projectId][_subsId] >= 3){
            ERC20(whitelistedTokens[symbol]).transfer(msg.sender, initialNinentyInvestor[_projectId][_investor]);
            initialNinentyInvestor[_projectId][_investor] = 0;
            projectRejectionStatus = true;
        }
    } 

    // FOUNDER WITHDRAW 10% TOKENS:
    function Withdraw10PercentOfStableCoin(address _founderSmartContractAd, address _founder, address _investor, bytes32 symbol, uint _projectId) public  {
        require(msg.sender == _founder,"The connected wallet is not founder wallet");
        Founder f = Founder(_founderSmartContractAd);   // Instance from the founder smart contract.
        if(f.verifyFounder(_founder) == true){
            ERC20(whitelistedTokens[symbol]).transfer(msg.sender, initialTenPercentOfInvestor[_projectId][_investor]);
            getInvestorCurrentBalance[_projectId][_investor] -= initialTenPercentOfInvestor[_projectId][_investor];
            getTotalReleasedFundsToFounderFromEscrow[_projectId][_founder] += initialTenPercentOfInvestor[_projectId][_investor];
            getTheTenpercentWithdrawalStatus[_projectId][_investor] = true;
            initialTenPercentOfInvestor[_projectId][_investor] = 0;
        }else{
            revert("The founder address is not registered yet");
        }
    }

    // INVESTOR WITHDRAW 10% TOKENS:

    // function Withdraw10PercentOfFounderToken(address _founder, address _investor, bytes32 symbol, uint _initialId) public  {
    //     require(founderAndInvestorConnection[_initialId][_founder] == _investor && _investor == msg.sender, "investor wallet is mismatching with founder project");
    //     if(initialInvestorId[_initialId][_investor] == msg.sender){
    //         // subsequentBalanceOfFounder[_founder][_subsId] -= initialBalanceOfFounder[_founder][_initialId];    
    //         ERC20(whitelistedTokens[symbol]).transfer(msg.sender, initialBalanceOfFounder[_founder][_initialId]);
    //         initialBalanceOfFounder[_founder][_initialId] = 0;
    //     }else{
    //         revert("The connected wallet and the project id is mismatch therefore initial withdrawl is suspended");
    //     }
    // }

    /*----------------------------------------------x
    Direct Deposit By Investor Once Project is Over:
    ------------------------------------------------x
    */

    // remove amount, remove tokenAddress, add if condition to check withdrawl status, create a mpping to hold balance
    // mapping(uint => mapping(address => uint)) private investorDirectDeposit;
    // mapping(uint => uint) private totalDirectDepositStatic;
    // mapping(uint => uint) private totalDirectDepositDynamic;
    // mapping(uint => mapping(address => uint)) private totalWithdrawnDirectDipositedBalance;
  

    // function DirectDepositTokens(address _investor, bytes32 symbol, uint _subsId, uint _projectId) external {
    //     require(msg.sender == _investor,"The connected wallet is not matching");
    //     require(initialInvestorId[_projectId][_investor] == msg.sender,"investor address is mismatch with subsequent id");
    //     require(initialNinentyInvestor[_projectId][_investor] > 0,"There is no amount in the investor balance");
    //     if(withdrawlSetup[_projectId][_subsId] >= 3){
    //         ERC20(whitelistedTokens[symbol]).transferFrom(_investor, address(this), initialNinentyInvestor[_projectId][_investor]);
    //         investorDirectDeposit[_projectId][_investor] = initialNinentyInvestor[_projectId][_investor];
    //         totalDirectDepositStatic[_projectId] += investorDirectDeposit[_projectId][_investor];
    //         totalDirectDepositDynamic[_projectId] += investorDirectDeposit[_projectId][_investor];
    //     }else{
    //          revert("The project is still live or direct deposit has not been made yet");
    //     }
    // }

// Founder 
    // function withdrawDirectDepositStableTokens(address _founder, address _investor, bytes32 _symbol, uint _projectId, uint _subsId) external{
    //     require(msg.sender == _founder,"The connected wallet is not matching");
    //     if(withdrawlSetup[_projectId][_subsId] >= 3){
    //         ERC20(whitelistedTokens[_symbol]).transferFrom(address(this), _founder, investorDirectDeposit[_projectId][_investor]);
    //         totalWithdrawnDirectDipositedBalance[_projectId][_founder] += investorDirectDeposit[_projectId][_investor];
    //         totalDirectDepositDynamic[_projectId] -= investorDirectDeposit[_projectId][_investor];
    //         investorDirectDeposit[_projectId][_investor] = 0;
            
    //     }else{
    //         revert("The project is still live or direct deposit has not been made yet");
    //     }
    // }

    // function _getDirectDepositBalance(uint _projectId, address _investor) public view returns(uint){
    //     return investorDirectDeposit[_projectId][_investor];
    // }

    // function _totalDirectDepositStatic(uint _projectId) public view returns(uint){
    //     return totalDirectDepositStatic[_projectId];
    // }

    // function _totalDirectDepositDynamic(uint _projectId) public view returns(uint){
    //     return totalDirectDepositDynamic[_projectId];
    // }

    // function _totalWithdrawnDirectDipositedBalance(uint _projectId, address _founder) public view returns(uint){
    //     return totalWithdrawnDirectDipositedBalance[_projectId][_founder];
    // }

/*-----------------------------x
    Expected all read functions:
  -----------------------------x  
*/

    // 1. getProjectEscrowBalance - project_id, founder  .Total Balance of escrow (static)

    mapping(uint => mapping(address => uint)) public getProjectEscrowBalance;   // all balance of investor deposits in project, both 10% and 90% combined.

    function _getProjectEscrowBalance(uint _projectId, address _founder) public view returns(uint){
        return getProjectEscrowBalance[_projectId][_founder];
    }

    // 2. getInvestorInvestedBalance - project_id, founder    // Same Total Investors investment static in the project.

    mapping(uint => mapping(address => uint)) public getInvestorInvestedBalance;

    function _getInvestorInvestedBalance(uint _projectId, address _investor) public view returns(uint){
        return getInvestorInvestedBalance[_projectId][_investor];
    }

    // 3. getInvestorCurrentBalance - project_id, founder     // Individual investor balance (dynamic)
    // used in Deposit stable, 10% withdraw and 90% withdraw. 

    mapping(uint => mapping(address => uint)) public getInvestorCurrentBalance;

    function _getInvestorCurrentBalance(uint _projectId, address _investor) public view returns(uint){
        return getInvestorCurrentBalance[_projectId][_investor];
    }

    // 4. getTotalReleasedFundsToFounderFromEscrow - project_id, founder      // fund taken by founder from investors- static
    // used in 10% withdraw and 90% withdraw. 
    mapping(uint => mapping(address => uint)) public getTotalReleasedFundsToFounderFromEscrow;

    function _getTotalReleasedFundsToFounderFromEscrow(uint _projectId, address _founder) public view returns(uint){
        return getTotalReleasedFundsToFounderFromEscrow[_projectId][_founder];
    }

    // 5. getInitialProposalRequestedFund - project_id, initial_prop_id      // how much founder is requested while intial prop

    mapping(uint => mapping(uint => uint)) public getInitialProposalRequestedFund;

    function _getInitialProposalRequestedFund(uint _projectId, uint _initialId) public view returns(uint){
        return getInitialProposalRequestedFund[_projectId][_initialId];
    }


    // 6. getSubsequentProposalFund - project_id, subsequent_prop_id          // subsequent balance

    mapping(uint => mapping(uint => uint)) public getSubsequentProposalFund;

    function _getSubsequentProposalFund(uint _projectId, uint _subsId) public view returns(uint){
        return getSubsequentProposalFund[_projectId][_subsId];
    }

    // 7. getProjectCycles - project_id             // no of cycle (static)

    mapping(uint => uint) public getProjectCycles;

    function _getProjectCycles(uint _projectId) public view returns(uint){
        return getProjectCycles[_projectId];
    }

    // 8. getProjectCurrentCycle - project_id       // no of cycle (dynamic)
    mapping(uint => uint) public getProjectCurrentCycle;

    function _getProjectCurrentCycle(uint _projectId) public view returns(uint){
        return getProjectCurrentCycle[_projectId];
    }

    // 9. getSubsequentProposalStatus - project_id, subsequent_prop_id        // subsequentProposal Live or not 

    mapping(uint => mapping(uint => string)) public getSubsequentProposalStatus;

    function _getSubsequentProposalStatus(uint _projectId, uint _subsId) public view returns(string memory){
            return subStatus[_projectId][_subsId];
    }

    // 10. getRejectedSubsequentProposalsCount - project_id         // how many times a subsequent have been rejected proj

    mapping(uint => uint) public getRejectedSubsequentProposalsCounts;

    function _getRejectedSubsequentProposalsCount(uint _projectId) public view returns(uint){
        return getRejectedSubsequentProposalsCounts[_projectId];
    }

    // 11. getProjectStatus - project_id                            // project live or not
    mapping(uint => string) public getProjectStatus;

    function _getProjectStatus(uint _projectId) public view returns(string memory){
        return getProjectStatus[_projectId];
    }

    // 12. getWhoValidatedTheSubsequentProposal - project_id, subsequent_prop_id   // validators list - approved
    // mapping name approvals;

    function _approvedValidators(uint _projectId, uint _subsId) public view returns(address[] memory){
        return  approvals[_projectId][_subsId];
    }

    // 13. getWhoRejectedSubsequentProposal - project_id, subsequent_prop_id       // validators list - rejected
    // mapping name rejections;

    function _rejectedValidators(uint _projectId, uint _subsId) public view returns(address[] memory){
        return  rejections[_projectId][_subsId];
    }

    // 14. getTotalProjectValue - project_id                                       // Total Balance of escrow (dynamic)
    mapping(uint => uint) public getTotalProjectValue;

    function _getProjectCurrentEscrowBalance(uint _projectId) public view returns(uint){
        return getTotalProjectValue[_projectId];
    }

    // 15. getTheTenpercentWithdrawalStatus - project_id, initial_prop_id // stable tokens: whether withdrawn or not.
    mapping(uint => mapping(address => bool)) public getTheTenpercentWithdrawalStatus;

    function _getTheTenpercentWithdrawalStatus(uint _projectId, address _investor) public view returns(bool){
        return getTheTenpercentWithdrawalStatus[_projectId][_investor];
    }

    // 16. getTheSubsequentProposalWithdrawalStatus - project_id, subsequent_prop_id // statble tokens: whether withdrawn or not. If withdrawn, how much (edited) 
    mapping(uint => mapping(uint => bool)) public getTheSubsequentProposalWithdrawalStatus;

    function _getTheSubsequentProposalWithdrawalStatus(uint _projectId, uint _subsId) public view returns(bool){
        return getTheSubsequentProposalWithdrawalStatus[_projectId][_subsId];
    }

    function _checkTenPecentOfStableToken(uint _projectId, address _investor) public view returns(uint){
        return initialTenPercentOfInvestor[_projectId][_investor];
    }

}

pragma solidity 0.8.0;

contract Vesting{

/*
    Vesting Smart Contract:
        a. depositFounderTokens(proj_id, vest_id, investor, token_no, tge_date_in_seconds, tge_percent, vesting_start_date, no_of_vesting_months)
        uint projId;
        uint vestingID;
        amount = no of tokens;
        uint tgeDate (keep this record in seconds)
        vesting start data = tgeData + vestingStart Date in seconds
        no of vestingMonths a simple uint.

        1. Founder is linking everything with investor address and vesting id, so make sure this condition check is there at first line

        whitelistedTokens[_symbol] = _tokenAddress;
        ERC20(whitelistedTokens[_symbol]).transferFrom(_founder, address(this), _amount);
*/  

    mapping(bytes32 => address) private whitelistedTokens;

    struct vestingSchedule{
        mapping(uint => mapping(address => uint)) depositsOfFounderTokensToInvestor;   // 1 vestingId, address(Investor) = amount (total by founder)
        mapping(uint => mapping(address => uint)) depositsOfFounderCurrentTokensToInvestor;
        mapping(uint => mapping(uint => address)) investorLinkProjectAndVesting;    // projId, vestingId, address(Investor)
        mapping(uint => mapping(address => uint)) tgeDate;                          // vestId, investor = date
        mapping(uint => mapping(address => uint)) tgePercentage;                       // vestingId, investor, storeDate (unix)
        mapping(uint => mapping(address => uint)) vestingStartDate;                 // vestingId, investor, vestingStarDate (unix)
        mapping(uint => mapping(address => uint)) vestingMonths;                    // vestingId, investor, vestingMonths (plain days)
        mapping(uint => mapping(address => uint)) tgeFund;                          // vestId, investor - tge percentage amt
        mapping(uint => mapping(address => uint)) remainingFundForInstallments;     // vestId, investor = remaining of tge
        mapping(uint => mapping(address => uint)) installmentAmount;                // vestId, investor = 800/24 =  
    }

    struct installment{
        mapping(uint => uint) date; // index => date 
        mapping(uint => bool) status; 
        mapping(uint => uint) fund;
    }

    mapping(address => vestingSchedule) vs;       // vestid -> investor -> installments[date: , fund]
    mapping(uint =>mapping(address => installment)) vestingDues;    // vestId => investorAd => installment

    // function getWhitelistedTokenAddresses(bytes32 token) external view returns(address) {
    //     return whitelistedTokens[token];
    // }

    mapping(uint => mapping(address => uint)) private investorWithdrawBalance;

    function whitelistToken(bytes32 _symbol, address _tokenAddress) public returns(address){
        return whitelistedTokens[_symbol] = _tokenAddress;
    }

// Method: LINEAR
    function depositFounderLinearTokens(address _founder, address _founderSmartContractAd, bytes32 _symbol, uint _vestId, uint _amount, address _investor, uint _tgeDate, uint _tgePercent, uint _vestingStartDate, uint _vestingMonths) public {
        require(msg.sender == _founder,"The connected wallet is not founder wallet");
        Founder f = Founder(_founderSmartContractAd);   // Instance from the founder smart contract. 
        uint _tgePercentage;
        uint _founderDeposit;
        if(f.verifyFounder(_founder) == true){
            vs[_founder].depositsOfFounderTokensToInvestor[_vestId][_investor] = _amount; // 1 deposit
            _founderDeposit = vs[_founder].depositsOfFounderTokensToInvestor[_vestId][_investor];
            vs[_founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] = _amount;
            vs[_founder].tgeDate[_vestId][_investor] = _tgeDate; // 3 unix
            vs[_founder].tgePercentage[_vestId][_investor] = _tgePercent;
            _tgePercentage = vs[_founder].tgePercentage[_vestId][_investor];
            vs[_founder].vestingStartDate[_vestId][_investor] = _vestingStartDate; // 4 unix
            vs[_founder].vestingMonths[_vestId][_investor] = _vestingMonths; // 5 plain
            /* TGEFUND:
            1. This gives use the balance of tge fund available for the investor to withdraw.
            2. makes this available for the investor to withdraw after "_tgeDate".
            */
            vs[_founder].tgeFund[_vestId][_investor] = (_tgePercentage * _founderDeposit) / 100;
            /*REMAININGFUND:
            1. This will divide the fund based on installments.
            */
            vs[_founder].remainingFundForInstallments[_vestId][_investor] = _amount - vs[_founder].tgeFund[_vestId][_investor];
            vs[_founder].installmentAmount[_vestId][_investor] = vs[_founder].remainingFundForInstallments[_vestId][_investor] / _vestingMonths;
            // whitelistedTokens[_symbol] = _tokenAddress;
            ERC20(whitelistedTokens[_symbol]).transferFrom(_founder, address(this), _amount);
            for(uint i = 1; i <= _vestingMonths; i++){
                vestingDues[_vestId][_investor].date[i] = _vestingStartDate + (i * 30 days);
                vestingDues[_vestId][_investor].status[i] = false;
                vestingDues[_vestId][_investor].fund[i] =  vs[_founder].installmentAmount[_vestId][_investor];
            }
        }else{
            revert("The founder is not registered yet");
        }
    }

    function withdrawTGEFund(address _investor,address _founder, uint _vestId, bytes32 _symbol) public {
        require(msg.sender == _investor,"The connected wallet is not investor wallet");
        if(block.timestamp >= vs[_founder].tgeDate[_vestId][_investor]){
            ERC20(whitelistedTokens[_symbol]).transfer(msg.sender, vs[_founder].tgeFund[_vestId][_investor]);
            vs[_founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] -= vs[_founder].tgeFund[_vestId][_investor];
            investorWithdrawBalance[_vestId][_investor] += vs[_founder].tgeFund[_vestId][_investor];
        }else{
            revert("The transaction has failed or error");
        }
    }

    function withdrawInstallmentAmount(address _investor,address _founder, uint _vestId, uint _index, bytes32 _symbol) public {
        require(msg.sender == _investor,"The connected wallet is not investor wallet");
        uint amt;
        if(block.timestamp >= vestingDues[_vestId][_investor].date[_index]){
            if(vestingDues[_vestId][_investor].status[_index] != true){
                amt = vestingDues[_vestId][_investor].fund[_index];
                ERC20(whitelistedTokens[_symbol]).transferFrom(_founder, address(this), amt);   // update this line
                vestingDues[_vestId][_investor].status[_index] = true;
                vs[_founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] -= amt;
                investorWithdrawBalance[_vestId][_investor] += amt;
            }else{
                revert("Already Withdrawn");
            }
        }else{
            revert("Installment is not unlocked yet");  
        }
    }

    /*
    --------------X
    READ FUNCTIONS:
    --------------X
    */
    
    function currentEscrowBalanceOfInvestor(address _founder, uint _vestId, address _investor) public view returns(uint){
        return vs[_founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor];
    }

    function investorTGEFund(address _founder, uint _vestId, address _investor) public view returns(uint){
        return vs[_founder].tgeFund[_vestId][_investor];
    }

    function investorInstallmentFund(uint _vestId, uint _index, address _investor) public view returns(uint){
        return vestingDues[_vestId][_investor].fund[_index];
    }

    function investorWithdrawnFund(address _investor, uint _vestId) public view returns(uint){
        return investorWithdrawBalance[_vestId][_investor];
    }


    /*
    Method: NON-LINEAR:
    */
    struct due{
        uint date;
        uint fund;
    }

    function setNonLinearInstallments(address _founder, address _founderSmartContractAd, uint _vestId, address _investor, due[] memory _dues) public {
        require(msg.sender == _founder,"The connected wallet is not founder wallet");
        Founder f = Founder(_founderSmartContractAd);   // Instance from the founder smart contract. 
        if(f.verifyFounder(_founder) == true){
            for(uint i = 1; i <= _dues.length; i++){
                vestingDues[_vestId][_investor].date[i] = _dues[i].date;
                vestingDues[_vestId][_investor].status[i] = false;
                vestingDues[_vestId][_investor].fund[i] =  _dues[i].fund;
            }
        }else{
            revert("The founder is not registered yet");
        }
    }

    function depositFounderNonLinearTokens(address _founder, address _founderSmartContractAd, bytes32 _symbol, uint _vestId, uint _amount, address _investor, uint _tgeDate, uint _tgePercent) public {
        require(msg.sender == _founder,"The connected wallet is not founder wallet");
        Founder f = Founder(_founderSmartContractAd);   // Instance from the founder smart contract. 
        uint _tgePercentage;
        uint _founderDeposit;
        if(f.verifyFounder(_founder) == true){
            vs[_founder].depositsOfFounderTokensToInvestor[_vestId][_investor] = _amount; // 1 deposit
            _founderDeposit = vs[_founder].depositsOfFounderTokensToInvestor[_vestId][_investor];
            vs[_founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] = _amount;
            vs[_founder].tgeDate[_vestId][_investor] = _tgeDate; // 3 unix
            vs[_founder].tgePercentage[_vestId][_investor] = _tgePercent;
            _tgePercentage = vs[_founder].tgePercentage[_vestId][_investor];
            /* TGEFUND:
            1. This gives use the balance of tge fund available for the investor to withdraw.
            2. makes this available for the investor to withdraw after "_tgeDate".
            */
            vs[_founder].tgeFund[_vestId][_investor] = (_tgePercentage * _founderDeposit) / 100;
            /*REMAININGFUND:
            1. This will divide the fund based on installments.
            */
            vs[_founder].remainingFundForInstallments[_vestId][_investor] = _amount - vs[_founder].tgeFund[_vestId][_investor];
            ERC20(whitelistedTokens[_symbol]).transferFrom(_founder, address(this), _amount);
        }else{
            revert("The founder is not registered yet");
        }
    }

}