/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// File: FundMe.sol

contract FundMe {
    mapping (address => uint256) public addresstoAmountFunded;
    address[] public funders;
    


    
    function fund() public payable {
        uint256 minimumUSD = 5*10**18;
        require(getConversionRate(msg.value) >= minimumUSD,"you need to spend more money"); 
        addresstoAmountFunded[msg.sender] += msg.value; 
        funders.push(msg.sender);
        
    }

    function getVersion() public view returns(uint256)
    {
        AggregatorV3Interface pricefeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return pricefeed.version();
    
    }

    function getPrice() public view returns(uint256)
    {
        AggregatorV3Interface pricefeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (
            ,int price,,,
        ) = pricefeed.latestRoundData();
        return uint256(price*10000000000);
    }
    function getConversionRate(uint256 ethAmount) public view returns(uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethAmount*ethPrice)/1000000000000000000;
        return ethAmountInUSD;
    }
    address public owner;

    constructor() public {
        owner = msg.sender;

    }

   

    function withdraw () payable public {
        require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++)
        {
            address funder = funders[funderIndex];
            addresstoAmountFunded[funder] = 0;
        }
         funders = new address[](0);
    }
 

}