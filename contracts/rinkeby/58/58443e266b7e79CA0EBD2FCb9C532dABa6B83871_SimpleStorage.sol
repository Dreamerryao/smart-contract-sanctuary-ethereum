/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 favouriteNumber;

    constructor(uint256 _favouriteNumber) {
        favouriteNumber = _favouriteNumber;
    }

    function store(uint256 _favouriteNumber) public {
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }
}