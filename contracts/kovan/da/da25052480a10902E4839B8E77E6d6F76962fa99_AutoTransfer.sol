/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

contract KeeperBase {
  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    require(tx.origin == address(0), "only for simulated backend");
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}
abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}
// import "https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.7/KeeperCompatible.sol";
contract AutoTransfer is KeeperCompatibleInterface {
    address payable to;
    uint value;
    uint frequency;
    uint lastTimeStamp;
    constructor(address payable _to, uint _value, uint _frequency) payable{
        to = _to;
        value = _value;
        frequency = _frequency;
        lastTimeStamp = block.timestamp;
    }

    function checkUpkeep(bytes calldata ) view external override returns(bool upkeepNeeded, bytes memory) {
        upkeepNeeded = (block.timestamp-lastTimeStamp) > frequency && address(this).balance > value;
    }

    function performUpkeep(bytes calldata) external override{
        lastTimeStamp = block.timestamp;
        _transfer();
    }

    function _transfer() internal{
        to.transfer(value);
    }

    receive() payable external{
    }
}