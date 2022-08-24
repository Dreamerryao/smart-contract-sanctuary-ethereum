/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// File: contracts/DaughterContract.sol


pragma solidity ^0.8.10;

contract DaughterContract {
  string public name;
  uint public age;
  constructor(
    string memory _daughtersName,
    uint _daughtersAge
  ) {
    name = _daughtersName;
    age = _daughtersAge;
  }
}
// File: contracts/MomContract.sol


pragma solidity ^0.8.10;

contract MomContract {
  string public name;
  uint public age;
  DaughterContract public daughter;
  constructor(
    string memory _momsName,
    uint _momsAge,
    string memory _daughtersName,
    uint _daughtersAge
  ) {
    daughter = new DaughterContract(_daughtersName, _daughtersAge);
    name = _momsName;
    age = _momsAge;
  }
}