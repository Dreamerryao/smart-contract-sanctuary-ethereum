// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract BoxV2 {
    uint public val;

    // function initialize(uint _val) external {
    //     val = _val;
    // }

    function inc() external {
        val += 1;
    }
}