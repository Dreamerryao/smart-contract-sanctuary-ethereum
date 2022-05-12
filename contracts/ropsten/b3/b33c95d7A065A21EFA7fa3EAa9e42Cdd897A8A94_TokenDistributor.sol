pragma solidity ^0.4.23;

// File: contracts/sale/Product.sol

/**
 * @title Product
 * @dev Simpler version of Product interface
 */
contract Product {
    string public name;
    uint256 public maxcap;
    uint256 public weiRaised;
    uint256 public exceed;
    uint256 public minimum;
    uint256 public rate;
    uint256 public lockup;

    constructor (
        string _name,
        uint256 _maxcap,
        uint256 _exceed,
        uint256 _minimum,
        uint256 _rate,
        uint256 _lockup
    ) public {
        require(_maxcap > _minimum);

        name = _name;
        maxcap = _maxcap;
        exceed = _exceed;
        minimum = _minimum;
        rate = _rate;
        lockup = _lockup;
    }
}

// File: contracts/utils/ExtendsOwnable.sol

contract ExtendsOwnable {

    mapping(address => bool) owners;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipExtended(address indexed host, address indexed guest);

    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }

    constructor() public {
        owners[msg.sender] = true;
    }

    function addOwner(address guest) public onlyOwner {
        require(guest != address(0));
        owners[guest] = true;
        emit OwnershipExtended(msg.sender, guest);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owners[newOwner] = true;
        delete owners[msg.sender];
        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

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

// File: contracts/sale/TokenDistributor.sol

contract TokenDistributor is ExtendsOwnable {

    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    struct Purchased {
        address buyer;
        address product;
        uint256 id;
        uint256 amount;
        uint256 etherAmount;
        bool release;
        bool refund;
    }

    ERC20 token;
    Purchased[] private purchasedList;
    uint256 private index;
    uint256 public criterionTime;

    modifier validAddress(address _account) {
        require(_account != address(0));
        require(_account != address(this));
        _;
    }

    event Receipt(
        address buyer,
        address product,
        uint256 id,
        uint256 amount,
        uint256 etherAmount,
        bool release,
        bool refund
    );

    event ReleaseByCount(
        address product,
        uint256 request,
        uint256 succeed,
        uint256 remainder
    );

    event BuyerAddressTransfer(uint256 _id, address _from, address _to);

    event WithdrawToken(address to, uint256 amount);

    constructor(address _token) public {
        token = ERC20(_token);
        index = 0;
        criterionTime = 0;

        //for error check
        purchasedList.push(Purchased(0, 0, 0, 0, 0, true, true));
    }

    function setPurchased(address _buyer, address _product, uint256 _amount, uint256 _etherAmount)
        external
        onlyOwner
        validAddress(_buyer)
        validAddress(_product)
        returns(uint256)
    {
        index = index.add(1);
        purchasedList.push(Purchased(_buyer, _product, index, _amount, _etherAmount, false, false));
        return index;

        emit Receipt(_buyer, _product, index, _amount, _etherAmount, false, false);
    }

    function addPurchased(uint256 _index, uint256 _amount, uint256 _etherAmount) external onlyOwner {
        require(_index != 0);

        if (isLive(_index)) {
            purchasedList[_index].amount = purchasedList[_index].amount.add(_amount);
            purchasedList[_index].etherAmount = purchasedList[_index].etherAmount.add(_etherAmount);

            emit Receipt(
                purchasedList[_index].buyer,
                purchasedList[_index].product,
                purchasedList[_index].id,
                _amount,
                _etherAmount,
                false,
                false);
        }
    }

    function getAmount(uint256 _index) external view returns(uint256) {
        if (_index == 0) {
            return 0;
        }

        if (purchasedList[_index].release || purchasedList[_index].refund) {
            return 0;
        } else {
            return purchasedList[_index].amount;
        }
    }

    function getEtherAmount(uint256 _index) external view returns(uint256) {
        if (_index == 0) {
            return 0;
        }

        if (purchasedList[_index].release || purchasedList[_index].refund) {
            return 0;
        } else {
            return purchasedList[_index].etherAmount;
        }
    }

    function getId(address _buyer, address _product) external view returns (uint256) {
        for(uint i=1; i < purchasedList.length; i++) {
            if (purchasedList[i].product == _product
                && purchasedList[i].buyer == _buyer) {
                return purchasedList[i].id;
            }
        }
        return 0;
    }

    function setCriterionTime(uint256 _criterionTime) external onlyOwner {
        require(_criterionTime > 0);

        criterionTime = _criterionTime;
    }

    function releaseByCount(address _product, uint256 _count)
        external
        onlyOwner
    {
        require(criterionTime != 0);

        uint256 succeed = 0;
        uint256 remainder = 0;

        for(uint i=1; i < purchasedList.length; i++) {
            if (isLive(i) && (purchasedList[i].product == _product)) {
                if (succeed < _count) {
                    Product product = Product(purchasedList[i].product);
                    require(block.timestamp >= criterionTime.add(product.lockup() * 1 days));
                    require(token.balanceOf(address(this)) >= purchasedList[i].amount);

                    purchasedList[i].release = true;
                    token.safeTransfer(purchasedList[i].buyer, purchasedList[i].amount);

                    succeed = succeed.add(1);

                    emit Receipt(
                        purchasedList[i].buyer,
                        purchasedList[i].product,
                        purchasedList[i].id,
                        purchasedList[i].amount,
                        purchasedList[i].etherAmount,
                        purchasedList[i].release,
                        purchasedList[i].refund);
                } else {
                    remainder = remainder.add(1);
                }
            }
        }

        emit ReleaseByCount(_product, _count, succeed, remainder);
    }

    function release(uint256 _index) external onlyOwner {
        require(_index != 0);
        require(criterionTime != 0);
        require(isLive(_index));

        Product product = Product(purchasedList[_index].product);
        require(block.timestamp >= criterionTime.add(product.lockup() * 1 days));
        require(token.balanceOf(address(this)) >= purchasedList[_index].amount);

        purchasedList[_index].release = true;
        token.safeTransfer(purchasedList[_index].buyer, purchasedList[_index].amount);

        emit Receipt(
            purchasedList[_index].buyer,
            purchasedList[_index].product,
            purchasedList[_index].id,
            purchasedList[_index].amount,
            purchasedList[_index].etherAmount,
            purchasedList[_index].release,
            purchasedList[_index].refund);
    }

    function refund(uint _index) external onlyOwner returns (bool, uint256) {
        if (isLive(_index)) {
            purchasedList[_index].refund = true;

            emit Receipt(
                purchasedList[_index].buyer,
                purchasedList[_index].product,
                purchasedList[_index].id,
                purchasedList[_index].amount,
                purchasedList[_index].etherAmount,
                purchasedList[_index].release,
                purchasedList[_index].refund);

            return (true, purchasedList[_index].etherAmount);
        } else {
            return (false, 0);
        }
    }

    function buyerAddressTransfer(uint256 _index, address _from, address _to)
        external
        onlyOwner
        returns (bool)
    {
        if (purchasedList[_index].buyer == _from) {
            purchasedList[_index].buyer = _to;
            emit BuyerAddressTransfer(_index, _from, _to);
            return true;
        } else {
            return false;
        }
    }

    function withdrawToken(address _Owner) external onlyOwner {
        token.safeTransfer(_Owner, token.balanceOf(address(this)));
        emit WithdrawToken(_Owner, token.balanceOf(address(this)));
    }

    function isLive(uint256 _index) private view returns(bool){
        if (!purchasedList[_index].release && !purchasedList[_index].refund) {
            return true;
        } else {
            return false;
        }
    }
}