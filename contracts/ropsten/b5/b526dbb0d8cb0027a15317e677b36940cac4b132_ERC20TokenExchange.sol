pragma solidity ^0.4.23;

// File: node_modules\openzeppelin-solidity\contracts\ReentrancyGuard.sol

/**
 * @title Helps contracts guard agains reentrancy attacks.
 * @author Remco Bloemen <remco@2π.com>
 * @notice If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private reentrancyLock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }

}

// File: node_modules\openzeppelin-solidity\contracts\math\SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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

// File: node_modules\openzeppelin-solidity\contracts\payment\PullPayment.sol

/**
 * @title PullPayment
 * @dev Base contract supporting async send for pull payments. Inherit from this
 * contract and use asyncSend instead of send or transfer.
 */
contract PullPayment {
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

  /**
  * @dev Withdraw accumulated balance, called by payee.
  */
  function withdrawPayments() public {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(address(this).balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    payee.transfer(payment);
  }

  /**
  * @dev Called by the payer to store the sent amount as credit to be pulled.
  * @param dest The destination address of the funds.
  * @param amount The amount to transfer.
  */
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }
}

// File: node_modules\openzeppelin-solidity\contracts\token\ERC20\ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: node_modules\openzeppelin-solidity\contracts\token\ERC20\ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: node_modules\openzeppelin-solidity\contracts\token\ERC20\SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

// File: contracts\ERC20TokenExchange.sol

contract ERC20TokenExchange is PullPayment, ReentrancyGuard {

    using SafeMath for uint256;

    event SellOrderPut(address _erc20TokenAddress, address _seller, uint256 _tokenPerLot, uint256 _pricePerLot, uint256 _numOfLot);
    event SellOrderFilled(address _erc20TokenAddress, address _seller, address _buyer, uint256 _tokenPerLot, uint256 _pricePerLot, uint256 _numOfLot);

    event BuyOrderPut(address _erc20TokenAddress, address _buyer, uint256 _tokenPerLot, uint256 _pricePerLot, uint256 _numOfLot);
    event BuyOrderFilled(address _erc20TokenAddress, address _buyer, address _seller, uint256 _tokenPerLot, uint256 _pricePerLot, uint256 _numOfLot);

    struct Order {

        uint256 tokenPerLot;
        uint256 pricePerLot;
        uint256 numOfLot;

    }

    mapping(address => mapping(address => Order)) public sellOrders;
    mapping(address => mapping(address => Order)) public buyOrders;

    function deposit() public payable nonReentrant {
        require(msg.value != 0);
        asyncSend(msg.sender, msg.value);
    }

    function putSellOrder(address _erc20TokenAddress, uint256 _tokenPerLot, uint256 _pricePerLot, uint256 _lotToSell) public nonReentrant {

        require(_erc20TokenAddress != address(0));
        require(_tokenPerLot != 0);
        require(_pricePerLot != 0);
        require(_lotToSell != 0);

        Order storage order = sellOrders[_erc20TokenAddress][msg.sender];
        order.tokenPerLot = _tokenPerLot;
        order.pricePerLot = _pricePerLot;
        order.numOfLot = _lotToSell;

        ERC20 erc20 = ERC20(_erc20TokenAddress);
        require(hasSufficientTokenInternal(erc20, msg.sender, _lotToSell.mul(_tokenPerLot)));

        emit SellOrderPut(_erc20TokenAddress, msg.sender, _tokenPerLot, _pricePerLot, _lotToSell);
    }

    function fillSellOrder(address _erc20TokenAddress, address _seller, uint256 _tokenPerLot, uint256 _lotToBuy) public payable nonReentrant {

        require(_erc20TokenAddress != address(0));
        require(_seller != address(0));
        require(_lotToBuy != 0);

        Order storage order = sellOrders[_erc20TokenAddress][_seller];
        uint256 numOfLot = order.numOfLot;
        uint256 pricePerLot = order.pricePerLot;
        require(numOfLot >= _lotToBuy);
        require(order.tokenPerLot == _tokenPerLot);

        uint256 payment = pricePerLot.mul(_lotToBuy);
        require(payment != 0 && payment == msg.value);

        order.numOfLot = numOfLot.sub(_lotToBuy);

        asyncSend(_seller, payment);

        ERC20 erc20 = ERC20(_erc20TokenAddress);

        uint256 amoutToBuy = _lotToBuy.mul(_tokenPerLot);
        uint256 previousBalance = erc20.balanceOf(msg.sender);

        SafeERC20.safeTransferFrom(erc20, _seller, msg.sender, amoutToBuy);
        require(previousBalance.add(amoutToBuy) == erc20.balanceOf(msg.sender));

        emit SellOrderFilled(_erc20TokenAddress, _seller, msg.sender, _tokenPerLot, pricePerLot, _lotToBuy);
    }

    function putBuyOrder(address _erc20TokenAddress, uint256 _tokenPerLot, uint256 _pricePerLot, uint256 _lotToBuy) public nonReentrant {

        require(_erc20TokenAddress != address(0));
        require(_tokenPerLot != 0);
        require(_pricePerLot != 0);
        require(_lotToBuy != 0);
        require(hasSufficientPaymentInternal(msg.sender, _pricePerLot.mul(_lotToBuy)));

        Order storage order = buyOrders[_erc20TokenAddress][msg.sender];
        order.tokenPerLot = _tokenPerLot;
        order.pricePerLot = _pricePerLot;
        order.numOfLot = _lotToBuy;

        emit BuyOrderPut(_erc20TokenAddress, msg.sender, _tokenPerLot, _pricePerLot, _lotToBuy);
    }

    function fillBuyOrder(address _erc20TokenAddress, address _buyer, uint256 _tokenPerLot, uint256 _pricePerLot, uint256 _lotToSell) public nonReentrant {
        require(_erc20TokenAddress != address(0));
        require(_buyer != address(0));
        require(_tokenPerLot != 0);
        require(_pricePerLot != 0);
        require(_lotToSell != 0);

        Order storage order = buyOrders[_erc20TokenAddress][_buyer];
        uint256 numOfLot = order.numOfLot;

        require(numOfLot >= _lotToSell);
        require(order.tokenPerLot == _tokenPerLot);
        require(order.pricePerLot == _pricePerLot);

        uint256 payment = _pricePerLot.mul(_lotToSell);

        asyncTransfer(_buyer, msg.sender, payment);
        order.numOfLot = numOfLot.sub(_lotToSell);

        ERC20 erc20 = ERC20(_erc20TokenAddress);

        uint256 amoutToSell = _lotToSell.mul(_tokenPerLot);
        uint256 previousBalance = erc20.balanceOf(_buyer);

        SafeERC20.safeTransferFrom(erc20, msg.sender, _buyer, amoutToSell);
        require(previousBalance.add(amoutToSell) == erc20.balanceOf(_buyer));

        emit SellOrderFilled(_erc20TokenAddress, _buyer, msg.sender, _tokenPerLot, _pricePerLot, _lotToSell);
    }

    function isValidSellOrder(address _erc20TokenAddress, address _seller) public view returns(bool) {
        ERC20 erc20 = ERC20(_erc20TokenAddress);
        Order storage order = sellOrders[_erc20TokenAddress][_seller];
        return hasSufficientTokenInternal(erc20, _seller, order.tokenPerLot.mul(order.numOfLot));
    }

    function isValidBuyOrder(address _erc20TokenAddress, address _buyer) public view returns(bool) {
        Order storage order = buyOrders[_erc20TokenAddress][_buyer];
        return hasSufficientPaymentInternal(_buyer, order.pricePerLot.mul(order.numOfLot));
    }

    function getSellOrderInfo(address _erc20TokenAddress, address _seller) public view returns(uint256, uint256, uint256) {
        Order storage order = sellOrders[_erc20TokenAddress][_seller];
        return (order.tokenPerLot, order.pricePerLot, order.numOfLot);
    }

    function getBuyOrderInfo(address _erc20TokenAddress, address _buyer) public view returns(uint256, uint256, uint256) {
        Order storage order = buyOrders[_erc20TokenAddress][_buyer];
        return (order.tokenPerLot, order.pricePerLot, order.numOfLot);
    }

    function asyncTransfer(address _from, address _to, uint256 amount) internal {
        require(hasSufficientPaymentInternal(_from, amount));
        payments[_from] = payments[_from].sub(amount);
        payments[_to] = payments[_to].add(amount);
    }

    function hasSufficientPaymentInternal(address _payee, uint256 _amount) internal view returns(bool) {
        return payments[_payee] >= _amount;
    }

    function hasSufficientTokenInternal(ERC20 erc20, address _seller, uint256 _amountToSell) internal view returns(bool) {
        return erc20.allowance(_seller, address(this)) >= _amountToSell;
    }

}