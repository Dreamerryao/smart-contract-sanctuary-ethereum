/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

// SPDX-License-Identifier: MIT;

pragma solidity >= 0.6.6;

contract IMasterChef {
    
    
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. SWIPEs to distribute per block.
        uint256 lastRewardBlock; // Last block number that SWIPEs distribution occurs.
        uint256 accSwipePerShare; // Accumulated SWIPEs per share, times 1e12. See below.
    }
    
    PoolInfo[] public poolInfo;
    function deposit(uint256 _pid, uint256 _amount) public {}
 
    function withdraw(uint256 _pid, uint256 _amount) public {}

    function emergencyWithdraw(uint256 _pid) public {}
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow"); 
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ETHereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

contract ETHSwipeswap is Ownable{
    using SafeMath for uint256;

    event SwapTokenToToken(
        uint[] amounts
    );

    event SwapTokenToEth(
        uint[] amounts
    );

    event SwapEthToToken(
        uint[] amounts
    );

    event AddLiquidity(
        uint amountA,
        uint amountB, 
        uint liquidity
    );

    event AddLiquidityETH(
        uint amountToken,
        uint amountETH, 
        uint liquidity
    );

    event RemoveLiquidity(
        uint amountA,
        uint amountB
    );

    event RemoveLiquidityETH(
        uint amountToken,
        uint amountETH
    );

    event StakeSXP();

    event WithdrawSXP();

    IUniswapV2Router02 private swipeswapRouter;
    IMasterChef masterChef;


    receive() external payable {

    }
    address payable public feeAddress = address(0x0);
    
    constructor(IUniswapV2Router02 _swipeswapRouter02, IMasterChef _masterChef) public {
        swipeswapRouter = _swipeswapRouter02;
        masterChef = _masterChef;

    }

    function setFeeAddress(address payable _feeAddress) external onlyOwner() {
        feeAddress = _feeAddress;
    }
    
    /////////////////////////////// SWAP ///////////////////////////////////////

    function swapTokenToToken(address _tokenA, address _tokenB, uint256 _amountAIn) external {
        require(feeAddress != address(0x0), "set fee address");
        require(IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountAIn), "transferFrom failed.");
        require(IERC20(_tokenA).approve(address(swipeswapRouter), _amountAIn), "approve failed.");

        address[] memory path = new address[](2);
        path[0] = _tokenA;
        path[1] = _tokenB;

        uint[] memory amounts = swipeswapRouter.swapExactTokensForTokens(_amountAIn, 0, path, address(this), block.timestamp);
        
        TransferHelper.safeTransferFrom(
            path[1], address(this), feeAddress, amounts[1].mul(1).div(100000)
        );
        
        TransferHelper.safeTransferFrom(
            path[1], address(this), msg.sender, amounts[1].mul(9999).div(100000)
        );
        
        // uint[] memory amounts = swipeswapRouter.swapExactTokensForTokens(_amountAIn, 0, path, msg.sender, block.timestamp);


        emit SwapTokenToToken(amounts);
    }

    function swapTokenToEth(address _tokenA, uint256 _amountAIn) external {

        require(feeAddress != address(0x0), "set fee address");
        require(IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountAIn), "transferFrom failed.");
        require(IERC20(_tokenA).approve(address(swipeswapRouter), _amountAIn), "approve failed.");

        address[] memory path = new address[](2);
        path[0] = _tokenA;
        path[1] = swipeswapRouter.WETH();

        // uint[] memory amounts = swipeswapRouter.swapExactTokensForETH(_amountAIn, 0, path, msg.sender, block.timestamp);
        uint[] memory amounts = swipeswapRouter.swapExactTokensForETH(_amountAIn, 0, path, address(this), block.timestamp);
        
        TransferHelper.safeTransferFrom(
            path[1], address(this), feeAddress, amounts[1].mul(1).div(100000)
        );
        
        TransferHelper.safeTransferFrom(
            path[1], address(this), msg.sender, amounts[1].mul(9999).div(100000)
        );
        // feeAddress.transfer(amounts[1].mul(1).div(100000));
        // msg.sender.transfer(amounts[1].mul(9999).div(100000));

        emit SwapTokenToEth(amounts);
    }

    function swapEthToToken(address _tokenB) external payable {

        require(feeAddress != address(0x0), "set fee address");
        address[] memory path = new address[](2);
        path[0] = swipeswapRouter.WETH();
        path[1] = _tokenB;

        // uint[] memory amounts = swipeswapRouter.swapExactETHForTokens{value : msg.value}(0, path, msg.sender, block.timestamp);
        
        uint[] memory amounts = swipeswapRouter.swapExactETHForTokens{value : msg.value}(0, path, address(this), block.timestamp);
        
        TransferHelper.safeTransferFrom(
            path[1], address(this), feeAddress, amounts[1].mul(1).div(100000)
        );
        
        TransferHelper.safeTransferFrom(
            path[1], address(this), msg.sender, amounts[1].mul(9999).div(100000)
        );
        

        emit SwapEthToToken(amounts);
    }
    
    /////////////////////////////// Liquidity ///////////////////////////////////////
    
    function addLiquidity(address _tokenA, address _tokenB, uint _amountADesired, uint _amountBDesired) external {

        require(IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountADesired), "transferFrom failed.");
        require(IERC20(_tokenA).approve(address(swipeswapRouter), _amountADesired), "approve failed.");
        
        require(IERC20(_tokenB).transferFrom(msg.sender, address(this), _amountBDesired), "transferFrom failed.");
        require(IERC20(_tokenB).approve(address(swipeswapRouter), _amountBDesired), "approve failed.");

        (uint amountA, uint amountB, uint liquidity) = swipeswapRouter.addLiquidity(_tokenA, _tokenB, _amountADesired, _amountBDesired, 0, 0, msg.sender, block.timestamp);

        emit AddLiquidity(amountA, amountB, liquidity);
    }
   
   
   function addLiquidityETH(address _token, uint _amountDesired) external payable {
        require(IERC20(_token).transferFrom(msg.sender, address(this), _amountDesired), 'transferFrom failed.');
        require(IERC20(_token).approve(address(swipeswapRouter), _amountDesired), 'approve failed.');

        (uint amountToken, uint amountETH, uint liquidity) = swipeswapRouter.addLiquidityETH{value: msg.value}(_token, _amountDesired, 0, 0, msg.sender, block.timestamp);

        emit AddLiquidityETH(amountToken, amountETH, liquidity);
    }

    function removeLiquidity(address _tokenA, address _tokenB, address _pair, uint _liquidity) external {

        require(IERC20(_pair).transferFrom(msg.sender, _pair, _liquidity), "transferFrom failed");
        require(IERC20(_pair).approve(address(swipeswapRouter), _liquidity), "approve failed.");
        
        // (uint amountA, uint amountB) = swipeswapRouter.removeLiquidity(_tokenA, _tokenB, _liquidity, 0, 0, msg.sender, block.timestamp);
        (uint amountA, uint amountB) = swipeswapRouter.removeLiquidity(_tokenA, _tokenB, _liquidity, 0, 0, address(this), block.timestamp);
        
        
        TransferHelper.safeTransferFrom(
            _tokenA, address(this), feeAddress, amountA.mul(1).div(100000)
        );
        
        TransferHelper.safeTransferFrom(
            _tokenA, address(this), msg.sender, amountA.mul(9999).div(100000)
        );
        
        TransferHelper.safeTransferFrom(
            _tokenB, address(this), feeAddress, amountB.mul(1).div(100000)
        );
        
        TransferHelper.safeTransferFrom(
            _tokenB, address(this), msg.sender, amountB.mul(9999).div(100000)
        );
        

        emit RemoveLiquidity(amountA, amountB);
    }

    function removeLiquidityETH(address _token, address _pair, uint _amountDesired) external {

        require(IERC20(_pair).transferFrom(msg.sender, _pair, _amountDesired), "transferFrom failed.");
        require(IERC20(_pair).approve(address(swipeswapRouter), _amountDesired), "approve failed.");

        // (uint amountToken, uint amountETH) = swipeswapRouter.removeLiquidityETH(_token, _amountDesired, 0, 0, msg.sender, block.timestamp);
        (uint amountToken, uint amountETH) = swipeswapRouter.removeLiquidityETH(_token, _amountDesired, 0, 0, address(this), block.timestamp);
        
        
        TransferHelper.safeTransferFrom(
            _token, address(this), feeAddress, amountToken.mul(1).div(100000)
        );
        
        TransferHelper.safeTransferFrom(
            _token, address(this), msg.sender, amountToken.mul(9999).div(100000)
        );
        
        // address(feeAddress).transfer(amounts[1].mul(1).div(100000));
        // msg.sender.transfer(amounts[1].mul(9999).div(100000));
        
        TransferHelper.safeTransferFrom(
            swipeswapRouter.WETH(), address(this), feeAddress, amountETH.mul(1).div(100000)
        );
        
        TransferHelper.safeTransferFrom(
            swipeswapRouter.WETH(), address(this), msg.sender, amountETH.mul(9999).div(100000)
        );
        emit RemoveLiquidityETH(amountToken, amountETH);
    }

}