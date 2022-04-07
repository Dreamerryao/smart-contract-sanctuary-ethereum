/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract SimpleStorage{
    uint256 favoriteNumber;
    event storedNumber(
        uint256 indexed oldNumber,
        uint256 indexed newNumber,
        uint256 addedNumber,
        address sender
    );
    function store(uint256 _favoriteNumber) public{
        emit storedNumber(
            favoriteNumber,
            _favoriteNumber,
            favoriteNumber+_favoriteNumber,
            msg.sender
        );
        favoriteNumber=_favoriteNumber;
    }
    function getF()public view returns(uint256){
        return favoriteNumber;
    }
}