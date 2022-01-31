// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";


contract ERC20FixedSupply is ERC20 {

        constructor(uint256 fixedSupply, string memory name_, string memory symbol_) ERC20(name_, symbol_) {
            _mint(msg.sender, fixedSupply);
            }
}