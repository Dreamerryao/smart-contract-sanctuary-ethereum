pragma solidity ^0.4.25;

/*************************************************************************

  Values are stored in 64 bits signed integer.
  In decimal this works out to an addressable amount of up to
  9,223,372,036,854,775,807

  However, we need to account for floating points, bps and fractional bps.

  8.25 BPS      = 0000000000000000825
  10 BPS        = 0000000000000001000
  28 Cents      = 0000000000000280000
  $35.66        = 0000000000035660000
  $38 Billion   = 0038000000000000000

  Quick Diagram
                  0000000000000 00 00 00
                                     ^==---- Fractional BPS (2)
                                  ^==------- BPS (2)
                               ^==---------- Cents (2)
                 ^=============------------- Dollars (13)

  250 * 8.25 BPS  = 0.20625
  250000000 * 825 = 206250000000 / 1000000 = 0000000000000206250

  
  


*************************************************************************/

contract SmartKx {
  address public keyOwner;              // owner key
  address public keyManager;            // manager key
  string public eMap;                   // encrypted account map
  uint8 public numAccounts;             // number of accounts
  int64[] public breaks;               // break points
  int8[] public rates;                // rates as integer
  mapping(uint16 => mapping(uint8 => mapping(uint8 => int64))) public accounts;


  // This is the constructor which registers the owner, manager, number of accounts, encrypted map
  constructor(
    address _keyManager,
    uint8 _numAccounts,
    string _eMap,
    int64[] _breaks,
    int8[] _rates
  )
    public
  {
    require(_breaks.length == _rates.length, "Number of breaks must equal number of rates");

    keyOwner = msg.sender;              // owner key is msg.sender
    keyManager = _keyManager;           // manager key
    numAccounts = _numAccounts;         // number of accounts
    eMap = _eMap;                       // encrypted map
    breaks = _breaks;                   // break points
    rates = _rates;                     // rates
  }

//***************** Modifiers *****************//

  // Ensures the year is correct
  modifier isValidYear(uint16 _Year) {
    require(_Year > 2017, 'Invalid year');
    require(_Year < 2048, 'Invalid year');
    _;
  }

  // Ensures the quarter is correct
  modifier isValidQuarter(uint8 _Quarter) {
    require(_Quarter > 0, 'Invalid quarter');
    require(_Quarter < 5, 'Invalid quarter');
    _;
  }

  // Ensures the account number is correct
  modifier isValidAccount(uint8 _Account) {
    require(_Account < numAccounts, 'Invalid account number');
    _;
  }



//*********** EVENTS **************************//

  event ReportAum(int);
  event ReportSplits(int64[]);
  event ReportFeeTotal(uint);

//*********** EXTERNAL FUNCTIONS **************//

  // Specify the year, quarter, account number and value
  function setAccountValue(
    uint16 _year,
    uint8 _quarter,
    uint8 _account,
    int64 _value
  )
    isValidYear(_year)
    isValidQuarter(_quarter)
    isValidAccount(_account)
    public
    returns (int64)
  {
    accounts[_year][_quarter][_account] = _value;
    return _value;
  }

  // getAccountValue
  function getAccountValue(
    uint16 _year,
    uint8 _quarter,
    uint8 _account
  )
    isValidYear(_year)
    isValidQuarter(_quarter)
    isValidAccount(_account)
    public
    view
    returns (int64)
  {
    return accounts[_year][_quarter][_account];
  }

  // getAccountValues
  function getAccountValues(
    uint16 _year,
    uint8 _quarter
  )
    isValidYear(_year)
    isValidQuarter(_quarter)
    public
    view
    returns (int64[])
  {
    int64[] values;
    
    for (uint8 i = 0; i < numAccounts; i++) {
      values[i] = accounts[_year][_quarter][i];
    }

    return values;
  }

  // getFeeSchedule
  function getFeeSchedule()
    public
    view
    returns (int64[], int64[])
  {
    
  }


  function calculate(
    uint16 _year,
    uint8 _quarter
  )
    public
    view
    isValidYear(_year)
    isValidQuarter(_quarter)
    //returns(
    //     sha3 hash //contract number (so as to reference the hardcopy contract, etc.)
    //     household 
    //     account number
    //     fee structure // variable
    //     contract (when it was signed and cast)
    //     quarter it calculated fees for
    //     account value 
    //     resulting amount due
    //     (all the blockchain info to verify data)    
    // )
  {
    
    // Account Scope by year/quarter
    mapping(uint8 => int64) target = accounts[_year][_quarter];

    uint8 i; // universal iterator // ignore for the most part

    int64 aum = 0; // set total to zero // assets under management total across accounts

    uint256 feeTotal = 0;   // total fee from all accounts
    int64[] splits;  // splits holds the grandTotal stratified by breaks // 1m, 2m, 1.43m on 4,430,000
    int64[] feesBySplit; // fees spread across accounts // .10 * 1m, .08 * 2m, .6 * 1.43m on 4,430,000
    int64[] spread;  //
    int64[] feesByAccount; // fees spread across accounts



    // loop through accounts and return total aum
    for (i = 0; i < numAccounts; i++) {
      aum += target[i];
    }

    emit ReportAum(aum);
    
    // loop through breaks and chop up grandTotal
    // should yeild 1m, 2m, 1.43m on 4,430,000
    int64 tempAum = aum;
    for (i = uint8(breaks.length); i >= 0; i--) {
      splits[i] = int64(ceil(uint256(breaks[i]), uint256(tempAum))); // use ceil for grabbing everything off the bottom of the total up to a max (breaks[i])
      tempAum = int64(sub(uint256(tempAum), uint256(splits[i]))); // even if splits or remainder are zero, this should work (0 - 0)
    }

    emit ReportSplits(splits);

    // loop through accounts and return total fee
    for (i = 0; i < splits.length; i++) {
      feeTotal += div(mul(uint256(splits[i]), uint256(rates[i])), 1000000);
    }

    emit ReportFeeTotal(feeTotal);

  }



//*********** HELPERS *************************//

  function ceil(uint a, uint m) internal pure returns (uint) {
    return ((a + m - 1) / m) * m;
  }


//*********** SAFE MATH ***********************//

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */

  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */

  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

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