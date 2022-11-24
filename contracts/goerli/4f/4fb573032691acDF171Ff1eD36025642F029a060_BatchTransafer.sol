// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BatchTransafer {    

event BatchTransfer(address fromAddress,address[] indexed  toAddress,uint[] recipientAmount);
event BatchTransferMultiToken(address indexed fromAddress,address[] indexed tokenAddress,address[] indexed toAddress,uint[] recipientAmount);
event BatchTransferToken(address indexed fromAddress,address indexed tokenAddress,address[] indexed toAddress, uint[] recipientAmount);

function batchTransfer(address[] calldata recipients,uint256[] calldata amounts) public payable {
    uint totalEthers;
    require(recipients.length == amounts.length, "The input array must have the same lenght");
    for(uint i=0;i<recipients.length;i++){
      require(recipients[i] != address(0), "Recipient address is zero");
        totalEthers += amounts[i];
    }
    require(msg.value == totalEthers, "Insuffient balance");
    for(uint i=0;i<recipients.length;i++){
    (bool success,)= recipients[i].call{value: amounts[i]}("");
    require(success , "Transaction is failed ");
    }
    emit BatchTransfer(msg.sender,recipients,amounts);
}

fallback() external {
}
function batchTransferMultiTokens(
    address[] calldata tokenAddress,
    address[] calldata recipients,
    uint256[] calldata amounts
  ) external {
    require(
      tokenAddress.length == recipients.length &&
        tokenAddress.length == amounts.length,
      "The input arrays must have the same length"
    );
  for(uint i=0;i<tokenAddress.length;i++)
  {
    require(tokenAddress[i] != address(0), "Contract address is zero");
    IERC20 requestedToken = IERC20(tokenAddress[i]);
    require(
      requestedToken.allowance(msg.sender, address(this)) >= amounts[i],
      "Not sufficient allowance for batch to pay"
    );
    require(requestedToken.balanceOf(msg.sender) >= amounts[i], "Not enough funds");

    (bool success,) = address(requestedToken).call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, recipients[i], amounts[i]));
    require(success,"BatchTransferMultiTokens payment failed");
    }
    emit BatchTransferMultiToken(msg.sender,tokenAddress,recipients,amounts);
  }

function batchTransferToken(
    address tokenAddress,
    address[] calldata recipients,
    uint256[] calldata amounts
  ) external {
    require(tokenAddress != address(0), "Contract addreess is zero");
    require(
      recipients.length == amounts.length,
      "The input arrays must have the same length"
    );
    uint256 amount = 0;
    for (uint256 i = 0; i < recipients.length; i++) {
      amount += amounts[i];
    }
    
    IERC20 requestedToken = IERC20(tokenAddress);
    require(
      requestedToken.allowance(msg.sender, address(this)) >= amount,
      "Not sufficient allowance for batch to pay"
    );
    require(requestedToken.balanceOf(msg.sender) >= amount, "Not enough funds");

    (bool success, ) = address(requestedToken).call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), amount));
    require(success,"BatchERC20Payment payment failed");

    require(requestedToken.balanceOf(address(this)) >= amount,"Smart contract does not have enough Balance");
    for(uint256 i = 0; i < recipients.length; i++) {      
      (bool okay,) = address(requestedToken).call(abi.encodeWithSignature("transfer(address,uint256)", recipients[i],  amounts[i]));
        require(okay , "batchTransferToken Payment is failed");
    } 
    emit BatchTransferToken(msg.sender,tokenAddress,recipients,amounts);
  }  
}