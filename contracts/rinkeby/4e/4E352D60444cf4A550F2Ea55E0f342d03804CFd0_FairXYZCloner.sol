// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFairXYZDeployer {
    function initialize(address _Owner, uint max_, uint price, string memory name_, string memory symbol_, bool burn_, uint256 max_mints_pw, 
                    address int_add_) external;
}

contract FairXYZCloner {

    address public implementation;

    mapping(address => address[]) public allClones;

    event NewClone(address _newClone, address _owner);

    constructor(address _implementation) {
        implementation = _implementation;
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address _implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, _implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    function _clone(uint max_, uint price, string memory _name, string memory _symbol, bool burnable_, uint256 Max_mints_pw, address interface_addy) external {
        address identicalChild = clone(implementation);
        allClones[msg.sender].push(identicalChild);
        IFairXYZDeployer(identicalChild).initialize(msg.sender, max_, price, _name, _symbol, burnable_, Max_mints_pw, interface_addy);
        emit NewClone(identicalChild, msg.sender);
    }

    function returnClones(address _owner) external view returns (address[] memory){
        return allClones[_owner];
    }

}