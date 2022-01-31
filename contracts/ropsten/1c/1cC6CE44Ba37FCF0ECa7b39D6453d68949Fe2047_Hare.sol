////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//////////////////////   ///////////////////////////////////////////////////////
/////////////////////       ////////////////////////////////////////////////////
//////////////////////        //////////////////////       /////////////////////
///////////////////////        ///////////////////         /////////////////////
/////////////////////////       /////////////////         //////////////////////
///////////////////////////      ///////////////       .////////////////////////
////////////////////////////      /////////////       //////////////////////////
/////////////////////////////     /////////////     ////////////////////////////
//////////////////////////////     ///////////     /////////////////////////////
///////////////////////////////    ///////////    //////////////////////////////
///////////////////////////////    ///////////    //////////////////////////////
///////////////////////////////    ///////////    //////////////////////////////
///////////////////////////////    ///////////    //////////////////////////////
///////////////////////////////                   //////////////////////////////
///////////////////////////////                   //////////////////////////////
///////////////////////////////    ///////////    //////////////////////////////
///////////////////////////////    ///////////    //////////////////////////////
///////////////////////////////    ///////////    //////////////////////////////
////////////////////////////////, /////////////, ///////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

/**
    https://hare.travel
    @author: Coeus
 */

// contracts/Hare.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "./interfaces/IBEP20.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";

contract Hare is ContextUpgradeable, IBEP20, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    string private constant _name = "Hare";
    string private constant _symbol = "HARE";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromLimits;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant TOTAL_COIN = 1000000000000;
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;
    uint256 public _advisoryFee;
    uint256 public _developmentFee;
    uint256 public _reflectionFee;
    uint256 public _liquidityFee;
    uint256 public _marketingFee;
    uint256 private _previousReflectionFee;
    uint256 public _companyTotalFees;
    uint256 private _previousTotalCompanyFees;
    uint256 public maxWalletAmount;

    mapping(address => bool) private bots;
    address payable public _advisoryWalletAddress;
    address payable public _marketingWalletAddress;
    address payable public _developmentWalletAddress;
    address payable public _liquidityWalletAddress;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    bool public isTradingEnabled;
    bool private liquidityAdded;
    bool private inSwap;
    bool private isSwapEnabled;
    uint256 public _maxTxAmount;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeFromLimits(address indexed account, bool isExcluded);
    event FeesDisabled(bool enabled);
    event FeesEnabled(bool enabled);
    event LiquiditySet(bool completed);
    event LiquidityPercentSet(uint256 oldFee, uint256 newFee);
    event MaxTxAmountPerMilleUpdated(uint256 maxTxAmount);
    event MaxTxAmountUpdated(uint256 maxTxAmount);
    event ManualSend(uint256 contractETHBalance);
    event ManualSwap(uint256 contractBalance);
    event OpenLiquidity(bool enabled);
    event OpenTrading(bool enabled);
    event PairAddressSet(bool completed);
    event RouterAddressUpdated(address newRouter);
    event SweptBNB(bool completed);
    event SweptTokens(address to, uint256 amount);
    event UpdatedAdvisoryWallet(
        address indexed oldAddress,
        address indexed newAddress
    );
    event UpdatedDevelopmentWallet(
        address indexed oldAddress,
        address indexed newAddress
    );
    event UpdatedLiquidityWallet(
        address indexed oldAddress,
        address indexed newAddress
    );
    event UpdatedMarketingWallet(
        address indexed oldAddress,
        address indexed newAddress
    );

    event AdvisoryTaxPercentSet(uint256 oldFee, uint256 newFee);
    event DevelopmentTaxPercentSet(uint256 oldFee, uint256 newFee);
    event MarketingTaxPercentSet(uint256 oldFee, uint256 newFee);
    event ReflectionTaxPercentSet(uint256 oldFee, uint256 newFee);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    function initialize(
        address payable advAddr,
        address payable devAddr,
        address payable mktgAddr,
        address payable liqAddr
    ) public initializer {
        __Ownable_init();

        _tTotal = TOTAL_COIN * 10**uint8(_decimals);
        _rTotal = (MAX - (MAX % _tTotal));
        _tFeeTotal;
        _advisoryFee = 1;
        _developmentFee = 2;
        _reflectionFee = 2;
        _liquidityFee = 3;
        _marketingFee = 2;
        _previousReflectionFee = _reflectionFee;
        _companyTotalFees =
            _advisoryFee +
            _developmentFee +
            _liquidityFee +
            _marketingFee;
        _previousTotalCompanyFees = _companyTotalFees;
        maxWalletAmount = 10000000000 * 10**uint8(_decimals);

        _advisoryWalletAddress = payable(advAddr);
        _developmentWalletAddress = payable(devAddr);
        _marketingWalletAddress = payable(mktgAddr);
        _liquidityWalletAddress = payable(liqAddr);

        isTradingEnabled = false;
        liquidityAdded = false;
        inSwap = false;
        isSwapEnabled = false;
        _maxTxAmount = (totalSupply() * 2) / 1000;
        _rOwned[_msgSender()] = _rTotal;

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(_advisoryWalletAddress, true);
        excludeFromFees(_marketingWalletAddress, true);
        excludeFromFees(_developmentWalletAddress, true);
        excludeFromFees(_liquidityWalletAddress, true);

        excludeFromLimits(owner(), true);
        excludeFromLimits(address(this), true);
        excludeFromLimits(_advisoryWalletAddress, true);
        excludeFromLimits(_marketingWalletAddress, true);
        excludeFromLimits(_developmentWalletAddress, true);
        excludeFromLimits(_liquidityWalletAddress, true);

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function manualSend() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);

        emit ManualSend(contractETHBalance);
    }

    function manualSwap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);

        emit ManualSwap(contractBalance);
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: Approve from the zero address");
        require(spender != address(0), "ERC20: Approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

   function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            if (!_isExcludedFromLimits[from] || !_isExcludedFromLimits[to]) {
                if(from == uniswapV2Pair || to == uniswapV2Pair){
                    require(amount <= _maxTxAmount, "You are exceeding max transaction amount");
                }

                if(to != uniswapV2Pair){
                    require(balanceOf(to) + amount <= maxWalletAmount, "Maximum wallet size limit");
                }
            }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && isSwapEnabled) {
                require(isTradingEnabled, "Trading is not active.");
            }

            uint256 contractTokenBalance = balanceOf(address(this));

            if (!inSwap && from != uniswapV2Pair && isSwapEnabled) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        bool takeFee = true;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
        restoreAllFee;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function setMaxTxAmountPerMille(uint8 newMaxTxAmountPerMille)
        external
        onlyOwner
    {
        require(
            newMaxTxAmountPerMille >= 1 && newMaxTxAmountPerMille <= 1000,
            "Max Tc must be between 0.1% (1) and 100% (1000)"
        );
        uint256 newMaxTxAmount = (totalSupply() * newMaxTxAmountPerMille) /
            1000;
        _maxTxAmount = newMaxTxAmount;

        emit MaxTxAmountPerMilleUpdated(_maxTxAmount);
    }

    function setMaxWalletPerMille(uint8 maxWalletPerMille) external onlyOwner {
        require(
            maxWalletPerMille >= 1 && maxWalletPerMille <= 1000,
            "Max wallet percentage must be between 0.1% (1) and 100% (1000)"
        );
        uint256 newMaxWalletAmount = (totalSupply() * maxWalletPerMille) / 1000;
        maxWalletAmount = newMaxWalletAmount;
    }

    function excludeFromLimits(address walletAddress, bool excluded)
        public
        onlyOwner
    {
        _isExcludedFromLimits[walletAddress] = excluded;

        emit ExcludeFromLimits(walletAddress, excluded);
    }

    function excludeFromFees(address walletAddress, bool excluded)
        public
        onlyOwner
    {
        _isExcludedFromFees[walletAddress] = excluded;

        emit ExcludeFromFees(walletAddress, excluded);
    }

    function tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function sendETHToFee(uint256 amount) private {
        _advisoryWalletAddress.transfer(
            amount.mul(_advisoryFee).div(_companyTotalFees)
        );
        _marketingWalletAddress.transfer(
            amount.mul(_marketingFee).div(_companyTotalFees)
        );
        _developmentWalletAddress.transfer(
            amount.mul(_developmentFee).div(_companyTotalFees)
        );
        _liquidityWalletAddress.transfer(
            amount.mul(_liquidityFee).div(_companyTotalFees)
        );
    }

    function openLiquidity(bool _enabled) external onlyOwner {
        isSwapEnabled = _enabled;
        liquidityAdded = _enabled;

        emit OpenLiquidity(_enabled);
    }

    function openTrading(bool _enabled) external onlyOwner {
        require(liquidityAdded, "Liquidity not enabled.");
        isTradingEnabled = _enabled;

        emit OpenTrading(_enabled);
    }

    function addLiquidity() external onlyOwner {
        require(
            address(uniswapV2Router) != address(0),
            "UniswapV2Router not set."
        );
        require(address(uniswapV2Pair) != address(0), "UniswapV2Pair not set.");

        _approve(address(this), address(uniswapV2Router), _tTotal);

        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );

        IBEP20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );

        emit LiquiditySet(true);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tCompany) = _getTValues(
            tAmount,
            _reflectionFee,
            _companyTotalFees
        );
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tCompany,
            currentRate
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tCompany
        );
    }

    function _getTValues(
        uint256 tAmount,
        uint256 taxFee,
        uint256 companyFee
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(taxFee).div(100);
        uint256 tCompany = tAmount.mul(companyFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tCompany);
        return (tTransferAmount, tFee, tCompany);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tCompany,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rCompany = tCompany.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rCompany);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function setPairAddress() public onlyOwner {
        require(
            address(uniswapV2Router) != address(0),
            "Must set uniswapV2Router first"
        );

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );

        emit PairAddressSet(true);
    }

    function updateRouterAddress(address newRouter) external onlyOwner {
        require(address(newRouter) != address(0), "Address cannot be 0");
        require(
            newRouter != address(uniswapV2Router),
            "Router already has that address"
        );

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(newRouter);
        uniswapV2Router = _uniswapV2Router;

        emit RouterAddressUpdated(newRouter);
    }

    function updateAdvisoryWalletAddress(address payable advisoryWalletAddress)
        external
        onlyOwner
    {
        require(
            address(advisoryWalletAddress) != address(0),
            "Address cannot be 0"
        );

        address oldAddress = _advisoryWalletAddress;
        excludeFromFees(advisoryWalletAddress, true);
        excludeFromFees(_advisoryWalletAddress, false);
        excludeFromLimits(advisoryWalletAddress, true);
        excludeFromLimits(_advisoryWalletAddress, false);
        _advisoryWalletAddress = advisoryWalletAddress;

        emit UpdatedAdvisoryWallet(oldAddress, _advisoryWalletAddress);
    }

    function updateDevelopmentWalletAddress(
        address payable developmentWalletAddress
    ) external onlyOwner {
        require(
            address(developmentWalletAddress) != address(0),
            "Address cannot be 0"
        );

        address oldAddress = _developmentWalletAddress;
        excludeFromFees(developmentWalletAddress, true);
        excludeFromFees(_developmentWalletAddress, false);
        excludeFromLimits(developmentWalletAddress, true);
        excludeFromLimits(_developmentWalletAddress, false);
        _developmentWalletAddress = developmentWalletAddress;

        emit UpdatedDevelopmentWallet(oldAddress, _developmentWalletAddress);
    }

    function updateLiquidityWalletAddress(
        address payable liquidityWalletAddress
    ) external onlyOwner {
        require(
            address(liquidityWalletAddress) != address(0),
            "Address cannot be 0"
        );

        address oldAddress = _liquidityWalletAddress;
        excludeFromLimits(liquidityWalletAddress, true);
        excludeFromLimits(_liquidityWalletAddress, false);
        _liquidityWalletAddress = liquidityWalletAddress;

        emit UpdatedLiquidityWallet(oldAddress, _liquidityWalletAddress);
    }

    function updateMarketingWalletAddress(
        address payable marketingWalletAddress
    ) external onlyOwner {
        require(
            address(marketingWalletAddress) != address(0),
            "Address cannot be 0"
        );

        address oldAddress = _marketingWalletAddress;
        excludeFromFees(marketingWalletAddress, true);
        excludeFromFees(_marketingWalletAddress, false);
        excludeFromLimits(marketingWalletAddress, true);
        excludeFromLimits(_marketingWalletAddress, false);
        _marketingWalletAddress = marketingWalletAddress;

        emit UpdatedMarketingWallet(oldAddress, _marketingWalletAddress);
    }

    function setReflectionTaxPercent(uint256 newFee) external onlyOwner {
        uint256 oldFee = _reflectionFee;
        _reflectionFee = newFee;
        _previousReflectionFee = _reflectionFee;

        emit ReflectionTaxPercentSet(oldFee, _reflectionFee);
    }

    function setAdvisoryTaxPercent(uint256 newFee) external onlyOwner {
        uint256 oldFee = _advisoryFee;
        _advisoryFee = newFee;
        _companyTotalFees =
            _marketingFee +
            _developmentFee +
            _advisoryFee +
            _liquidityFee;
        _previousTotalCompanyFees = _companyTotalFees;

        emit AdvisoryTaxPercentSet(oldFee, _advisoryFee);
    }

    function setDevelopmentTaxPercent(uint256 newFee) external onlyOwner {
        uint256 oldFee = _developmentFee;
        _developmentFee = newFee;
        _companyTotalFees =
            _marketingFee +
            _developmentFee +
            _advisoryFee +
            _liquidityFee;
        _previousTotalCompanyFees = _companyTotalFees;

        emit DevelopmentTaxPercentSet(oldFee, _developmentFee);
    }

    function setMarketingTaxPercent(uint256 newFee) external onlyOwner {
        uint256 oldFee = _marketingFee;
        _marketingFee = newFee;
        _companyTotalFees =
            _marketingFee +
            _developmentFee +
            _advisoryFee +
            _liquidityFee;
        _previousTotalCompanyFees = _companyTotalFees;

        emit MarketingTaxPercentSet(oldFee, _marketingFee);
    }

    function setLiquidityTaxPercent(uint256 liquidityFee) external onlyOwner {
        uint256 oldFee = _liquidityFee;
        _liquidityFee = liquidityFee;
        _companyTotalFees =
            _marketingFee +
            _developmentFee +
            _advisoryFee +
            _liquidityFee;
        _previousTotalCompanyFees = _companyTotalFees;

        emit LiquidityPercentSet(oldFee, _liquidityFee);
    }

    function removeAllFee() private {
        if (_reflectionFee == 0 && _companyTotalFees == 0) return;

        _previousReflectionFee = _reflectionFee;
        _reflectionFee = 0;
        _previousTotalCompanyFees = _companyTotalFees;
        _companyTotalFees = 0;

        emit FeesDisabled(true);
    }

    function restoreAllFee() private {
        _reflectionFee = _previousReflectionFee;

        _companyTotalFees =
            _advisoryFee +
            _developmentFee +
            _liquidityFee +
            _marketingFee;

        _previousTotalCompanyFees = _companyTotalFees;

        emit FeesEnabled(true);
    }

    // Used to withdraw any BNB which is in the contract address by mistake
    function sweepBNB(uint256 amount) public onlyOwner {
        if (address(this).balance == 0) {
            revert("Contract has a zero balance.");
        } else {
            if (amount == 0) {
                payable(owner()).transfer(address(this).balance);
            } else {
                payable(owner()).transfer(amount);
            }

            emit SweptBNB(true);
        }
    }

    // Used to withdraw tokens transferred to this address by mistake
    function sweepTokens(address token, uint256 amount) public onlyOwner {
        require(amount > 0, "Invalid amount supplied.");
        IBEP20(address(token)).transfer(msg.sender, amount);

        emit SweptTokens(msg.sender, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

/*
SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/*
SPDX-License-Identifier: MIT
*/

pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

/*
SPDX-License-Identifier: MIT
*/

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

/*
SPDX-License-Identifier: MIT
*/

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}