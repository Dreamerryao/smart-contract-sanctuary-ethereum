pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// File: contracts/Jackpot.sol

contract Jackpot is Ownable {
    using SafeMath for uint256;

    struct Range {
        uint256 end;
        address player;
    }

    uint256 constant public NO_WINNER = uint256(-1);
    uint256 constant public BLOCK_STEP = 100; // Every 100 blocks
    uint256 constant public PROBABILITY = 1000; // 1/1000

    uint256 public winnerOffset = NO_WINNER;
    uint256 public totalLength;
    mapping (uint256 => Range) public ranges;
    mapping (address => uint256) public playerLengths;

    function () public payable onlyOwner {
    }

    function addRange(address player, uint256 length) public onlyOwner returns(uint256 begin, uint256 end) {
        begin = totalLength;
        end = begin.add(length);

        playerLengths[player] += length;
        ranges[begin] = Range({
            end: end,
            player: player
        });

        totalLength = end;
    }

    function candidateBlockNumberHash() public view returns(uint256) {
        uint256 blockNumber = block.number.sub(1).div(BLOCK_STEP).mul(BLOCK_STEP);
        return uint256(blockhash(blockNumber));
    }

    function shouldSelectWinner() public view returns(bool) {
        return (candidateBlockNumberHash() ^ uint256(this)) % PROBABILITY == 0;
    }

    function selectWinner() public onlyOwner returns(uint256) {
        require(winnerOffset == NO_WINNER, "Winner was selected");
        require(shouldSelectWinner(), "Winner could not be selected now");

        winnerOffset = (candidateBlockNumberHash() / PROBABILITY) % totalLength;
        return winnerOffset;
    }

    function payJackpot(uint256 begin) public onlyOwner {
        Range storage range = ranges[begin];
        require(winnerOffset != NO_WINNER, "Winner was not selected");
        require(begin <= winnerOffset && winnerOffset < range.end, "Not winning range");

        selfdestruct(range.player);
    }
}