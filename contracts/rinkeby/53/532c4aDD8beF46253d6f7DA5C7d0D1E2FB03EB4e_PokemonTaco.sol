/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0 < 0.9.0;
contract PokemonTaco {
    uint256 public num = 1337;
    function updateNum(uint256 _num) public {
        num = _num;
    }
}