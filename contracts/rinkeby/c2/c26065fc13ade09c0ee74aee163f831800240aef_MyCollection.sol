/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MyCollection {

    address public owner;
   

    struct Drop {
        string imageUri;
        string name;
        string description;
        string social_1;
        string social_2;
        string websiteUri;
        string price;
        uint256 supply;
        uint256 presale;
        uint256 sale;
        uint8 chain;
        bool approved;
    }


    Drop[] public drops;
    mapping(uint256 => address) public users;


    constructor() {
        
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, 'you are not the owner');
        _;
    }

    function addDrop(Drop memory _drop ) public{
        _drop.approved = false;
         drops.push(_drop);
        uint256 id = drops.length - 1;
        users[id] = msg.sender;
    }

    

  function getDrops() public view returns(Drop[] memory){
      return drops;
  }

  function updateDrop(
        uint256 _index, Drop memory _drop) public{
         require(msg.sender == users[_index], "you are not the owner of this drop");
        _drop.approved = false;
        drops[_index] = _drop;
    }

    function approveDrop(uint256 _index) onlyOwner public{
        Drop storage drop = drops[_index];
        drop.approved = true;
    }

}