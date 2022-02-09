/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;



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
    mapping(address => uint256) public addressToAmountFunded;
    address owner;
    address[] public funders;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function fund() public payable onlyOwner {
        uint256 minimumUSD = 5 * 10**18;
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH !!"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    // Get Eth/USD conversion rate
    function getPrice() public view onlyOwner returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1000000000);
    }

    //1000000000
    function getConversionRate(uint256 ethAmount)
        public
        view
        onlyOwner
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmmountInUSD = (ethPrice * ethAmount) / 10**18;
        return ethAmmountInUSD;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 fundersIndex = 0;
            fundersIndex < funders.length;
            fundersIndex++
        ) {
            address funder = funders[fundersIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}