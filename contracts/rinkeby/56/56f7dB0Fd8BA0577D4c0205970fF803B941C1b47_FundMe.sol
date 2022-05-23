//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import "AggregatorV3Interface.sol";
contract FundMe
{
    mapping(address=>uint256) public addressToValue;
    address[] public funders;
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    
    function Fund() public payable
    {
        //minimum $50
        //require(getConversionRate(msg.value)>=50*10**18,"You need to spend extra eth!");
        addressToValue[msg.sender]+=msg.value;
        funders.push(msg.sender);
    }
    // function getVersion() public view returns (uint256)
    // {
    //     AggregatorV3Interface PriceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    //     return PriceFeed.version();
    // }
    function getPrice() public view returns (uint256)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (
            //uint80 roundId,
            ,int256 answer,,,
            //uint256 startedAt,
            //uint256 updatedAt,
            //uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    function getConversionRate(uint256 ethAmount) public view returns(uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = ethPrice*ethAmount;
        return ethAmountInUSD;
        //208517977818000000000
    }

    modifier ownerCheck{
        require(owner == msg.sender);
        _;
    }

    function withdraw() payable ownerCheck public{
        
        payable(msg.sender).transfer(address(this).balance);
        for(uint256 funderindex=0;funderindex<funders.length;funderindex++)
        {
            address funder = funders[funderindex];
            addressToValue[funder]=0;
        }
        funders = new address[](0); 
    }

    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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