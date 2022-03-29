// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// ==================== Internal Imports ====================

import { ExactSafeErc20 } from "../../lib/ExactSafeErc20.sol";
import { PreciseUnitMath } from "../../lib/PreciseUnitMath.sol";
import { AddressArrayUtil } from "../../lib/AddressArrayUtil.sol";

import { ModuleBase } from "../lib/ModuleBase.sol";
import { PositionUtil } from "../lib/PositionUtil.sol";

import { IWETH } from "../../interfaces/external/IWETH.sol";
import { IController } from "../../interfaces/IController.sol";
import { IMatrixToken } from "../../interfaces/IMatrixToken.sol";
import { INavIssuanceHook } from "../../interfaces/INavIssuanceHook.sol";

/**
 * @title NavIssuanceModule
 *
 * @dev Module that enables issuance and redemption with any valid ERC20 token or ETH if allowed by the manager. Sender receives
 * a proportional amount of MatrixToken on issuance or ERC20 token on redemption based on the calculated net asset value using
 * oracle prices. Manager is able to enforce a premium / discount on issuance / redemption to avoid arbitrage and front
 * running when relying on oracle prices. Managers can charge a fee (denominated in reserve asset).
 */
contract NavIssuanceModule is ModuleBase, ReentrancyGuard {
    using SafeCast for int256;
    using SafeCast for uint256;
    using PreciseUnitMath for int256;
    using PreciseUnitMath for uint256;
    using ExactSafeErc20 for IERC20;
    using PositionUtil for IMatrixToken;
    using AddressArrayUtil for address[];

    // ==================== Constants ====================

    // 0 index stores the manager fee percentage in managerFees array, charged on issue (denominated in reserve asset)
    uint256 internal constant MANAGER_ISSUE_FEE_INDEX = 0;

    // 1 index stores the manager fee percentage in managerFees array, charged on redeem
    uint256 internal constant MANAGER_REDEEM_FEE_INDEX = 1;

    // 0 index stores the manager revenue share protocol fee % on the controller, charged in the issuance function
    uint256 internal constant PROTOCOL_ISSUE_MANAGER_REVENUE_SHARE_FEE_INDEX = 0;

    // 1 index stores the manager revenue share protocol fee % on the controller, charged in the redeem function
    uint256 internal constant PROTOCOL_REDEEM_MANAGER_REVENUE_SHARE_FEE_INDEX = 1;

    // 2 index stores the direct protocol fee % on the controller, charged in the issuance function
    uint256 internal constant PROTOCOL_ISSUE_DIRECT_FEE_INDEX = 2;

    // 3 index stores the direct protocol fee % on the controller, charged in the redeem function
    uint256 internal constant PROTOCOL_REDEEM_DIRECT_FEE_INDEX = 3;

    // ==================== Structs ====================

    /**
     * @dev Premium is a buffer around oracle prices paid by user to the MatrixToken, which prevents arbitrage and oracle front running
     */
    struct IssuanceSetting {
        uint256 maxManagerFee; // Maximum fee manager is allowed to set for issue and redeem
        uint256 premiumPercentage; // Premium percentage (0.01% = 1e14, 1% = 1e16).
        uint256 maxPremiumPercentage; // Maximum premium percentage manager is allowed to set (configured by manager)
        uint256 minMatrixTokenSupply; // Minimum supply required for issuance and redemption, prevent dramatic inflationary changes to the MatrixToken's position multiplier
        address feeRecipient; // Manager fee recipient
        INavIssuanceHook managerIssuanceHook; // Issuance hook configurations
        INavIssuanceHook managerRedemptionHook; // Redemption hook configurations
        uint256[2] managerFees; // Manager fees. 0 index is issue and 1 index is redeem fee (0.01% = 1e14, 1% = 1e16)
        address[] reserveAssets; // Allowed reserve assets - Must have a price enabled with the price oracle
    }

    struct ActionInfo {
        uint256 preFeeReserveQuantity; // Reserve value before fees: represents raw quantity when issuance; represents post-premium value when redeem
        uint256 protocolFees; // Total protocol fees (direct + manager revenue share)
        uint256 managerFee; // Total manager fee paid in reserve asset
        uint256 netFlowQuantity; // quantity of reserve asset sent to MatrixToken when issuing; quantity of reserve asset sent to redeemer when redeeming
        uint256 matrixTokenQuantity; // quantity of minted to mintee when issuing; quantity of redeemed When redeeming;
        uint256 previousMatrixTokenSupply; // supply prior to issue/redeem action
        uint256 newMatrixTokenSupply; // supply after issue/redeem action
        uint256 newReservePositionUnit; // MatrixToken reserve asset position unit after issue/redeem
        int256 newPositionMultiplier; // MatrixToken position multiplier after issue/redeem
    }

    // ==================== Variables ====================

    IWETH internal immutable _weth;

    mapping(IMatrixToken => IssuanceSetting) internal _issuanceSettings;

    // MatrixToken => reserveAsset => isReserved
    mapping(IMatrixToken => mapping(address => bool)) internal _isReserveAssets;

    // ==================== Events ====================

    event IssueMatrixTokenNav(
        IMatrixToken indexed matrixToken,
        address indexed issuer,
        address indexed to,
        address reserveAsset,
        uint256 reserveAssetQuantity,
        address hookContract,
        uint256 matrixTokenQuantity,
        uint256 managerFee,
        uint256 premium
    );

    event RedeemMatrixTokenNav(
        IMatrixToken indexed matrixToken,
        address indexed redeemer,
        address indexed to,
        address reserveAsset,
        uint256 reserveReceiveQuantity,
        address hookContract,
        uint256 matrixTokenQuantity,
        uint256 managerFee,
        uint256 premium
    );

    event AddReserveAsset(IMatrixToken indexed matrixToken, address newReserveAsset);
    event RemoveReserveAsset(IMatrixToken indexed matrixToken, address removedReserveAsset);
    event EditPremium(IMatrixToken indexed matrixToken, uint256 newPremium);
    event EditManagerFee(IMatrixToken indexed matrixToken, uint256 newManagerFee, uint256 index);
    event EditFeeRecipient(IMatrixToken indexed matrixToken, address feeRecipient);

    // ==================== Constructor function ====================

    constructor(IController controller, IWETH weth) ModuleBase(controller) {
        _weth = weth;
    }

    // ==================== Receive function ====================

    receive() external payable {}

    // ==================== External functions ====================

    function getWeth() external view returns (address) {
        return address(_weth);
    }

    function getIssuanceSetting(IMatrixToken matrixToken) external view returns (IssuanceSetting memory) {
        return _issuanceSettings[matrixToken];
    }

    function getReserveAssets(IMatrixToken matrixToken) external view returns (address[] memory) {
        return _issuanceSettings[matrixToken].reserveAssets;
    }

    function isReserveAsset(IMatrixToken matrixToken, address asset) external view returns (bool) {
        return _isReserveAssets[matrixToken][asset];
    }

    function getIssuePremium(
        IMatrixToken matrixToken,
        address reserveAsset,
        uint256 reserveAssetQuantity
    ) external view returns (uint256) {
        return _getIssuePremium(matrixToken, reserveAsset, reserveAssetQuantity);
    }

    function getRedeemPremium(
        IMatrixToken matrixToken,
        address reserveAsset,
        uint256 matrixTokenQuantity
    ) external view returns (uint256) {
        return _getRedeemPremium(matrixToken, reserveAsset, matrixTokenQuantity);
    }

    function getManagerFee(IMatrixToken matrixToken, uint256 managerFeeIndex) external view returns (uint256) {
        return _issuanceSettings[matrixToken].managerFees[managerFeeIndex];
    }

    /**
     * @dev Get the expected MatrixToken minted to recipient on issuance
     *
     * @param matrixToken            Instance of the MatrixToken
     * @param reserveAsset           Address of the reserve asset
     * @param reserveAssetQuantity   Quantity of the reserve asset to issue with
     *
     * @return uint256               Expected MatrixToken to be minted to recipient
     */
    function getExpectedMatrixTokenIssueQuantity(
        IMatrixToken matrixToken,
        address reserveAsset,
        uint256 reserveAssetQuantity
    ) external view returns (uint256) {
        uint256 totalSupply = matrixToken.totalSupply();

        (, , uint256 netReserveFlow) = _getFees(
            matrixToken,
            reserveAssetQuantity,
            PROTOCOL_ISSUE_MANAGER_REVENUE_SHARE_FEE_INDEX,
            PROTOCOL_ISSUE_DIRECT_FEE_INDEX,
            MANAGER_ISSUE_FEE_INDEX
        );

        return _getMatrixTokenMintQuantity(matrixToken, reserveAsset, netReserveFlow, totalSupply);
    }

    /**
     * @dev Get the expected reserve asset to be redeemed
     *
     * @param matrixToken            Instance of the MatrixToken
     * @param reserveAsset           Address of the reserve asset
     * @param matrixTokenQuantity    Quantity of MatrixToken to redeem
     *
     * @return uint256               Expected reserve asset quantity redeemed
     */
    function getExpectedReserveRedeemQuantity(
        IMatrixToken matrixToken,
        address reserveAsset,
        uint256 matrixTokenQuantity
    ) external view returns (uint256) {
        uint256 preFeeReserveQuantity = _getRedeemReserveQuantity(matrixToken, reserveAsset, matrixTokenQuantity);

        (, , uint256 netReserveFlows) = _getFees(
            matrixToken,
            preFeeReserveQuantity,
            PROTOCOL_REDEEM_MANAGER_REVENUE_SHARE_FEE_INDEX,
            PROTOCOL_REDEEM_DIRECT_FEE_INDEX,
            MANAGER_REDEEM_FEE_INDEX
        );

        return netReserveFlows;
    }

    /**
     * @dev Checks if issue is valid
     *
     * @param matrixToken             Instance of the MatrixToken
     * @param reserveAsset            Address of the reserve asset
     * @param reserveAssetQuantity    Quantity of the reserve asset to issue with
     *
     * @return bool                   Returns true if issue is valid
     */
    function isValidIssue(
        IMatrixToken matrixToken,
        address reserveAsset,
        uint256 reserveAssetQuantity
    ) external view returns (bool) {
        return
            reserveAssetQuantity != 0 &&
            _isReserveAssets[matrixToken][reserveAsset] &&
            matrixToken.totalSupply() >= _issuanceSettings[matrixToken].minMatrixTokenSupply;
    }

    /**
     * @dev Checks if redeem is valid
     *
     * @param matrixToken            Instance of the MatrixToken
     * @param reserveAsset           Address of the reserve asset
     * @param matrixTokenQuantity    Quantity of MatrixToken to redeem
     *
     * @return bool                  Returns true if redeem is valid
     */
    function isValidRedeem(
        IMatrixToken matrixToken,
        address reserveAsset,
        uint256 matrixTokenQuantity
    ) external view returns (bool) {
        uint256 totalSupply = matrixToken.totalSupply();

        if (
            (matrixTokenQuantity == 0) ||
            !_isReserveAssets[matrixToken][reserveAsset] ||
            (totalSupply < _issuanceSettings[matrixToken].minMatrixTokenSupply + matrixTokenQuantity)
        ) {
            return false;
        } else {
            uint256 existingUnit = matrixToken.getDefaultPositionRealUnit(reserveAsset).toUint256();
            uint256 totalRedeemValue = _getRedeemReserveQuantity(matrixToken, reserveAsset, matrixTokenQuantity);

            (, , uint256 expectedRedeemQuantity) = _getFees(
                matrixToken,
                totalRedeemValue,
                PROTOCOL_REDEEM_MANAGER_REVENUE_SHARE_FEE_INDEX,
                PROTOCOL_REDEEM_DIRECT_FEE_INDEX,
                MANAGER_REDEEM_FEE_INDEX
            );

            return existingUnit.preciseMul(totalSupply) >= expectedRedeemQuantity;
        }
    }

    /**
     * @dev Initializes this module to the MatrixToken with hooks, allowed reserve assets,
     * fees and issuance premium. Only callable by the MatrixToken's manager. Hook addresses are optional.
     * Address(0) means that no hook will be called.
     *
     * @param matrixToken        Instance of the MatrixToken to issue
     * @param issuanceSetting    IssuanceSetting struct defining parameters
     */
    function initialize(IMatrixToken matrixToken, IssuanceSetting memory issuanceSetting)
        external
        onlyMatrixManager(matrixToken, msg.sender)
        onlyValidAndPendingMatrix(matrixToken)
    {
        require(issuanceSetting.reserveAssets.length > 0, "N0a"); // "Reserve assets must be greater than 0"
        require(issuanceSetting.maxManagerFee < PreciseUnitMath.preciseUnit(), "N0b"); // "Max manager fee must be less than 100%"
        require(issuanceSetting.maxPremiumPercentage < PreciseUnitMath.preciseUnit(), "N0c"); // "Max premium percentage must be less than 100%"
        require(issuanceSetting.managerFees[0] <= issuanceSetting.maxManagerFee, "N0d"); // "Manager issue fee must be less than max"
        require(issuanceSetting.managerFees[1] <= issuanceSetting.maxManagerFee, "N0e"); // "Manager redeem fee must be less than max"
        require(issuanceSetting.premiumPercentage <= issuanceSetting.maxPremiumPercentage, "N0f"); // "Premium must be less than max"
        require(issuanceSetting.feeRecipient != address(0), "N0g"); // "Fee Recipient must be non-zero address"

        // Initial mint cannot use NAVIssuance since minMatrixTokenSupply must be > 0
        require(issuanceSetting.minMatrixTokenSupply > 0, "N0h"); // "Min MatrixToken supply must be greater than 0"

        for (uint256 i = 0; i < issuanceSetting.reserveAssets.length; i++) {
            require(!_isReserveAssets[matrixToken][issuanceSetting.reserveAssets[i]], "N0i"); // "Reserve assets must be unique"

            _isReserveAssets[matrixToken][issuanceSetting.reserveAssets[i]] = true;
        }

        _issuanceSettings[matrixToken] = issuanceSetting;
        matrixToken.initializeModule();
    }

    /**
     * @dev Removes this module from the MatrixToken when called by the MatrixToken, delete issuance setting and reserve asset states.
     */
    function removeModule() external override {
        IMatrixToken matrixToken = IMatrixToken(msg.sender);

        for (uint256 i = 0; i < _issuanceSettings[matrixToken].reserveAssets.length; i++) {
            delete _isReserveAssets[matrixToken][_issuanceSettings[matrixToken].reserveAssets[i]];
        }

        delete _issuanceSettings[matrixToken];
    }

    /**
     * @dev Deposits the allowed reserve asset into the MatrixToken and
     * mints the appropriate % of Net Asset Value of the MatrixToken to the specified to address.
     *
     * @param matrixToken                      Instance of the MatrixToken contract
     * @param reserveAsset                     Address of the reserve asset to issue with
     * @param reserveAssetQuantity             Quantity of the reserve asset to issue with
     * @param minMatrixTokenReceiveQuantity    Min quantity of MatrixToken to receive after issuance
     * @param to                               Address to mint MatrixToken to
     */
    function issue(
        IMatrixToken matrixToken,
        address reserveAsset,
        uint256 reserveAssetQuantity,
        uint256 minMatrixTokenReceiveQuantity,
        address to
    ) external nonReentrant onlyValidAndInitializedMatrix(matrixToken) {
        _validateCommon(matrixToken, reserveAsset, reserveAssetQuantity);
        _callPreIssueHooks(matrixToken, reserveAsset, reserveAssetQuantity, msg.sender, to);
        ActionInfo memory issueInfo = _createIssuanceInfo(matrixToken, reserveAsset, reserveAssetQuantity);
        _validateIssuanceInfo(matrixToken, minMatrixTokenReceiveQuantity, issueInfo);
        _transferCollateralAndHandleFees(matrixToken, IERC20(reserveAsset), issueInfo);
        _handleIssueStateUpdates(matrixToken, reserveAsset, to, issueInfo);
    }

    /**
     * @dev Wraps ETH and deposits WETH if allowed into the MatrixToken and
     * mints the appropriate % of Net Asset Value of the MatrixToken to the specified _to address.
     *
     * @param matrixToken                      Instance of the MatrixToken contract
     * @param minMatrixTokenReceiveQuantity    Min quantity of MatrixToken to receive after issuance
     * @param to                               Address to mint MatrixToken to
     */
    function issueWithEther(
        IMatrixToken matrixToken,
        uint256 minMatrixTokenReceiveQuantity,
        address to
    ) external payable nonReentrant onlyValidAndInitializedMatrix(matrixToken) {
        _weth.deposit{ value: msg.value }();
        _validateCommon(matrixToken, address(_weth), msg.value);
        _callPreIssueHooks(matrixToken, address(_weth), msg.value, msg.sender, to);
        ActionInfo memory issueInfo = _createIssuanceInfo(matrixToken, address(_weth), msg.value);
        _validateIssuanceInfo(matrixToken, minMatrixTokenReceiveQuantity, issueInfo);
        _transferWethAndHandleFees(matrixToken, issueInfo);
        _handleIssueStateUpdates(matrixToken, address(_weth), to, issueInfo);
    }

    /**
     * @dev Redeems a MatrixToken into a valid reserve asset representing the appropriate % of Net Asset Value of
     * the MatrixToken to the specified _to address. Only valid if there are available reserve units on the MatrixToken.
     *
     * @param matrixToken                  Instance of the MatrixToken contract
     * @param reserveAsset                 Address of the reserve asset to redeem with
     * @param matrixTokenQuantity          Quantity of MatrixToken to redeem
     * @param minReserveReceiveQuantity    Min quantity of reserve asset to receive
     * @param to                           Address to redeem reserve asset to
     */
    function redeem(
        IMatrixToken matrixToken,
        address reserveAsset,
        uint256 matrixTokenQuantity,
        uint256 minReserveReceiveQuantity,
        address to
    ) external nonReentrant onlyValidAndInitializedMatrix(matrixToken) {
        _validateCommon(matrixToken, reserveAsset, matrixTokenQuantity);
        _callPreRedeemHooks(matrixToken, matrixTokenQuantity, msg.sender, to);
        ActionInfo memory redeemInfo = _createRedemptionInfo(matrixToken, reserveAsset, matrixTokenQuantity);
        _validateRedemptionInfo(matrixToken, minReserveReceiveQuantity, redeemInfo);
        matrixToken.burn(msg.sender, matrixTokenQuantity);

        // Instruct the MatrixToken to transfer the reserve asset back to the user
        matrixToken.invokeExactSafeTransfer(reserveAsset, to, redeemInfo.netFlowQuantity);
        _handleRedemptionFees(matrixToken, reserveAsset, redeemInfo);
        _handleRedeemStateUpdates(matrixToken, reserveAsset, to, redeemInfo);
    }

    /**
     * @dev Redeems a MatrixToken into Ether (if WETH is valid) representing the appropriate % of Net Asset Value of
     * the MatrixToken to the specified _to address. Only valid if there are available WETH units on the MatrixToken.
     *
     * @param matrixToken                  Instance of the MatrixToken contract
     * @param matrixTokenQuantity          Quantity of MatrixToken to redeem
     * @param minReserveReceiveQuantity    Min quantity of reserve asset to receive
     * @param to                           Address to redeem reserve asset to
     */
    function redeemIntoEther(
        IMatrixToken matrixToken,
        uint256 matrixTokenQuantity,
        uint256 minReserveReceiveQuantity,
        address payable to
    ) external nonReentrant onlyValidAndInitializedMatrix(matrixToken) {
        _validateCommon(matrixToken, address(_weth), matrixTokenQuantity);
        _callPreRedeemHooks(matrixToken, matrixTokenQuantity, msg.sender, to);
        ActionInfo memory redeemInfo = _createRedemptionInfo(matrixToken, address(_weth), matrixTokenQuantity);
        _validateRedemptionInfo(matrixToken, minReserveReceiveQuantity, redeemInfo);
        matrixToken.burn(msg.sender, matrixTokenQuantity);

        // Instruct the MatrixToken to transfer WETH from MatrixToken to module
        matrixToken.invokeExactSafeTransfer(address(_weth), address(this), redeemInfo.netFlowQuantity);
        _weth.withdraw(redeemInfo.netFlowQuantity);
        to.transfer(redeemInfo.netFlowQuantity);
        _handleRedemptionFees(matrixToken, address(_weth), redeemInfo);
        _handleRedeemStateUpdates(matrixToken, address(_weth), to, redeemInfo);
    }

    /**
     * @dev Add an allowed reserve asset
     *
     * @param matrixToken     Instance of the MatrixToken
     * @param reserveAsset    Address of the reserve asset to add
     */
    function addReserveAsset(IMatrixToken matrixToken, address reserveAsset) external onlyManagerAndValidMatrix(matrixToken) {
        _addReserveAsset(matrixToken, reserveAsset);
    }

    function batchAddReserveAsset(IMatrixToken matrixToken, address[] memory reserveAssets) external onlyManagerAndValidMatrix(matrixToken) {
        _batchAddReserveAsset(matrixToken, reserveAssets);
    }

    /**
     * @dev Remove a reserve asset
     *
     * @param matrixToken     Instance of the MatrixToken
     * @param reserveAsset    Address of the reserve asset to remove
     */
    function removeReserveAsset(IMatrixToken matrixToken, address reserveAsset) external onlyManagerAndValidMatrix(matrixToken) {
        _removeReserveAsset(matrixToken, reserveAsset);
    }

    function batchRemoveReserveAsset(IMatrixToken matrixToken, address[] memory reserveAssets) external onlyManagerAndValidMatrix(matrixToken) {
        for (uint256 i = 0; i < reserveAssets.length; i++) {
            _removeReserveAsset(matrixToken, reserveAssets[i]);
        }
    }

    function setReserveAsset(IMatrixToken matrixToken, address[] memory reserveAssets) external onlyManagerAndValidMatrix(matrixToken) {
        IssuanceSetting memory oldIssuanceSetting = _issuanceSettings[matrixToken];

        require(!oldIssuanceSetting.reserveAssets.equal(reserveAssets), "N1");

        _setReserveAsset(matrixToken, reserveAssets);
    }

    /**
     * @dev Edit the premium percentage
     *
     * @param matrixToken          Instance of the MatrixToken
     * @param premiumPercentage    Premium percentage in 10e16 (e.g. 10e16 = 1%)
     */
    function editPremium(IMatrixToken matrixToken, uint256 premiumPercentage) external onlyManagerAndValidMatrix(matrixToken) {
        _editPremium(matrixToken, premiumPercentage);
    }

    /**
     * @dev Edit manager fee
     *
     * @param matrixToken             Instance of the MatrixToken
     * @param managerFeePercentage    Manager fee percentage in 10e16 (e.g. 10e16 = 1%)
     * @param managerFeeIndex         Manager fee index. 0 index is issue fee, 1 index is redeem fee
     */
    function editManagerFee(
        IMatrixToken matrixToken,
        uint256 managerFeePercentage,
        uint256 managerFeeIndex
    ) external onlyManagerAndValidMatrix(matrixToken) {
        _editManagerFee(matrixToken, managerFeePercentage, managerFeeIndex);
    }

    /**
     * @dev Edit the manager fee recipient
     *
     * @param matrixToken            Instance of the MatrixToken
     * @param managerFeeRecipient    Manager fee recipient
     */
    function editFeeRecipient(IMatrixToken matrixToken, address managerFeeRecipient) external onlyManagerAndValidMatrix(matrixToken) {
        _editFeeRecipient(matrixToken, managerFeeRecipient);
    }

    function editIssuanceSetting(IMatrixToken matrixToken, IssuanceSetting memory newIssuanceSetting) external onlyManagerAndValidMatrix(matrixToken) {
        IssuanceSetting memory oldIssuanceSetting = _issuanceSettings[matrixToken];

        if (!oldIssuanceSetting.reserveAssets.equal(newIssuanceSetting.reserveAssets)) {
            _setReserveAsset(matrixToken, newIssuanceSetting.reserveAssets);
        }

        if (oldIssuanceSetting.premiumPercentage != newIssuanceSetting.premiumPercentage) {
            _editPremium(matrixToken, newIssuanceSetting.premiumPercentage);
        }

        if (oldIssuanceSetting.managerFees[0] != newIssuanceSetting.managerFees[0]) {
            _editManagerFee(matrixToken, newIssuanceSetting.managerFees[0], 0);
        }

        if (oldIssuanceSetting.managerFees[1] != newIssuanceSetting.managerFees[1]) {
            _editManagerFee(matrixToken, newIssuanceSetting.managerFees[1], 1);
        }

        if (oldIssuanceSetting.feeRecipient != newIssuanceSetting.feeRecipient) {
            _editFeeRecipient(matrixToken, newIssuanceSetting.feeRecipient);
        }
    }

    // ==================== Internal functions ====================

    function _addReserveAsset(IMatrixToken matrixToken, address reserveAsset) internal {
        require(!_isReserveAssets[matrixToken][reserveAsset], "N2"); // "Reserve asset already exists"

        _issuanceSettings[matrixToken].reserveAssets.push(reserveAsset);
        _isReserveAssets[matrixToken][reserveAsset] = true;

        emit AddReserveAsset(matrixToken, reserveAsset);
    }

    function _batchAddReserveAsset(IMatrixToken matrixToken, address[] memory reserveAssets) internal {
        require(reserveAssets.length > 0, "N3"); // "Reserve assets must be greater than 0"

        for (uint256 i = 0; i < reserveAssets.length; i++) {
            _addReserveAsset(matrixToken, reserveAssets[i]);
        }
    }

    function _removeReserveAsset(IMatrixToken matrixToken, address reserveAsset) internal {
        require(_isReserveAssets[matrixToken][reserveAsset], "N4"); // "Reserve asset does not exist"

        _issuanceSettings[matrixToken].reserveAssets.quickRemoveItem(reserveAsset);
        delete _isReserveAssets[matrixToken][reserveAsset];

        emit RemoveReserveAsset(matrixToken, reserveAsset);
    }

    function _setReserveAsset(IMatrixToken matrixToken, address[] memory reserveAssets) internal {
        address[] memory oldReserveAssets = _issuanceSettings[matrixToken].reserveAssets;

        for (uint256 i = 0; i < oldReserveAssets.length; i++) {
            delete _isReserveAssets[matrixToken][oldReserveAssets[i]];

            emit RemoveReserveAsset(matrixToken, oldReserveAssets[i]);
        }

        delete _issuanceSettings[matrixToken].reserveAssets;

        _batchAddReserveAsset(matrixToken, reserveAssets);
    }

    function _editPremium(IMatrixToken matrixToken, uint256 premiumPercentage) internal {
        require(premiumPercentage <= _issuanceSettings[matrixToken].maxPremiumPercentage, "N5"); // "Premium must be less than maximum allowed"

        _issuanceSettings[matrixToken].premiumPercentage = premiumPercentage;

        emit EditPremium(matrixToken, premiumPercentage);
    }

    function _editManagerFee(
        IMatrixToken matrixToken,
        uint256 managerFeePercentage,
        uint256 managerFeeIndex
    ) internal {
        require(managerFeePercentage <= _issuanceSettings[matrixToken].maxManagerFee, "N6"); // "Manager fee must be less than maximum allowed"

        _issuanceSettings[matrixToken].managerFees[managerFeeIndex] = managerFeePercentage;

        emit EditManagerFee(matrixToken, managerFeePercentage, managerFeeIndex);
    }

    function _editFeeRecipient(IMatrixToken matrixToken, address managerFeeRecipient) internal {
        require(managerFeeRecipient != address(0), "N7"); // "Fee recipient must not be 0 address"

        _issuanceSettings[matrixToken].feeRecipient = managerFeeRecipient;

        emit EditFeeRecipient(matrixToken, managerFeeRecipient);
    }

    function _validateCommon(
        IMatrixToken matrixToken,
        address reserveAsset,
        uint256 quantity
    ) internal view {
        require(quantity > 0, "N8a"); // "Quantity must be > 0"
        require(_isReserveAssets[matrixToken][reserveAsset], "N8b"); // "Must be valid reserve asset"
    }

    function _validateIssuanceInfo(
        IMatrixToken matrixToken,
        uint256 minMatrixTokenReceiveQuantity,
        ActionInfo memory issueInfo
    ) internal view {
        // Check that total supply is greater than min supply needed for issuance
        // Note: A min supply amount is needed to avoid division by 0 when MatrixToken supply is 0
        require(issueInfo.previousMatrixTokenSupply >= _issuanceSettings[matrixToken].minMatrixTokenSupply, "N9a"); // "Supply must be greater than minimum to enable issuance"
        require(issueInfo.matrixTokenQuantity >= minMatrixTokenReceiveQuantity, "N9b"); // "Must be greater than min MatrixToken"
    }

    function _validateRedemptionInfo(
        IMatrixToken matrixToken,
        uint256 minReserveReceiveQuantity,
        ActionInfo memory redeemInfo
    ) internal view {
        // Check that new supply is more than min supply needed for redemption
        // Note: A min supply amount is needed to avoid division by 0 when redeeming MatrixToken to 0
        require(redeemInfo.newMatrixTokenSupply >= _issuanceSettings[matrixToken].minMatrixTokenSupply, "N10a"); // "Supply must be greater than minimum to enable redemption"
        require(redeemInfo.netFlowQuantity >= minReserveReceiveQuantity, "N10b"); // "Must be greater than min receive reserve quantity"
    }

    function _createIssuanceInfo(
        IMatrixToken matrixToken,
        address reserveAsset,
        uint256 reserveAssetQuantity
    ) internal view returns (ActionInfo memory) {
        ActionInfo memory issueInfo;
        issueInfo.previousMatrixTokenSupply = matrixToken.totalSupply();
        issueInfo.preFeeReserveQuantity = reserveAssetQuantity;

        (issueInfo.protocolFees, issueInfo.managerFee, issueInfo.netFlowQuantity) = _getFees(
            matrixToken,
            issueInfo.preFeeReserveQuantity,
            PROTOCOL_ISSUE_MANAGER_REVENUE_SHARE_FEE_INDEX,
            PROTOCOL_ISSUE_DIRECT_FEE_INDEX,
            MANAGER_ISSUE_FEE_INDEX
        );

        issueInfo.matrixTokenQuantity = _getMatrixTokenMintQuantity(matrixToken, reserveAsset, issueInfo.netFlowQuantity, issueInfo.previousMatrixTokenSupply);
        (issueInfo.newMatrixTokenSupply, issueInfo.newPositionMultiplier) = _getIssuePositionMultiplier(matrixToken, issueInfo);
        issueInfo.newReservePositionUnit = _getIssuePositionUnit(matrixToken, reserveAsset, issueInfo);

        return issueInfo;
    }

    function _createRedemptionInfo(
        IMatrixToken matrixToken,
        address reserveAsset,
        uint256 matrixTokenQuantity
    ) internal view returns (ActionInfo memory) {
        ActionInfo memory redeemInfo;
        redeemInfo.previousMatrixTokenSupply = matrixToken.totalSupply();
        redeemInfo.matrixTokenQuantity = matrixTokenQuantity;
        redeemInfo.preFeeReserveQuantity = _getRedeemReserveQuantity(matrixToken, reserveAsset, matrixTokenQuantity);

        (redeemInfo.protocolFees, redeemInfo.managerFee, redeemInfo.netFlowQuantity) = _getFees(
            matrixToken,
            redeemInfo.preFeeReserveQuantity,
            PROTOCOL_REDEEM_MANAGER_REVENUE_SHARE_FEE_INDEX,
            PROTOCOL_REDEEM_DIRECT_FEE_INDEX,
            MANAGER_REDEEM_FEE_INDEX
        );

        (redeemInfo.newMatrixTokenSupply, redeemInfo.newPositionMultiplier) = _getRedeemPositionMultiplier(matrixToken, matrixTokenQuantity, redeemInfo);
        redeemInfo.newReservePositionUnit = _getRedeemPositionUnit(matrixToken, reserveAsset, redeemInfo);

        return redeemInfo;
    }

    /**
     * @dev Transfer reserve asset from user to MatrixToken and fees from user to appropriate fee recipients
     */
    function _transferCollateralAndHandleFees(
        IMatrixToken matrixToken,
        IERC20 reserveAsset,
        ActionInfo memory issueInfo
    ) internal {
        reserveAsset.exactSafeTransferFrom(msg.sender, address(matrixToken), issueInfo.netFlowQuantity);

        if (issueInfo.protocolFees > 0) {
            reserveAsset.exactSafeTransferFrom(msg.sender, _controller.getFeeRecipient(), issueInfo.protocolFees);
        }

        if (issueInfo.managerFee > 0) {
            reserveAsset.exactSafeTransferFrom(msg.sender, _issuanceSettings[matrixToken].feeRecipient, issueInfo.managerFee);
        }
    }

    /**
     * @dev Transfer WETH from module to MatrixToken and fees from module to appropriate fee recipients
     */
    function _transferWethAndHandleFees(IMatrixToken matrixToken, ActionInfo memory issueInfo) internal {
        _weth.transfer(address(matrixToken), issueInfo.netFlowQuantity);

        if (issueInfo.protocolFees > 0) {
            _weth.transfer(_controller.getFeeRecipient(), issueInfo.protocolFees);
        }

        if (issueInfo.managerFee > 0) {
            _weth.transfer(_issuanceSettings[matrixToken].feeRecipient, issueInfo.managerFee);
        }
    }

    function _handleIssueStateUpdates(
        IMatrixToken matrixToken,
        address reserveAsset,
        address to,
        ActionInfo memory issueInfo
    ) internal {
        matrixToken.editPositionMultiplier(issueInfo.newPositionMultiplier);
        matrixToken.editDefaultPosition(reserveAsset, issueInfo.newReservePositionUnit);
        matrixToken.mint(to, issueInfo.matrixTokenQuantity);

        emit IssueMatrixTokenNav(
            matrixToken,
            msg.sender,
            to,
            reserveAsset,
            issueInfo.preFeeReserveQuantity,
            address(_issuanceSettings[matrixToken].managerIssuanceHook),
            issueInfo.matrixTokenQuantity,
            issueInfo.managerFee,
            issueInfo.protocolFees
        );
    }

    function _handleRedeemStateUpdates(
        IMatrixToken matrixToken,
        address reserveAsset,
        address to,
        ActionInfo memory redeemInfo
    ) internal {
        matrixToken.editPositionMultiplier(redeemInfo.newPositionMultiplier);
        matrixToken.editDefaultPosition(reserveAsset, redeemInfo.newReservePositionUnit);

        emit RedeemMatrixTokenNav(
            matrixToken,
            msg.sender,
            to,
            reserveAsset,
            redeemInfo.netFlowQuantity,
            address(_issuanceSettings[matrixToken].managerRedemptionHook),
            redeemInfo.matrixTokenQuantity,
            redeemInfo.managerFee,
            redeemInfo.protocolFees
        );
    }

    function _handleRedemptionFees(
        IMatrixToken matrixToken,
        address reserveAsset,
        ActionInfo memory redeemInfo
    ) internal {
        // Instruct the MatrixToken to transfer protocol fee to fee recipient if there is a fee
        payProtocolFeeFromMatrixToken(matrixToken, reserveAsset, redeemInfo.protocolFees);

        // Instruct the MatrixToken to transfer manager fee to manager fee recipient if there is a fee
        if (redeemInfo.managerFee > 0) {
            matrixToken.invokeExactSafeTransfer(reserveAsset, _issuanceSettings[matrixToken].feeRecipient, redeemInfo.managerFee);
        }
    }

    /**
     * @dev Returns the issue premium percentage. Virtual function that can be overridden
     * in future versions of the module and can contain arbitrary logic to calculate the issuance premium.
     */
    function _getIssuePremium(
        IMatrixToken matrixToken,
        address, /* reserveAsset */
        uint256 /* _reserveAssetQuantity */
    ) internal view virtual returns (uint256) {
        return _issuanceSettings[matrixToken].premiumPercentage;
    }

    /**
     * @dev Returns the redeem premium percentage. Virtual function that can be overridden
     * in future versions of the module and can contain arbitrary logic to calculate the redemption premium.
     */
    function _getRedeemPremium(
        IMatrixToken matrixToken,
        address, /* reserveAsset */
        uint256 /* matrixTokenQuantity */
    ) internal view virtual returns (uint256) {
        return _issuanceSettings[matrixToken].premiumPercentage;
    }

    /**
     * @dev Returns the fees attributed to the manager and the protocol. The fees are calculated as follows:
     * ManagerFee = (manager fee % - % to protocol) * reserveAssetQuantity
     * Protocol Fee = (% manager fee share + direct fee %) * reserveAssetQuantity
     *
     * @param matrixToken                Instance of the MatrixToken
     * @param reserveAssetQuantity       Quantity of reserve asset to calculate fees from
     * @param protocolManagerFeeIndex    Index to pull rev share NAV Issuance fee from the Controller
     * @param protocolDirectFeeIndex     Index to pull direct NAV issuance fee from the Controller
     * @param managerFeeIndex            Index from IssuanceSetting (0 = issue fee, 1 = redeem fee)
     *
     * @return uint256                   Fees paid to the protocol in reserve asset
     * @return uint256                   Fees paid to the manager in reserve asset
     * @return uint256                   Net reserve to user net of fees
     */
    function _getFees(
        IMatrixToken matrixToken,
        uint256 reserveAssetQuantity,
        uint256 protocolManagerFeeIndex,
        uint256 protocolDirectFeeIndex,
        uint256 managerFeeIndex
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 protocolFeePercentage, uint256 managerFeePercentage) = _getProtocolAndManagerFeePercentages(
            matrixToken,
            protocolManagerFeeIndex,
            protocolDirectFeeIndex,
            managerFeeIndex
        );

        // Calculate total notional fees
        uint256 protocolFees = protocolFeePercentage.preciseMul(reserveAssetQuantity);
        uint256 managerFee = managerFeePercentage.preciseMul(reserveAssetQuantity);
        uint256 netReserveFlow = reserveAssetQuantity - protocolFees - managerFee;

        return (protocolFees, managerFee, netReserveFlow);
    }

    function _getProtocolAndManagerFeePercentages(
        IMatrixToken matrixToken,
        uint256 protocolManagerFeeIndex,
        uint256 protocolDirectFeeIndex,
        uint256 managerFeeIndex
    ) internal view returns (uint256, uint256) {
        // Get protocol fee percentages
        uint256 protocolDirectFeePercent = _controller.getModuleFee(address(this), protocolDirectFeeIndex);
        uint256 protocolManagerShareFeePercent = _controller.getModuleFee(address(this), protocolManagerFeeIndex);
        uint256 managerFeePercent = _issuanceSettings[matrixToken].managerFees[managerFeeIndex];

        // Calculate revenue share split percentage
        uint256 protocolRevenueSharePercentage = protocolManagerShareFeePercent.preciseMul(managerFeePercent);
        uint256 managerRevenueSharePercentage = managerFeePercent - protocolRevenueSharePercentage;
        uint256 totalProtocolFeePercentage = protocolRevenueSharePercentage + protocolDirectFeePercent;

        return (totalProtocolFeePercentage, managerRevenueSharePercentage);
    }

    function _getMatrixTokenMintQuantity(
        IMatrixToken matrixToken,
        address reserveAsset,
        uint256 netReserveFlows, // Value of reserve asset net of fees
        uint256 totalSupply
    ) internal view returns (uint256) {
        // Get valuation of the MatrixToken with the quote asset as the reserve asset. Reverts if price is not found
        uint256 matrixTokenValuation = _controller.getMatrixValuer().calculateMatrixTokenValuation(matrixToken, reserveAsset);

        uint256 premiumPercentage = _getIssuePremium(matrixToken, reserveAsset, netReserveFlows);
        uint256 premiumValue = netReserveFlows.preciseMul(premiumPercentage);
        uint256 reserveAssetDecimals = ERC20(reserveAsset).decimals();
        uint256 denominator = totalSupply.preciseMul(matrixTokenValuation).preciseMul(10**reserveAssetDecimals) + premiumValue;

        return (netReserveFlows - premiumValue).preciseMul(totalSupply).preciseDiv(denominator);
    }

    function _getRedeemReserveQuantity(
        IMatrixToken matrixToken,
        address reserveAsset,
        uint256 matrixTokenQuantity
    ) internal view returns (uint256) {
        // Get valuation of the MatrixToken with the quote asset as the reserve asset. Returns value in precise units (10e18). Reverts if price is not found
        uint256 matrixTokenValuation = _controller.getMatrixValuer().calculateMatrixTokenValuation(matrixToken, reserveAsset);
        uint256 totalRedeemValueInPreciseUnits = matrixTokenQuantity.preciseMul(matrixTokenValuation);

        // Get reserve asset decimals
        uint256 reserveAssetDecimals = ERC20(reserveAsset).decimals();
        uint256 prePremiumReserveQuantity = totalRedeemValueInPreciseUnits.preciseMul(10**reserveAssetDecimals);
        uint256 premiumPercentage = _getRedeemPremium(matrixToken, reserveAsset, matrixTokenQuantity);
        uint256 premiumQuantity = prePremiumReserveQuantity.preciseMulCeil(premiumPercentage);

        return prePremiumReserveQuantity - premiumQuantity;
    }

    /**
     * @dev The new position multiplier is calculated as follows:
     * inflationPercentage = (newSupply - oldSupply) / newSupply
     * newMultiplier = (1 - inflationPercentage) * positionMultiplier = oldSupply * positionMultiplier / newSupply
     */
    function _getIssuePositionMultiplier(IMatrixToken matrixToken, ActionInfo memory issueInfo) internal view returns (uint256, int256) {
        // Calculate inflation and new position multiplier. Note: Round inflation up in order to round position multiplier down
        uint256 newTotalSupply = issueInfo.matrixTokenQuantity + issueInfo.previousMatrixTokenSupply;
        int256 newPositionMultiplier = (issueInfo.previousMatrixTokenSupply.toInt256() * matrixToken.getPositionMultiplier()) / newTotalSupply.toInt256();

        return (newTotalSupply, newPositionMultiplier);
    }

    /**
     * @dev Calculate deflation and new position multiplier. The new position multiplier is calculated as follows:
     * deflationPercentage = (oldSupply - newSupply) / newSupply
     * newMultiplier = (1 + deflationPercentage) * positionMultiplier = oldSupply * positionMultiplier / newSupply
     *
     * @notice Round deflation down in order to round position multiplier down
     */
    function _getRedeemPositionMultiplier(
        IMatrixToken matrixToken,
        uint256 matrixTokenQuantity,
        ActionInfo memory redeemInfo
    ) internal view returns (uint256, int256) {
        uint256 newTotalSupply = redeemInfo.previousMatrixTokenSupply - matrixTokenQuantity;
        int256 newPositionMultiplier = (matrixToken.getPositionMultiplier() * redeemInfo.previousMatrixTokenSupply.toInt256()) / newTotalSupply.toInt256();

        return (newTotalSupply, newPositionMultiplier);
    }

    /**
     * @dev The new position reserve asset unit is calculated as follows:
     * totalReserve = (oldUnit * oldMatrixTokenSupply) + reserveQuantity
     * newUnit = totalReserve / newMatrixTokenSupply
     */
    function _getIssuePositionUnit(
        IMatrixToken matrixToken,
        address reserveAsset,
        ActionInfo memory issueInfo
    ) internal view returns (uint256) {
        uint256 existingUnit = matrixToken.getDefaultPositionRealUnit(reserveAsset).toUint256();
        uint256 totalReserve = existingUnit.preciseMul(issueInfo.previousMatrixTokenSupply) + issueInfo.netFlowQuantity;

        return totalReserve.preciseDiv(issueInfo.newMatrixTokenSupply);
    }

    /**
     * @dev The new position reserve asset unit is calculated as follows:
     * totalReserve = (oldUnit * oldMatrixTokenSupply) - reserveQuantityToSendOut
     * newUnit = totalReserve / newMatrixTokenSupply
     */
    function _getRedeemPositionUnit(
        IMatrixToken matrixToken,
        address reserveAsset,
        ActionInfo memory redeemInfo
    ) internal view returns (uint256) {
        uint256 existingUnit = matrixToken.getDefaultPositionRealUnit(reserveAsset).toUint256();
        uint256 totalExistingUnits = existingUnit.preciseMul(redeemInfo.previousMatrixTokenSupply);
        uint256 outflow = redeemInfo.netFlowQuantity + redeemInfo.protocolFees + redeemInfo.managerFee;

        // Require withdrawable quantity is greater than existing collateral
        require(totalExistingUnits >= outflow, "N11"); // "Must be greater than total available collateral"

        return (totalExistingUnits - outflow).preciseDiv(redeemInfo.newMatrixTokenSupply);
    }

    /**
     * @dev If a pre-issue hook has been configured, call the external-protocol contract. Pre-issue hook logic
     * can contain arbitrary logic including validations, external function calls, etc.
     */
    function _callPreIssueHooks(
        IMatrixToken matrixToken,
        address reserveAsset,
        uint256 reserveAssetQuantity,
        address caller,
        address to
    ) internal {
        INavIssuanceHook preIssueHook = _issuanceSettings[matrixToken].managerIssuanceHook;

        if (address(preIssueHook) != address(0)) {
            preIssueHook.invokePreIssueHook(matrixToken, reserveAsset, reserveAssetQuantity, caller, to);
        }
    }

    /**
     * @dev If a pre-redeem hook has been configured, call the external-protocol contract.
     */
    function _callPreRedeemHooks(
        IMatrixToken matrixToken,
        uint256 setQuantity,
        address caller,
        address to
    ) internal {
        INavIssuanceHook preRedeemHook = _issuanceSettings[matrixToken].managerRedemptionHook;

        if (address(preRedeemHook) != address(0)) {
            preRedeemHook.invokePreRedeemHook(matrixToken, setQuantity, caller, to);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title ExactSafeErc20
 *
 * @dev Utility functions for ERC20 transfers that require the explicit amount to be transferred.
 */
library ExactSafeErc20 {
    using SafeERC20 for IERC20;

    // ==================== Internal functions ====================

    /**
     * Ensures that the recipient has received the correct quantity (ie no fees taken on transfer)
     */
    function exactSafeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            uint256 oldBalance = token.balanceOf(to);
            token.safeTransfer(to, amount);
            uint256 newBalance = token.balanceOf(to);
            require(newBalance == oldBalance + amount, "ES0"); // "Invalid post transfer balance"
        }
    }

    /**
     * Ensures that the recipient has received the correct quantity (ie no fees taken on transfer)
     */
    function exactSafeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            uint256 oldBalance = token.balanceOf(to);
            token.safeTransferFrom(from, to, amount);

            if (from != to) {
                require(token.balanceOf(to) == oldBalance + amount, "ES1"); // "Invalid post transfer balance"
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title PreciseUnitMath
 *
 * @dev Arithmetic for fixed-point numbers with 18 decimals of precision.
 */
library PreciseUnitMath {
    // ==================== Constants ====================

    // The number One in precise units
    uint256 internal constant PRECISE_UNIT = 10**18;
    int256 internal constant PRECISE_UNIT_INT = 10**18;

    // Max unsigned integer value
    uint256 internal constant MAX_UINT_256 = type(uint256).max;

    // Max and min signed integer value
    int256 internal constant MAX_INT_256 = type(int256).max;
    int256 internal constant MIN_INT_256 = type(int256).min;

    // ==================== Internal functions ====================

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnit() internal pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnitInt() internal pure returns (int256) {
        return PRECISE_UNIT_INT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxUint256() internal pure returns (uint256) {
        return MAX_UINT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxInt256() internal pure returns (int256) {
        return MAX_INT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function minInt256() internal pure returns (int256) {
        return MIN_INT_256;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded down).
     * It's assumed that the value b is the significand of a number with 18 decimals precision.
     */
    function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / PRECISE_UNIT;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded towards zero).
     * It's assumed that the value b is the significand of a number with 18 decimals precision.
     */
    function preciseMul(int256 a, int256 b) internal pure returns (int256) {
        return (a * b) / PRECISE_UNIT_INT;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded up).
     * It's assumed that the value b is the significand of a number with 18 decimals precision.
     */
    function preciseMulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        return (product == 0) ? 0 : ((product - 1) / PRECISE_UNIT + 1);
    }

    /**
     * @dev Divides value a by value b (result is rounded down).
     */
    function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "PM0");

        return (a * PRECISE_UNIT) / b;
    }

    /**
     * @dev Divides value a by value b (result is rounded towards 0).
     */
    function preciseDiv(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "PM1");

        return (a * PRECISE_UNIT_INT) / b;
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0).
     */
    function preciseDivCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "PM2");

        return a > 0 ? ((a * PRECISE_UNIT - 1) / b + 1) : 0;
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0).
     * return 0 when `a` is 0.reverts when `b` is 0.
     */
    function preciseDivCeil(int256 a, int256 b) internal pure returns (int256 result) {
        require(b != 0, "PM3");

        a *= PRECISE_UNIT_INT;
        result = a / b;

        if (a % b != 0) {
            (a ^ b >= 0) ? ++result : --result;
        }
    }

    /**
     * @dev Multiplies value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function preciseMulFloor(int256 a, int256 b) internal pure returns (int256 result) {
        int256 product = a * b;
        result = product / PRECISE_UNIT_INT;

        if ((product < 0) && (product % PRECISE_UNIT_INT != 0)) {
            --result;
        }
    }

    /**
     * @dev Divides value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function preciseDivFloor(int256 a, int256 b) internal pure returns (int256 result) {
        require(b != 0, "PM4");

        int256 numerator = a * PRECISE_UNIT_INT;
        result = numerator / b; // not check overflow: numerator == MIN_INT_256 && b == -1

        if ((numerator ^ b < 0) && (numerator % b != 0)) {
            --result;
        }
    }

    /**
     * @dev Returns true if a =~ b within range, false otherwise.
     */
    function approximatelyEquals(
        uint256 a,
        uint256 b,
        uint256 range
    ) internal pure returns (bool) {
        if (a >= b) {
            return a - b <= range;
        } else {
            return b - a <= range;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title AddressArrayUtil
 *
 * @dev Utility functions to handle address arrays
 */
library AddressArrayUtil {
    // ==================== Internal functions ====================

    /**
     * @dev Returns true if there are 2 same elements in an array
     *
     * @param array The input array to search
     */
    function hasDuplicate(address[] memory array) internal pure returns (bool) {
        if (array.length > 1) {
            uint256 lastIndex = array.length - 1;
            for (uint256 i = 0; i < lastIndex; i++) {
                address value = array[i];
                for (uint256 j = i + 1; j < array.length; j++) {
                    if (value == array[j]) {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    /**
     * @dev Finds the index of the first occurrence of the given element.
     *
     * @param array     The input array to search
     * @param value     The value to find
     *
     * @return index    The first occurrence starting from 0
     * @return found    True if find
     */
    function indexOf(address[] memory array, address value) internal pure returns (uint256 index, bool found) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return (i, true);
            }
        }

        return (type(uint256).max, false);
    }

    /**
     * @dev Check if the value is in the list.
     *
     * @param array    The input array to search
     * @param value    The value to find
     *
     * @return found   True if find
     */
    function contain(address[] memory array, address value) internal pure returns (bool found) {
        (, found) = indexOf(array, value);
    }

    /**
     * @param array    The input array to search
     * @param value    The address to remove
     *
     * @return result  the array with the object removed.
     */
    function removeValue(address[] memory array, address value) internal pure returns (address[] memory result) {
        (uint256 index, bool found) = indexOf(array, value);
        require(found, "A0");

        result = new address[](array.length - 1);

        for (uint256 i = 0; i < index; i++) {
            result[i] = array[i];
        }

        for (uint256 i = index + 1; i < array.length; i++) {
            result[index] = array[i];
            index = i;
        }
    }

    /**
     * @param array    The input array to search
     * @param item     The address to remove
     */
    function removeItem(address[] storage array, address item) internal {
        (uint256 index, bool found) = indexOf(array, item);
        require(found, "A1");

        for (uint256 right = index + 1; right < array.length; right++) {
            array[index] = array[right];
            index = right;
        }

        array.pop();
    }

    /**
     * @param array    The input array to search
     * @param item     The address to remove
     */
    function quickRemoveItem(address[] storage array, address item) internal {
        (uint256 index, bool found) = indexOf(array, item);
        require(found, "A2");

        array[index] = array[array.length - 1];
        array.pop();
    }

    /**
     * @dev Returns the combination of the two arrays
     *
     * @param array1    The first array
     * @param array2    The second array
     *
     * @return result   A extended by B
     */
    function merge(address[] memory array1, address[] memory array2) internal pure returns (address[] memory result) {
        result = new address[](array1.length + array2.length);

        for (uint256 i = 0; i < array1.length; i++) {
            result[i] = array1[i];
        }

        uint256 index = array1.length;
        for (uint256 j = 0; j < array2.length; j++) {
            result[index++] = array2[j];
        }
    }

    /**
     * @dev Validate that address and uint array lengths match. Validate address array is not empty and contains no duplicate elements.
     *
     * @param array1    Array of addresses
     * @param array2    Array of uint
     */
    function validateArrayPairs(address[] memory array1, uint256[] memory array2) internal pure {
        require(array1.length == array2.length, "A3");
        _validateLengthAndUniqueness(array1);
    }

    /**
     * @dev Validate that address and bool array lengths match. Validate address array is not empty and contains no duplicate elements.
     *
     * @param array1    Array of addresses
     * @param array2    Array of bool
     */
    function validateArrayPairs(address[] memory array1, bool[] memory array2) internal pure {
        require(array1.length == array2.length, "A4");
        _validateLengthAndUniqueness(array1);
    }

    /**
     * @dev Validate that address and string array lengths match. Validate address array is not empty and contains no duplicate elements.
     *
     * @param array1    Array of addresses
     * @param array2    Array of strings
     */
    function validateArrayPairs(address[] memory array1, string[] memory array2) internal pure {
        require(array1.length == array2.length, "A5");
        _validateLengthAndUniqueness(array1);
    }

    /**
     * @dev Validate that address array lengths match, and calling address array are not empty and contain no duplicate elements.
     *
     * @param array1    Array of addresses
     * @param array2    Array of addresses
     */
    function validateArrayPairs(address[] memory array1, address[] memory array2) internal pure {
        require(array1.length == array2.length, "A6");
        _validateLengthAndUniqueness(array1);
    }

    /**
     * @dev Validate that address and bytes array lengths match. Validate address array is not empty and contains no duplicate elements.
     *
     * @param array1    Array of addresses
     * @param array2    Array of bytes
     */
    function validateArrayPairs(address[] memory array1, bytes[] memory array2) internal pure {
        require(array1.length == array2.length, "A7");
        _validateLengthAndUniqueness(array1);
    }

    /**
     * @dev Validate address array is not empty and contains no duplicate elements.
     *
     * @param array    Array of addresses
     */
    function _validateLengthAndUniqueness(address[] memory array) internal pure {
        require(array.length > 0, "A8a");
        require(!hasDuplicate(array), "A8b");
    }

    /**
     * @dev assume both of array1 and array2 has no duplicate items
     */
    function equal(address[] memory array1, address[] memory array2) internal pure returns (bool) {
        if (array1.length != array2.length) {
            return false;
        }

        for (uint256 i = 0; i < array1.length; i++) {
            if (!contain(array2, array1[i])) {
                return false;
            }
        }

        return true;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

// ==================== Internal Imports ====================

import { ExactSafeErc20 } from "../../lib/ExactSafeErc20.sol";
import { PreciseUnitMath } from "../../lib/PreciseUnitMath.sol";
import { AddressArrayUtil } from "../../lib/AddressArrayUtil.sol";

import { IModule } from "../../interfaces/IModule.sol";
import { IController } from "../../interfaces/IController.sol";
import { IMatrixToken } from "../../interfaces/IMatrixToken.sol";

import { PositionUtil } from "./PositionUtil.sol";

/**
 * @title ModuleBase
 *
 * @dev Abstract class that houses common Module-related state and functions.
 */
abstract contract ModuleBase is IModule {
    using SafeCast for int256;
    using SafeCast for uint256;
    using ExactSafeErc20 for IERC20;
    using PreciseUnitMath for uint256;
    using AddressArrayUtil for address[];
    using PositionUtil for IMatrixToken;

    // ==================== Variables ====================

    IController internal immutable _controller;

    // ==================== Constructor function ====================

    constructor(IController controller) {
        _controller = controller;
    }

    // ==================== Modifier functions ====================

    modifier onlyManagerAndValidMatrix(IMatrixToken matrixToken) {
        _onlyManagerAndValidMatrix(matrixToken);
        _;
    }

    modifier onlyMatrixManager(IMatrixToken matrixToken, address caller) {
        _onlyMatrixManager(matrixToken, caller);
        _;
    }

    modifier onlyValidAndInitializedMatrix(IMatrixToken matrixToken) {
        _onlyValidAndInitializedMatrix(matrixToken);
        _;
    }

    modifier onlyModule(IMatrixToken matrixToken) {
        _onlyModule(matrixToken);
        _;
    }

    /**
     * @dev Utilized during module initializations to check that the module is in pending state and that the MatrixToken is valid.
     */
    modifier onlyValidAndPendingMatrix(IMatrixToken matrixToken) {
        _onlyValidAndPendingMatrix(matrixToken);
        _;
    }

    // ==================== External functions ====================

    function getController() external view returns (address) {
        return address(_controller);
    }

    // ==================== Internal functions ====================

    /**
     * @dev Transfers tokens from an address (that has set allowance on the module).
     *
     * @param token       The address of the ERC20 token
     * @param from        The address to transfer from
     * @param to          The address to transfer to
     * @param quantity    The number of tokens to transfer
     */
    function transferFrom(IERC20 token, address from, address to, uint256 quantity) internal {
        token.exactSafeTransferFrom(from, to, quantity);
    } // prettier-ignore

    /**
     * @dev Hashes the string and returns a bytes32 value.
     */
    function getNameHash(string memory name) internal pure returns (bytes32) {
        return keccak256(bytes(name));
    }

    /**
     * @return The integration for the module with the passed in name.
     */
    function getAndValidateAdapter(string memory integrationName) internal view returns (address) {
        bytes32 integrationHash = getNameHash(integrationName);
        return getAndValidateAdapterWithHash(integrationHash);
    }

    /**
     * @return The integration for the module with the passed in hash.
     */
    function getAndValidateAdapterWithHash(bytes32 integrationHash) internal view returns (address) {
        address adapter = _controller.getIntegrationRegistry().getIntegrationAdapterWithHash(address(this), integrationHash);

        require(adapter != address(0), "M0"); // "Must be valid adapter"

        return adapter;
    }

    /**
     * @return The total fee for this module of the passed in index (fee % * quantity).
     */
    function getModuleFee(uint256 feeIndex, uint256 quantity) internal view returns (uint256) {
        uint256 feePercentage = _controller.getModuleFee(address(this), feeIndex);
        return quantity.preciseMul(feePercentage);
    }

    /**
     * @dev Pays the feeQuantity from the matrixToken denominated in token to the protocol fee recipient.
     */
    function payProtocolFeeFromMatrixToken(IMatrixToken matrixToken, address token, uint256 feeQuantity) internal {
        if (feeQuantity > 0) {
            matrixToken.invokeExactSafeTransfer(token, _controller.getFeeRecipient(), feeQuantity);
        }
    } // prettier-ignore

    /**
     * @return Whether the module is in process of initialization on the MatrixToken.
     */
    function isMatrixPendingInitialization(IMatrixToken matrixToken) internal view returns (bool) {
        return matrixToken.isPendingModule(address(this));
    }

    /**
     * @return Whether the address is the MatrixToken's manager.
     */
    function isMatrixManager(IMatrixToken matrixToken, address addr) internal view returns (bool) {
        return matrixToken.getManager() == addr;
    }

    /**
     * @return Whether MatrixToken must be enabled on the controller and module is registered on the MatrixToken.
     */
    function isMatrixValidAndInitialized(IMatrixToken matrixToken) internal view returns (bool) {
        return _controller.isMatrix(address(matrixToken)) && matrixToken.isInitializedModule(address(this));
    }

    // ==================== Private functions ====================

    /**
     * @notice Caller must be MatrixToken manager and MatrixToken must be valid and initialized.
     */
    function _onlyManagerAndValidMatrix(IMatrixToken matrixToken) private view {
        require(isMatrixManager(matrixToken, msg.sender), "M1a"); // "Must be the MatrixToken manager"
        require(isMatrixValidAndInitialized(matrixToken), "M1b"); // "Must be a valid and initialized MatrixToken"
    }

    /**
     * @notice Caller must be MatrixToken manager.
     */
    function _onlyMatrixManager(IMatrixToken matrixToken, address caller) private view {
        require(isMatrixManager(matrixToken, caller), "M2"); // "Must be the MatrixToken manager"
    }

    /**
     * @notice MatrixToken must be valid and initialized.
     */
    function _onlyValidAndInitializedMatrix(IMatrixToken matrixToken) private view {
        require(isMatrixValidAndInitialized(matrixToken), "M3"); // "Must be a valid and initialized MatrixToken"
    }

    /**
     * @notice Caller must be initialized module and module must be enabled on the controller.
     */
    function _onlyModule(IMatrixToken matrixToken) private view {
        require(matrixToken.getModuleState(msg.sender) == IMatrixToken.ModuleState.INITIALIZED, "M4a"); // "Only the module can call"
        require(_controller.isModule(msg.sender), "M4b"); // "Module must be enabled on controller"
    }

    /**
     * @dev MatrixToken must be in a pending state and module must be in pending state.
     */
    function _onlyValidAndPendingMatrix(IMatrixToken matrixToken) private view {
        require(_controller.isMatrix(address(matrixToken)), "M5a"); // "Must be controller-enabled MatrixToken"
        require(isMatrixPendingInitialization(matrixToken), "M5b"); // "Must be pending initialization"
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

// ==================== Internal Imports ====================

import { PreciseUnitMath } from "../../lib/PreciseUnitMath.sol";
import { IMatrixToken } from "../../interfaces/IMatrixToken.sol";

/**
 * @title PositionUtil
 *
 * @dev Collection of helper functions for handling and updating MatrixToken Positions.
 */
library PositionUtil {
    using SafeCast for uint256;
    using SafeCast for int256;
    using PreciseUnitMath for uint256;

    // ==================== Internal functions ====================

    /**
     * @return Whether the MatrixToken has a default position for a given component (if the real unit is > 0)
     */
    function hasDefaultPosition(IMatrixToken matrixToken, address component) internal view returns (bool) {
        return matrixToken.getDefaultPositionRealUnit(component) > 0;
    }

    /**
     * @return Whether the MatrixToken has an external position for a given component (if # of position modules is > 0)
     */
    function hasExternalPosition(IMatrixToken matrixToken, address component) internal view returns (bool) {
        return matrixToken.getExternalPositionModules(component).length > 0;
    }

    /**
     * @return Whether the MatrixToken component default position real unit is greater than or equal to units passed in.
     */
    function hasSufficientDefaultUnits(
        IMatrixToken matrixToken,
        address component,
        uint256 unit
    ) internal view returns (bool) {
        return matrixToken.getDefaultPositionRealUnit(component) >= unit.toInt256();
    }

    /**
     * @return Whether the MatrixToken component external position is greater than or equal to the real units passed in.
     */
    function hasSufficientExternalUnits(
        IMatrixToken matrixToken,
        address component,
        address positionModule,
        uint256 unit
    ) internal view returns (bool) {
        return matrixToken.getExternalPositionRealUnit(component, positionModule) >= unit.toInt256();
    }

    /**
     * @dev If the position does not exist, create a new Position and add to the MatrixToken. If it already exists,
     * then set the position units. If the new units is 0, remove the position. Handles adding/removing of
     * components where needed (in light of potential external positions).
     *
     * @param matrixToken    Address of MatrixToken being modified
     * @param component      Address of the component
     * @param newUnit        Quantity of Position units - must be >= 0
     */
    function editDefaultPosition(
        IMatrixToken matrixToken,
        address component,
        uint256 newUnit
    ) internal {
        bool isPositionFound = hasDefaultPosition(matrixToken, component);
        if (!isPositionFound && newUnit > 0) {
            // If there is no Default Position and no External Modules, then component does not exist
            if (!hasExternalPosition(matrixToken, component)) {
                matrixToken.addComponent(component);
            }
        } else if (isPositionFound && newUnit == 0) {
            // If there is a Default Position and no external positions, remove the component
            if (!hasExternalPosition(matrixToken, component)) {
                matrixToken.removeComponent(component);
            }
        }

        matrixToken.editDefaultPositionUnit(component, newUnit.toInt256());
    }

    /**
     * @dev Update an external position and remove and external positions or components if necessary. The logic flows as follows:
     * 1) If component is not already added then add component and external position.
     * 2) If component is added but no existing external position using the passed module exists then add the external position.
     * 3) If the existing position is being added to then just update the unit and data
     * 4) If the position is being closed and no other external positions or default positions are associated with the component then untrack the component and remove external position.
     * 5) If the position is being closed and other existing positions still exist for the component then just remove the external position.
     *
     * @param matrixToken    MatrixToken being updated
     * @param component      Component position being updated
     * @param module         Module external position is associated with
     * @param newUnit        Position units of new external position
     * @param data           Arbitrary data associated with the position
     */
    function editExternalPosition(
        IMatrixToken matrixToken,
        address component,
        address module,
        int256 newUnit,
        bytes memory data
    ) internal {
        if (newUnit != 0) {
            if (!matrixToken.isComponent(component)) {
                matrixToken.addComponent(component);
                matrixToken.addExternalPositionModule(component, module);
            } else if (!matrixToken.isExternalPositionModule(component, module)) {
                matrixToken.addExternalPositionModule(component, module);
            }

            matrixToken.editExternalPositionUnit(component, module, newUnit);
            matrixToken.editExternalPositionData(component, module, data);
        } else {
            require(data.length == 0, "P0a"); // "Passed data must be null"

            // If no default or external position remaining then remove component from components array
            if (matrixToken.getExternalPositionRealUnit(component, module) != 0) {
                address[] memory positionModules = matrixToken.getExternalPositionModules(component);

                if (matrixToken.getDefaultPositionRealUnit(component) == 0 && positionModules.length == 1) {
                    require(positionModules[0] == module, "P0b"); // "External positions must be 0 to remove component")
                    matrixToken.removeComponent(component);
                }

                matrixToken.removeExternalPositionModule(component, module);
            }
        }
    }

    /**
     * @dev Get total notional amount of Default position
     *
     * @param matrixTokenSupply    Supply of MatrixToken in precise units (10^18)
     * @param positionUnit         Quantity of Position units
     *
     * @return uint256             Total notional amount of units
     */
    function getDefaultTotalNotional(uint256 matrixTokenSupply, uint256 positionUnit) internal pure returns (uint256) {
        return matrixTokenSupply.preciseMul(positionUnit);
    }

    /**
     * @dev Get position unit from total notional amount
     *
     * @param matrixTokenSupply    Supply of MatrixToken in precise units (10^18)
     * @param totalNotional        Total notional amount of component prior to
     *
     * @return uint256             Default position unit
     */
    function getDefaultPositionUnit(uint256 matrixTokenSupply, uint256 totalNotional) internal pure returns (uint256) {
        return totalNotional.preciseDiv(matrixTokenSupply);
    }

    /**
     * @dev Get the total tracked balance - total supply * position unit
     *
     * @param matrixToken    Address of the MatrixToken
     * @param component      Address of the component
     *
     * @return uint256       Notional tracked balance
     */
    function getDefaultTrackedBalance(IMatrixToken matrixToken, address component) internal view returns (uint256) {
        int256 positionUnit = matrixToken.getDefaultPositionRealUnit(component);

        return matrixToken.totalSupply().preciseMul(positionUnit.toUint256());
    }

    /**
     * @dev Calculates the new default position unit and performs the edit with the new unit
     *
     * @param matrixToken                 Address of the MatrixToken
     * @param component                   Address of the component
     * @param matrixTotalSupply           Current MatrixToken supply
     * @param componentPreviousBalance    Pre-action component balance
     *
     * @return uint256                    Current component balance
     * @return uint256                    Previous position unit
     * @return uint256                    New position unit
     */
    function calculateAndEditDefaultPosition(
        IMatrixToken matrixToken,
        address component,
        uint256 matrixTotalSupply,
        uint256 componentPreviousBalance
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 currentBalance = IERC20(component).balanceOf(address(matrixToken));
        uint256 positionUnit = matrixToken.getDefaultPositionRealUnit(component).toUint256();

        uint256 newTokenUnit;
        if (currentBalance > 0) {
            newTokenUnit = calculateDefaultEditPositionUnit(matrixTotalSupply, componentPreviousBalance, currentBalance, positionUnit);
        } else {
            newTokenUnit = 0;
        }

        editDefaultPosition(matrixToken, component, newTokenUnit);

        return (currentBalance, positionUnit, newTokenUnit);
    }

    /**
     * @dev Calculate the new position unit given total notional values pre and post executing an action that changes MatrixToken state.
     * The intention is to make updates to the units without accidentally picking up airdropped assets as well.
     *
     * @param matrixTokenSupply    Supply of MatrixToken in precise units (10^18)
     * @param preTotalNotional     Total notional amount of component prior to executing action
     * @param postTotalNotional    Total notional amount of component after the executing action
     * @param prePositionUnit      Position unit of MatrixToken prior to executing action
     *
     * @return uint256             New position unit
     */
    function calculateDefaultEditPositionUnit(
        uint256 matrixTokenSupply,
        uint256 preTotalNotional,
        uint256 postTotalNotional,
        uint256 prePositionUnit
    ) internal pure returns (uint256) {
        // If pre action total notional amount is greater then subtract post action total notional and calculate new position units
        uint256 airdroppedAmount = preTotalNotional - prePositionUnit.preciseMul(matrixTokenSupply);

        return (postTotalNotional - airdroppedAmount).preciseDiv(matrixTokenSupply);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IWETH
 *
 * @dev This interface allows for interaction for wrapped ether's deposit and withdrawal functionality.
 */
interface IWETH is IERC20 {
    // ==================== External functions ====================

    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== Internal Imports ====================

import { IPriceOracle } from "../interfaces/IPriceOracle.sol";
import { IMatrixValuer } from "../interfaces/IMatrixValuer.sol";
import { IIntegrationRegistry } from "../interfaces/IIntegrationRegistry.sol";

/**
 * @title IController
 */
interface IController {
    // ==================== Events ====================

    event AddFactory(address indexed factory);
    event RemoveFactory(address indexed factory);
    event AddFee(address indexed module, uint256 indexed feeType, uint256 feePercentage);
    event EditFee(address indexed module, uint256 indexed feeType, uint256 feePercentage);
    event EditFeeRecipient(address newFeeRecipient);
    event AddModule(address indexed module);
    event RemoveModule(address indexed module);
    event AddResource(address indexed resource, uint256 id);
    event RemoveResource(address indexed resource, uint256 id);
    event AddMatrix(address indexed matrixToken, address indexed factory);
    event RemoveMatrix(address indexed matrixToken);

    // ==================== External functions ====================

    function isMatrix(address matrixToken) external view returns (bool);

    function isFactory(address addr) external view returns (bool);

    function isModule(address addr) external view returns (bool);

    function isResource(address addr) external view returns (bool);

    function isSystemContract(address contractAddress) external view returns (bool);

    function getFeeRecipient() external view returns (address);

    function getModuleFee(address module, uint256 feeType) external view returns (uint256);

    function getFactories() external view returns (address[] memory);

    function getModules() external view returns (address[] memory);

    function getResources() external view returns (address[] memory);

    function getResource(uint256 id) external view returns (address);

    function getMatrixs() external view returns (address[] memory);

    function getIntegrationRegistry() external view returns (IIntegrationRegistry);

    function getPriceOracle() external view returns (IPriceOracle);

    function getMatrixValuer() external view returns (IMatrixValuer);

    function initialize(
        address[] memory factories,
        address[] memory modules,
        address[] memory resources,
        uint256[] memory resourceIds
    ) external;

    function addMatrix(address matrixToken) external;

    function removeMatrix(address matrixToken) external;

    function addFactory(address factory) external;

    function removeFactory(address factory) external;

    function addModule(address module) external;

    function removeModule(address module) external;

    function addResource(address resource, uint256 id) external;

    function removeResource(uint256 id) external;

    function addFee(
        address module,
        uint256 feeType,
        uint256 newFeePercentage
    ) external;

    function editFee(
        address module,
        uint256 feeType,
        uint256 newFeePercentage
    ) external;

    function editFeeRecipient(address newFeeRecipient) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== External Imports ====================

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IMatrixToken
 */
interface IMatrixToken is IERC20 {
    // ==================== Enums ====================

    enum ModuleState {
        NONE,
        PENDING,
        INITIALIZED
    }

    // ==================== Structs ====================

    /**
     * @dev The base definition of a MatrixToken Position
     *
     * @param unit             Each unit is the # of components per 10^18 of a MatrixToken
     * @param module           If not in default state, the address of associated module
     * @param component        Address of token in the Position
     * @param positionState    Position ENUM. Default is 0; External is 1
     * @param data             Arbitrary data
     */
    struct Position {
        int256 unit;
        address module;
        address component;
        uint8 positionState;
        bytes data;
    }

    /**
     * @dev A struct that stores a component's external position details including virtual unit and any auxiliary data.
     *
     * @param virtualUnit    Virtual value of a component's EXTERNAL position.
     * @param data           Arbitrary data
     */
    struct ExternalPosition {
        int256 virtualUnit;
        bytes data;
    }

    /**
     * @dev A struct that stores a component's cash position details and external positions
     * This data structure allows O(1) access to a component's cash position units and  virtual units.
     *
     * @param virtualUnit                Virtual value of a component's DEFAULT position. Stored as virtual for efficiency updating all units
     *                                   at once via the position multiplier. Virtual units are achieved by dividing a real value by the positionMultiplier
     * @param externalPositionModules    Eexternal modules attached to each external position. Each module maps to an external position
     * @param externalPositions          Mapping of module => ExternalPosition struct for a given component
     */
    struct ComponentPosition {
        int256 virtualUnit;
        address[] externalPositionModules;
        mapping(address => ExternalPosition) externalPositions;
    }

    // ==================== Events ====================

    event Invoke(address indexed target, uint256 indexed value, bytes data, bytes returnValue);
    event AddModule(address indexed module);
    event RemoveModule(address indexed module);
    event InitializeModule(address indexed module);
    event EditManager(address newManager, address oldManager);
    event RemovePendingModule(address indexed module);
    event EditPositionMultiplier(int256 newMultiplier);
    event AddComponent(address indexed component);
    event RemoveComponent(address indexed component);
    event EditDefaultPositionUnit(address indexed component, int256 realUnit);
    event EditExternalPositionUnit(address indexed component, address indexed positionModule, int256 realUnit);
    event EditExternalPositionData(address indexed component, address indexed positionModule, bytes data);
    event AddPositionModule(address indexed component, address indexed positionModule);
    event RemovePositionModule(address indexed component, address indexed positionModule);

    // ==================== External functions ====================

    function getController() external view returns (address);

    function getManager() external view returns (address);

    function getLocker() external view returns (address);

    function getComponents() external view returns (address[] memory);

    function getModules() external view returns (address[] memory);

    function getModuleState(address module) external view returns (ModuleState);

    function getPositionMultiplier() external view returns (int256);

    function getPositions() external view returns (Position[] memory);

    function getTotalComponentRealUnits(address component) external view returns (int256);

    function getDefaultPositionRealUnit(address component) external view returns (int256);

    function getExternalPositionRealUnit(address component, address positionModule) external view returns (int256);

    function getExternalPositionModules(address component) external view returns (address[] memory);

    function getExternalPositionData(address component, address positionModule) external view returns (bytes memory);

    function isExternalPositionModule(address component, address module) external view returns (bool);

    function isComponent(address component) external view returns (bool);

    function isInitializedModule(address module) external view returns (bool);

    function isPendingModule(address module) external view returns (bool);

    function isLocked() external view returns (bool);

    function setManager(address manager) external;

    function addComponent(address component) external;

    function removeComponent(address component) external;

    function editDefaultPositionUnit(address component, int256 realUnit) external;

    function addExternalPositionModule(address component, address positionModule) external;

    function removeExternalPositionModule(address component, address positionModule) external;

    function editExternalPositionUnit(
        address component,
        address positionModule,
        int256 realUnit
    ) external;

    function editExternalPositionData(
        address component,
        address positionModule,
        bytes calldata data
    ) external;

    function invoke(
        address target,
        uint256 value,
        bytes calldata data
    ) external returns (bytes memory);

    function invokeSafeIncreaseAllowance(
        address token,
        address spender,
        uint256 amount
    ) external;

    function invokeSafeTransfer(
        address token,
        address to,
        uint256 amount
    ) external;

    function invokeExactSafeTransfer(
        address token,
        address to,
        uint256 amount
    ) external;

    function invokeWrapWETH(address weth, uint256 amount) external;

    function invokeUnwrapWETH(address weth, uint256 amount) external;

    function editPositionMultiplier(int256 newMultiplier) external;

    function mint(address account, uint256 quantity) external;

    function burn(address account, uint256 quantity) external;

    function lock() external;

    function unlock() external;

    function addModule(address module) external;

    function removeModule(address module) external;

    function initializeModule() external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// ==================== Internal Imports ====================

import { IMatrixToken } from "./IMatrixToken.sol";

/**
 * @title INavIssuanceHook
 */
interface INavIssuanceHook {
    // ==================== External functions ====================

    function invokePreIssueHook(IMatrixToken matrixToken, address reserveAsset, uint256 reserveAssetQuantity, address sender, address to) external; // prettier-ignore

    function invokePreRedeemHook(IMatrixToken matrixToken, uint256 redeemQuantity, address sender, address to) external; // prettier-ignore
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IModule
 *
 * @dev Interface for interacting with Modules.
 */
interface IModule {
    // ==================== External functions ====================

    /**
     * @dev Called by a MatrixToken to notify that this module was removed from the MatrixToken.
     * Any logic can be included in case checks need to be made or state needs to be cleared.
     */
    function removeModule() external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IPriceOracle
 */
interface IPriceOracle {
    // ==================== Events ====================

    event AddPair(address indexed asset1, address indexed asset2, address indexed oracle);
    event RemovePair(address indexed asset1, address indexed asset2, address indexed oracle);
    event EditPair(address indexed asset1, address indexed asset2, address indexed newOracle);
    event AddAdapter(address indexed adapter);
    event RemoveAdapter(address indexed adapter);
    event EditMasterQuoteAsset(address indexed newMasterQuote);
    event EditSecondQuoteAsset(address indexed newSecondQuote);

    // ==================== External functions ====================

    function getController() external view returns (address);

    function getOracle(address asset1, address asset2) external view returns (address);

    function getMasterQuoteAsset() external view returns (address);

    function getSecondQuoteAsset() external view returns (address);

    function getAdapters() external view returns (address[] memory);

    function getPrice(address asset1, address asset2) external view returns (uint256);

    function addPair(
        address asset1,
        address asset2,
        address oracle
    ) external;

    function editPair(
        address asset1,
        address asset2,
        address oracle
    ) external;

    function removePair(address asset1, address asset2) external;

    function addAdapter(address adapter) external;

    function removeAdapter(address adapter) external;

    function editMasterQuoteAsset(address newMasterQuoteAsset) external;

    function editSecondQuoteAsset(address newSecondQuoteAsset) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { IMatrixToken } from "../interfaces/IMatrixToken.sol";

/**
 * @title IMatrixValuer
 */
interface IMatrixValuer {
    // ==================== External functions ====================

    function calculateMatrixTokenValuation(IMatrixToken matrixToken, address quoteAsset) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/*
 * @title IIntegrationRegistry
 */
interface IIntegrationRegistry {
    // ==================== Events ====================

    event AddIntegration(address indexed module, address indexed adapter, string integrationName);
    event RemoveIntegration(address indexed module, address indexed adapter, string integrationName);
    event EditIntegration(address indexed module, address newAdapter, string integrationName);

    // ==================== External functions ====================

    function getIntegrationAdapter(address module, string memory id) external view returns (address);

    function getIntegrationAdapterWithHash(address module, bytes32 id) external view returns (address);

    function isValidIntegration(address module, string memory id) external view returns (bool);

    function addIntegration(address module, string memory id, address wrapper) external; // prettier-ignore

    function batchAddIntegration(address[] memory modules, string[] memory names, address[] memory adapters) external; // prettier-ignore

    function editIntegration(address module, string memory name, address adapter) external; // prettier-ignore

    function batchEditIntegration(address[] memory modules, string[] memory names, address[] memory adapters) external; // prettier-ignore

    function removeIntegration(address module, string memory name) external;
}