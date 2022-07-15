// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StubAccessController {

  function hasAccess(address, bytes calldata) external pure returns (bool) {
      return true;
  }

}