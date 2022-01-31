/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

// File: IERC20.sol

pragma solidity >=0.7.0 <0.9.0;

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
// File: ISwap.sol

pragma solidity >=0.7.0 <0.9.0;

interface ISwap {
    function swapExtractOut(
        address tokenIn, 
        address tokenOut, 
        address recipient, 
        uint256 amountIn, 
        uint256 slippage, 
        uint256 deadline
    ) external returns (uint256);

    // function swapExtractIn(
    //     address tokenIn, 
    //     address tokenOut, 
    //     address recipient, 
    //     uint256 amountOut, 
    //     uint256 slippage, 
    //     uint256 deadline
    // ) external returns (uint256);

    function swapEstimateOut(address tokenIn, address tokenOut, uint256 amountIn) external view returns (uint256);

    function swapEstimateIn(address tokenIn, address tokenOut, uint256 amountOut) external view returns (uint256);
}
// File: Ownerable.sol

pragma solidity >=0.7.0 <0.9.0;

abstract contract Ownerable {

    address private _owner;

    event OwnershipTransferred(address indexed preOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// File: Aggreswap.sol

pragma solidity >=0.7.0 <0.9.0;




contract Aggreswap is Ownerable, ISwap {

    event TokenAdded(address token);
    event NewDexAdded(string name, address indexed handler);
    event DexHandlerChanged(string name, address indexed oldHandler, address indexed newHandler);
    event Swap(
        string dexName,
        address indexed dexHandler,
        address sender,
        address recipient,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    struct Dex {
        string name;
        ISwap handler;
    }

    Dex[] public dexs;
    mapping(string => ISwap) public dexHandlers;
    address[] public tokens;

    function supportDex(string calldata name, ISwap handler) external onlyOwner {
        require(address(handler) != address(0), "Aggreswap: handler is the zero address");
        require(address(dexHandlers[name]) == address(0), "Aggreswap: the dex is already added");
        dexHandlers[name] = handler;
        Dex memory dex = Dex(name, handler);
        dexs.push(dex);
        emit NewDexAdded(name, address(handler));
    }

    function updateDexHandler(string calldata name, ISwap handler) external onlyOwner {
        require(address(handler) != address(0), "Aggreswap: handler is the zero address");
        require(address(dexHandlers[name]) != address(0), "Aggreswap: the dex is not exist");
        for (uint256 i = 0; i < dexs.length; i++) {
            if (keccak256(abi.encodePacked(dexs[i].name)) == keccak256(abi.encodePacked(name))) {
                dexs[i].handler = handler;
            }
        }
        emit DexHandlerChanged(name, address(dexHandlers[name]), address(handler));
        dexHandlers[name] = handler;
    }

    function supportTokens(address[] memory tokens_) external onlyOwner {
        require(tokens_.length > 0, "Aggreswap: tokens length is zero");
        for (uint256 i = 0; i < tokens_.length; i++) {
            _addToken(tokens_[i]);
        }
    }

    function _addToken(address token) internal {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == token) {
                return;
            }
        }
        tokens.push(token);
        emit TokenAdded(token);
    }

    function isTokenSupported(address token) external view returns (bool) {
        return _isTokenSupportedInternal(token);
    }

    function _isTokenSupportedInternal(address token) internal view returns (bool) {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == token) {
                return true;
            }
        }
        return false;
    }

    function swapEstimateOut(address tokenIn, address tokenOut, uint256 amountIn) external view override returns (uint256) {
        (uint256 resultAmount,) = _getBestOut(tokenIn, tokenOut, amountIn);
        return resultAmount;
    }

    function swapEstimateIn(address tokenIn, address tokenOut, uint256 amountOut) external view override returns (uint256) {
        (uint256 resultAmount,) = _getBestIn(tokenIn, tokenOut, amountOut);
        return resultAmount;
    }

    function swapExtractOut(
        address tokenIn, 
        address tokenOut, 
        address recipient, 
        uint256 amountIn, 
        uint256 slippage, 
        uint256 deadline
    ) external override returns (uint256) {
        require(recipient != address(0), "Aggreswap: recipient is the zero address");
        require(_isTokenSupportedInternal(tokenIn), "Aggreswap: tokenIn is not supported");
        (, Dex memory dex) = _getBestOut(tokenIn, tokenOut, amountIn);
        IERC20(tokenIn).transferFrom(msg.sender, address(dex.handler), amountIn);
        uint amountOut = ISwap(dex.handler).swapExtractOut(tokenIn, tokenOut, recipient, amountIn, slippage, deadline);
        emit Swap(dex.name, address(dex.handler), msg.sender, recipient, tokenIn, tokenOut, amountIn, amountOut);
        return amountOut;
    }

    // function swapExtractIn(
    //     address tokenIn, 
    //     address tokenOut, 
    //     address recipient, 
    //     uint256 amountOut, 
    //     uint256 slippage, 
    //     uint256 deadline
    // ) external override returns (uint256) {
    //     require(recipient != address(0), "Aggreswap: recipient is the zero address");
    //     (, address resultHandler) = _getBestIn(tokenIn, tokenOut, amountOut);
    //     return ISwap(resultHandler).swapExtractIn(tokenIn, tokenOut, recipient, amountOut, slippage, deadline);
    // }

    function _getBestOut(address tokenIn, address tokenOut, uint256 amountIn) internal view returns (uint256, Dex memory) {
        require(tokenIn != address(0), "Aggreswap: tokenIn is the zero address");
        require(tokenOut != address(0), "Aggreswap: tokenOut is the zero address");
        require(tokenIn != tokenOut, "Aggreswap: tokenIn and tokenOut is the same");
        require(amountIn > 0, "Aggreswap: amountIn must be greater than zero");
        
        uint256 resultAmount = 0;
        Dex memory resultDex;
        
        for (uint256 i = 0; i < dexs.length; i++) {
            uint256 amount = dexs[i].handler.swapEstimateOut(tokenIn, tokenOut, amountIn);
            if (amount > resultAmount) {
                resultAmount = amount;
                resultDex = dexs[i];
            }
        }

        return (resultAmount, resultDex);
    }

    function _getBestIn(address tokenIn, address tokenOut, uint256 amountOut) internal view returns (uint256, Dex memory) {
        require(tokenIn != address(0), "Aggreswap: tokenIn is the zero address");
        require(tokenOut != address(0), "Aggreswap: tokenOut is the zero address");
        require(tokenIn != tokenOut, "Aggreswap: tokenIn and tokenOut is the same");
        require(amountOut > 0, "Aggreswap: amountOut must be greater than zero");
        
        uint256 resultAmount = 0;
        Dex memory resultDex;
        
        for (uint256 i = 0; i < dexs.length; i++) {
            uint256 amount = dexs[i].handler.swapEstimateIn(tokenIn, tokenOut, amountOut);
            if (amount < resultAmount) {
                resultAmount = amount;
                resultDex = dexs[i];
            } else if (resultAmount == 0) {
                resultAmount = amount;
                resultDex = dexs[i];
            }
        }

        return (resultAmount, resultDex);
    }
}