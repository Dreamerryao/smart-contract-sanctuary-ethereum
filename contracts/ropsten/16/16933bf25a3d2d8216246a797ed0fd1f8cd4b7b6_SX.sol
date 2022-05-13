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

// File: contracts/SX.sol

contract SX is Ownable {
    using SafeMath for uint256;

    uint256 public adminFeePercent = 1; // 1%
    uint256 public jackpotFeePercent = 2; // 2%
    uint256 public minValue = 0.01 ether;
    uint256 public maxValue = 3 ether;
    
    struct Game {
        address player;
        uint256 blockNumber;
        uint256 value;
        uint256 combinations;
        uint256 answer;
    }

    Game[] public games;
    uint256 public gamesFinished;
    uint256 public totalWeisInGame;
    mapping (uint256 => bytes32) private _blockHashes;
    mapping (uint256 => bool) public blockNumbersWithGames;
    
    Jackpot public nextJackpot;
    Jackpot[] public prevJackpots;

    event BlockHashAssigned(uint256 indexed blockNumber, bytes32 indexed blockHash);
    event GameStarted(address indexed player, uint256 indexed blockNumber, uint256 indexed index, uint256 combinations, uint256 answer, uint256 value);
    event GameFinished(address indexed player, uint256 indexed blockNumber, uint256 value, uint256 combinations, uint256 answer, bool won);

    event JackpotRangeAdded(address indexed jackpot, address indexed player, uint256 indexed begin, uint256 end);
    event JackpotWinnerSelected(address indexed jackpot, uint256 offset);
    event JackpotRewardPayed(address indexed jackpot, address indexed player, uint256 begin, uint256 end, uint256 winnerOffset, uint256 value);

    constructor() public {
        nextJackpot = new Jackpot();
    }

    function gamesLength() public view returns(uint256) {
        return games.length;
    }

    function prevJackpotsLength() public view returns(uint256) {
        return prevJackpots.length;
    }

    function blockHashes(uint256 blockNumber) public view returns(bytes32) {
        if (blockNumber.add(256) > block.number) {
            return blockhash(blockNumber);
        }
    
        return _blockHashes[blockNumber];
    }

    function setAllBlockHashes() public {
        for (uint i = 1; i <= 256; i++) {
            if (blockNumbersWithGames[block.number - i]) {
                if (_setBlockHash(block.number - i)) {
                    return;
                }
            }
        }
    }

    function updateState() public {
        finishAllGames();

        // Update 256 latest block hashes
        setAllBlockHashes();

        if (nextJackpot.shouldSelectWinner()) {
            nextJackpot.selectWinner();
            emit JackpotWinnerSelected(nextJackpot, nextJackpot.winnerOffset());

            prevJackpots.push(nextJackpot);
            nextJackpot = new Jackpot();
        }
    }

    function () public payable {
        // Coin flip
        uint256 prevBlockHash = uint256(blockhash(block.number - 1));
        play(2, 1 << (prevBlockHash % 2));
    }

    function play(uint256 combinations, uint256 answer) public payable {
        uint256 answerSize = _countBits(answer);
        uint256 possibleReward = msg.value.mul(combinations).div(answerSize);
        require(minValue <= possibleReward && possibleReward <= maxValue, "Possible reward value out of range");
        require(answer < (1 << combinations) - 1, "Answer should not contain all bits set");
        require(2 <= combinations && combinations <= 100, "Combinations value is invalid");

        // Update
        updateState();

        // Play game
        uint256 blockNumber = block.number + 1;
        emit GameStarted(msg.sender, blockNumber, games.length, combinations, answer, msg.value);
        blockNumbersWithGames[blockNumber] = true;
        games.push(Game({
            player: msg.sender,
            blockNumber: blockNumber,
            value: msg.value,
            combinations: combinations,
            answer: answer
        }));

        (uint256 begin, uint256 end) = nextJackpot.addRange(msg.sender, msg.value);
        emit JackpotRangeAdded(nextJackpot, msg.sender, begin, end);

        totalWeisInGame = totalWeisInGame.add(msg.value.mul(combinations));
        require(totalWeisInGame <= address(this).balance, "Not enough balance");
    }

    function finishAllGames() public returns(uint256 count) {
        while (finishNextGame()) {
            count += 1;
        }
    }

    function finishNextGame() public returns(bool) {
        if (gamesFinished >= games.length) {
            return false;
        }

        Game storage game = games[gamesFinished];
        uint256 hash = uint256(blockHashes(game.blockNumber));
        if (hash == 0) {
            return false;
        }

        uint256 answerSize = _countBits(game.answer);
        uint256 reward = game.value.mul(game.combinations).div(answerSize);
        uint256 adminFee = reward.mul(adminFeePercent).div(100);
        uint256 jackpotFee = reward.mul(jackpotFeePercent).div(100);
        
        if (((1 << (hash % game.combinations)) & game.answer) != 0) {
            owner().send(adminFee);
            address(nextJackpot).transfer(jackpotFee);
            game.player.transfer(reward.sub(adminFee).sub(jackpotFee));
            emit GameFinished(game.player, game.blockNumber, game.value, game.combinations, game.answer, true);
        } else {
            emit GameFinished(game.player, game.blockNumber, game.value, game.combinations, game.answer, false);
        }

        totalWeisInGame = totalWeisInGame.sub(reward);
        gamesFinished += 1;
        return true;
    }

    function finishJackpot(Jackpot jackpot, uint256 begin) public {
        (uint256 end, address player) = jackpot.ranges(begin);
        uint256 winnerOffset = jackpot.winnerOffset();
        uint256 value = address(jackpot).balance;
        jackpot.payJackpot(begin);
        emit JackpotRewardPayed(jackpot, player, begin, end, winnerOffset, value);
    }

    // Admin methods

    function setAdminFeePercent(uint256 feePercent) public onlyOwner {
        require(feePercent <= 2, "Should be <= 2%");
        adminFeePercent = feePercent;
    }

    function setJackpotFeePercent(uint256 feePercent) public onlyOwner {
        require(feePercent <= 3, "Should be <= 3%");
        jackpotFeePercent = feePercent;
    }

    function setMinValue(uint256 value) public onlyOwner {
        minValue = value;
    }

    function setMaxValue(uint256 value) public onlyOwner {
        maxValue = value;
    }

    function putToBank() public payable onlyOwner {
    }

    function getFromBank(uint256 value) public onlyOwner {
        msg.sender.transfer(value);
        require(totalWeisInGame <= address(this).balance, "Not enough balance");
    }

    function _setBlockHash(uint blockNumber) internal returns(bool) {
        bytes32 blockHash = blockhash(blockNumber);
            
        if (_blockHashes[blockNumber] == 0 && blockHash != 0) {
            _blockHashes[blockNumber] = blockHash;
            emit BlockHashAssigned(blockNumber, blockHash);
            return false;
        }

        return _blockHashes[blockNumber] != 0;
    }

    function _countBits(uint256 value) internal pure returns(uint256 count) {
        while (value > 0) {
            value &= value - 1; // clear the least significant bit set
            count++;
        }
    }
}