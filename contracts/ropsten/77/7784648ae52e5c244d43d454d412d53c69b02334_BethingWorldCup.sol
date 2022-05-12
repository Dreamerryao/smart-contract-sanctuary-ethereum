pragma solidity ^0.4.23;

// File: zeppelin/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: zeppelin/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts\BethingWorldCup.sol

/**
 * @title BethingWorldCup
 * @author Bething.io
 *
 * A parimutuel betting pool for the FIFA World Cup 2018. Players can place multiple bets on one or more teams,
 * and the total pool amount is then shared amongst all winning bets.
 * 
 * The winning team is determined through an Oraclize query to Wolfram Alpha.
 */
contract BethingWorldCup is Ownable {
	using SafeMath for uint256;

	// ============ Events ============

	event Bet(address indexed better, uint256 weiAmount);

    // ============ Constants ============

	// Minimum bet amount
	uint256 public constant MIN_BET_AMOUNT = 0.01 ether;

	// Commission to be paid to the bookie
	uint256 public constant BOOKIE_COMMISSION = 10;

	// Time from which betting is disabled (1 hour before final)
	uint256 public BETS_CLOSING_TIME = 1531666800; // 15 Jul 2018 - 17:00 CET

	// Total number of teams
	uint256 public constant TOTAL_TEAMS = 32;

	// Teams participating in the competition
	string[TOTAL_TEAMS] public TEAMS = [
		"Russia",
		"Brazil",
		"Iran",
		"Japan",
		"Mexico",
		"Belgium",
		"South Korea",
		"Saudi Arabia",
		"Germany",
		"England",
		"Spain",
		"Nigeria",
		"Costa Rica",
		"Poland",
		"Egypt",
		"Iceland",
		"Serbia",
		"Portugal",
		"France",
		"Uruguay",
		"Argentina",
		"Colombia",
		"Panama",
		"Senegal",
		"Morocco",
		"Tunisia",
		"Switzerland",
		"Croatia",
		"Sweden",
		"Denmark",
		"Australia",
		"Peru"
	];

    // ============ State Variables ============	

	// Address to collect bookmaker fees
	address bookie;

	// Total number of bets
	uint256 public totalBets;

	// Total amount of bets placed on the betting pool
	uint256 public totalBetAmount;

	// Total amount of bets placed on each team
	uint256[TOTAL_TEAMS] public teamTotalBetAmount;

	// Bet amounts for a given player
	mapping(address => uint256[TOTAL_TEAMS]) public betterBetAmounts;

	// ============ Modifiers ============

 	/**
	 * @dev Reverts if not in betting time range.
 	 */
	modifier whenNotClosed() {
		require(!hasClosed());
		_;
	}

 	/**
	 * @dev Reverts if team is not valid.
 	 */
	modifier isValidTeam(uint256 team) {
		require(team <= TOTAL_TEAMS);
		_;
	}

    // ============ Constructor ============

  	/**
   	 * @dev Constructor.
   	 */
	constructor() public {
		bookie = owner;
	}

    // ============ State-Changing Functions ============

  	/**
   	 * @dev Places a bet for a given team.
   	 */
	function bet(uint256 team) public whenNotClosed isValidTeam(team) payable {
		address better = msg.sender;
		uint256 betAmount = msg.value;
		require(betAmount >= MIN_BET_AMOUNT);

		betterBetAmounts[better][team] = betterBetAmounts[better][team].add(betAmount);
		totalBetAmount = totalBetAmount.add(betAmount);
		teamTotalBetAmount[team] = teamTotalBetAmount[team].add(betAmount);
		totalBets++;

		emit Bet(better, betAmount);
	}

	// ============ Public Constant Functions ============

  	/**
   	 * @dev Checks whether the period in which the betting is open has already elapsed.
   	 * @return Whether betting period has elapsed
   	 */
	function hasClosed() public constant returns (bool) {
		return now > BETS_CLOSING_TIME;
	}
}