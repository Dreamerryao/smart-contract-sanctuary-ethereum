/**
 *Submitted for verification at Etherscan.io on 2021-09-03
*/

// Sources flattened with hardhat v2.6.1 https://hardhat.org

// File contracts/Enum.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Enum {
    enum GnosisSafeOperation {
        Call,
        DelegateCall
    }
}


// File contracts/interfaces/IGnosisSafe.sol

pragma solidity ^0.8.0;
interface IGnosisSafe {
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.GnosisSafeOperation operation
    ) external returns (bool success);

    function getOwners() external view returns (address[] memory);
}


// File contracts/libraries/Utils.sol

pragma solidity ^0.8.0;

library Utils {
   /**
   * @param fromToken Address of the source token
   * @param fromAmount Amount of source tokens to be swapped
   * @param toAmount Minimum destination token amount expected out of this swap
   * @param expectedAmount Expected amount of destination tokens without slippage
   * @param beneficiary Beneficiary address
   * 0 then 100% will be transferred to beneficiary. Pass 10000 for 100%
   * @param path Route to be taken for this swap to take place
   */
    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.Path[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct MegaSwapSellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.MegaSwapPath[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct SimpleData {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address[] callees;
        bytes exchangeData;
        uint256[] startIndexes;
        uint256[] values;
        address payable beneficiary;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct Adapter {
        address payable adapter;
        uint256 percent;
        uint256 networkFee;
        Route[] route;
    }

    struct Route {
        uint256 index; //Adapter at which index needs to be used
        address targetExchange;
        uint percent;
        bytes payload;
        uint256 networkFee; //Network fee is associated with 0xv3 trades
    }

    struct MegaSwapPath {
        uint256 fromAmountPercent;
        Path[] path;
    }

    struct Path {
        address to;
        uint256 totalNetworkFee; //Network fee is associated with 0xv3 trades
        Adapter[] adapters;
    }
}


// File contracts/interfaces/IERC20.sol

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}


// File contracts/interfaces/IAugustusSwapper.sol

pragma solidity ^0.8.0;

interface IAugustusSwapper {
    function getTokenTransferProxy() external view returns (address);
}


// File contracts/ScoreLabClientsGnosisSafeModule.sol

pragma solidity ^0.8.0;

//import "hardhat/console.sol";
contract ScoreLabClientsGnosisSafeModule {
    struct Allowance {
        uint256 amount;
        uint256 expiration;
    }

    event Deposit(address indexed safe, uint256 value);
    event Refund(address indexed safe, uint256 value);

    address public constant AUGUSTUS_SWAPPER =
        address(0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57); //ROPSTEN address
    //address public constant AUGUSTUS_SWAPPER = address(0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57); //MAINNET address

    mapping(address => bool) private _isAdmin;
    mapping(address => bool) private _isScoreLab;
    mapping(address => uint256) private _gasTanks;
    mapping(address => mapping(address => mapping(address => Allowance)))
        private _allowances;

    /**
      SL#01: admin only operation
      SL#02: ScoreLab only operation
      SL#03: admin cannot revoke itself
      SL#04: invalid token pair parameters
      SL#05: insufficient gas tank
      SL#06: unable to payback gas, recipient may have reverted
      SL#07: insufficient allowance
      SL#08: lapsed allowance
      SL#09: invalid beneficiary
      SL#10: swap failed
      SL#11: approve error
     */

    modifier onlyAdmin() {
        require(_isAdmin[msg.sender], "SL#01");
        _;
    }

    modifier onlyScoreLab() {
        require(_isScoreLab[msg.sender], "SL#02");
        _;
    }

    modifier onlyForSafe(address safe, address beneficiary) {
        require(beneficiary == safe, "SL#09");
        _;
    }

    constructor(address admin) {
        _isAdmin[admin] = true;
    }

    function deposit(address safe) external payable {
        _gasTanks[safe] += msg.value;

        emit Deposit(safe, msg.value);
    }

    function refund(
        address safe,
        uint256 value,
        address to
    ) external onlyScoreLab {
        require(_gasTanks[safe] >= value, "SL#05");
        (bool success, ) = to.call{value: value}("");
        require(success, "SL#06");
        _gasTanks[safe] -= value;

        emit Refund(safe, value);
    }

    function multiSwap(
        address safe,
        Utils.SellData calldata params
    )
        external
        payable
        onlyScoreLab
        onlyForSafe(safe, params.beneficiary)
        {
            _swap(
                safe,
                params.fromToken,
                params.path[0].to,
                params.fromAmount,
                abi.encodeWithSelector(0x5f4c5998, params)
            );

        }

    function megaSwap(
        address safe,
        Utils.MegaSwapSellData calldata params
    )
        external
        payable
        onlyScoreLab
        onlyForSafe(safe, params.beneficiary)
        {
            _swap(
                safe,
                params.fromToken,
                params.path[0].path[0].to,
                params.fromAmount,
                abi.encodeWithSelector(0x3b42c540, params)
            );
        }

    function protectedMultiSwap(
        address safe,
        Utils.SellData calldata params
    )
        external
        payable
        onlyScoreLab
        onlyForSafe(safe, params.beneficiary)
        {
            _swap(
                safe,
                params.fromToken,
                params.path[0].to,
                params.fromAmount,
                abi.encodeWithSelector(0xa5607ba3, params)
            );
        }

    function protectedMegaSwap(
        address safe,
        Utils.MegaSwapSellData calldata params
    )
        external
        payable
        onlyScoreLab
        onlyForSafe(safe, params.beneficiary)
        {
            _swap(
                safe,
                params.fromToken,
                params.path[0].path[0].to,
                params.fromAmount,
                abi.encodeWithSelector(0x25af3621, params)
            );
        }

    function protectedSimpleSwap(
        address safe,
        Utils.SimpleData calldata params
    )
        external
        payable
        onlyScoreLab
        onlyForSafe(safe, params.beneficiary)
        {
            _swap(
                safe,
                params.fromToken,
                params.toToken,
                params.fromAmount,
                abi.encodeWithSelector(0x42323ab5, params)
            ); 
        }

    function protectedSimpleBuy(
        address safe,
        Utils.SimpleData calldata params
    )
        external
        payable
        onlyScoreLab
        onlyForSafe(safe, params.beneficiary)
        {
            _swap(
                safe,
                params.fromToken,
                params.toToken,
                params.fromAmount,
                abi.encodeWithSelector(0xd3f395bf, params)
            ); 
        }

    function simpleSwap(
        address safe,
        Utils.SimpleData calldata params
    )
        external
        payable
        onlyScoreLab
        onlyForSafe(safe, params.beneficiary)
        {
            _swap(
                safe,
                params.fromToken,
                params.toToken,
                params.fromAmount,
                abi.encodeWithSelector(0xcb4a1637, params)
            ); 
        }

    function simpleBuy(
        address safe,
        Utils.SimpleData calldata params
    )
        external
        payable
        onlyScoreLab
        onlyForSafe(safe, params.beneficiary)
        {
            _swap(
                safe,
                params.fromToken,
                params.toToken,
                params.fromAmount,
                abi.encodeWithSelector(0x2b65343d, params)
            ); 
        }

    function swapOnUniswap(
        address safe,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    )
        external
        payable
        onlyScoreLab
        {
            _swap(
                safe,
                path[0],
                path[1],
                amountIn,
                abi.encodeWithSelector(
                    0x54840d1a,
                    amountIn,
                    amountOutMin,
                    path
                )
            ); 
        }

    function swapOnUniswapFork(
        address safe,
        address factory,
        bytes32 initCode,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    )
        external
        payable 
        onlyScoreLab
        {
            _swap(
                safe,
                path[0],
                path[1],
                amountIn,
                abi.encodeWithSelector(
                    0xf5661034,
                    factory,
                    initCode,
                    amountIn,
                    amountOutMin,
                    path
                )
            ); 
        }

    function buyOnUniswap(
        address safe,
        uint256 amountInMax,
        uint256 amountOut,
        address[] calldata path
    )
        external
        payable 
        onlyScoreLab
        {
            _swap(
                safe,
                path[0],
                path[1],
                amountInMax,
                abi.encodeWithSelector(
                    0x935fb84b,
                    amountInMax,
                    amountOut,
                    path
                )
            ); 
        }

    function buyOnUniswapFork(
        address safe,
        address factory,
        bytes32 initCode,
        uint256 amountInMax,
        uint256 amountOut,
        address[] calldata path
    )
        external
        payable
        onlyScoreLab
        {
            _swap(
                safe,
                path[0],
                path[1],
                amountInMax,
                abi.encodeWithSelector(
                    0xc03786b0,
                    factory,
                    initCode,
                    amountInMax,
                    amountOut,
                    path
                )
            );
        }

    /*function swapOnUniswapV2Fork(
        address safe,
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address weth,
        uint256[] calldata pools
    )
        external
        payable 
        {
            NOT ENABLED WITHIN THIS MODULE
        }
    */

    /*function buyOnUniswapV2Fork(
        address safe,
        address tokenIn,
        uint256 amountInMax,
        uint256 amountOut,
        address weth,
        uint256[] calldata pools
    )
        external
        payable 
        {
            NOT ENABLED WITHIN THIS MODULE
        }
    */

    function swapOnZeroXv2(
        address safe,
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 amountOutMin,
        address exchange,
        bytes calldata payload
    )
    external
    payable
    onlyScoreLab
    {
        _swap(
            safe,
            address(fromToken),
            address(toToken),
            fromAmount,
            abi.encodeWithSelector(
                0x81033120,
                fromToken,
                toToken,
                fromAmount,
                amountOutMin,
                exchange,
                payload
            )
        );
    }

    function swapOnZeroXv4(
        address safe,
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 amountOutMin,
        address exchange,
        bytes calldata payload
    )
    external
    payable
    onlyScoreLab
    {
        _swap(
            safe,
            address(fromToken),
            address(toToken),
            fromAmount,
            abi.encodeWithSelector(
                0x64466805,
                fromToken,
                toToken,
                fromAmount,
                amountOutMin,
                exchange,
                payload
            )
        );
    }

    function _swap(
        address safe,
        address fromToken,
        address toToken,
        uint256 amount,
        bytes memory data
    ) private {
        Allowance storage allowance = _allowances[safe][fromToken][toToken];
        require(allowance.amount >= amount, "SL#07");
        require(allowance.expiration >= block.timestamp, "SL#08");

        uint256 etherAmount = 0;

        if (fromToken != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            address tokenTransferProxy = IAugustusSwapper(AUGUSTUS_SWAPPER)
                        .getTokenTransferProxy();

            //Init approval to 0 to avoid attack vectors
            if (
                !IGnosisSafe(safe).execTransactionFromModule(
                    fromToken,
                    0,
                    abi.encodeWithSelector(0x095ea7b3, tokenTransferProxy, 0),
                    Enum.GnosisSafeOperation.Call
                )
            ) revert("SL#11");

            //Approval with the specified amount
            require(
                IGnosisSafe(safe).execTransactionFromModule(
                    fromToken,
                    0,
                    abi.encodeWithSelector(0x095ea7b3, tokenTransferProxy, amount),
                    Enum.GnosisSafeOperation.Call
                ),
                "SL#11"
            );
        } else {
            etherAmount = amount;
        }

        uint256 balance = IERC20(fromToken).balanceOf(safe);

        if (
            !IGnosisSafe(safe).execTransactionFromModule(
                AUGUSTUS_SWAPPER,
                etherAmount,
                data,
                Enum.GnosisSafeOperation.Call
            )
        ) revert("SL#10");

        allowance.amount -= balance - IERC20(fromToken).balanceOf(safe);
    }

    function setTokenPair(
        address from,
        address to,
        uint256 amount,
        uint256 expiration
    ) external {
        require(amount == 0 || expiration > block.timestamp, "SL#04");
        require(amount != 0 || expiration == 0, "SL#04");

        _allowances[msg.sender][from][to] = Allowance({
            amount: amount,
            expiration: expiration
        });
    }

    function setAdmin(address account, bool isAdmin) external onlyAdmin {
        require(isAdmin || msg.sender != account, "SL#03");

        _isAdmin[account] = isAdmin;
    }

    function setScoreLab(address account, bool isScoreLab) external onlyAdmin {
        _isScoreLab[account] = isScoreLab;
    }
}