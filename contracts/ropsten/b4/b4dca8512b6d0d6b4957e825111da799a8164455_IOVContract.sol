pragma solidity ^0.4.21;

// File: contracts/utils/StringUtils.sol

library StringUtils {
    /// @dev Does a byte-by-byte lexicographical comparison of two strings.
    /// @return a negative number if `_a` is smaller, zero if they are equal
    /// and a positive numbe if `_b` is smaller.
    function compare(string _a, string _b) internal pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }
    /// @dev Compares two strings and returns true iff they are equal.
    function equal(string _a, string _b) internal pure returns (bool) {
        return compare(_a, _b) == 0;
    }
    /// @dev Finds the index of the first occurrence of _needle in _haystack
    function indexOf(string _haystack, string _needle) internal pure returns (int)
    {
    	bytes memory h = bytes(_haystack);
    	bytes memory n = bytes(_needle);
    	if(h.length < 1 || n.length < 1 || (n.length > h.length)) 
    		return -1;
    	else if(h.length > (2**128 -1)) // since we have to be able to return -1 (if the char isn't found or input error), this function must return an "int" type with a max length of (2^128 - 1)
    		return -1;									
    	else
    	{
    		uint subindex = 0;
    		for (uint i = 0; i < h.length; i ++)
    		{
    			if (h[i] == n[0]) // found the first char of b
    			{
    				subindex = 1;
    				while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) // search until the chars don't match or until we reach the end of a or b
    				{
    					subindex++;
    				}	
    				if(subindex == n.length)
    					return int(i);
    			}
    		}
    		return -1;
    	}	
    }
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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
  function Ownable() public {
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
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/iov/IOVContract.sol

contract IOVContract is Ownable {

    using SafeMath for uint;
    using StringUtils for string;

    struct IOVInfo {
        string hashVal;
        uint timestamp;
        
        bool flag;
    }

    event evInsertHash(IOVInfo _info);

    event evUpdateHash(IOVInfo _info);

    uint public count = 0;
    
    string[] datetimes;

    mapping(string => IOVInfo) infos;

    modifier notOwner() {
        require(msg.sender != owner);
        _;
    }

    function IOVContract() public {
    }
    
    /*
    function compareStrings(string a, string b) internal pure returns (bool) {
       return keccak256(a) == keccak256(b);
    }*/

    function storeHash(string _datetime, string _hashVal) public onlyOwner {
        //require(!compareStrings(_datetime, "") && !compareStrings(_hashVal, ""));
        require(!_datetime.equal("") && !_hashVal.equal(""));

        bool b = infos[_datetime].flag;

        IOVInfo memory info = IOVInfo({hashVal: _hashVal, timestamp: now, flag: true});
        infos[_datetime] = info;

        if (!b) {
            datetimes.push(_datetime);
            count = count.add(1);
            emit evInsertHash(info);
        } else {
            emit evUpdateHash(info);
        }
    }

    function getTimestamp(string _datetime) public view returns (uint) {
        if (infos[_datetime].flag) {
            IOVInfo memory info = infos[_datetime];
            return info.timestamp;
        }
        return 0;
    }

    function getHash(string _datetime) public view returns (string) {
        if (infos[_datetime].flag) {
            IOVInfo memory info = infos[_datetime];
            return info.hashVal;
        }
        return "";
    }

    function getDateTime(uint _count) public view returns (string) {
        require(_count < count);
        return datetimes[_count];
    }

    function currentDateTime() public view returns (string) {
        if (count == 0) {
            return "";
        }
        return datetimes[count - 1];
    }

}