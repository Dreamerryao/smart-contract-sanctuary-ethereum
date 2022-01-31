/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

// SPDX-License-Identifier: MIT
// The line above is recommended and let you define the license of your contract
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.

pragma solidity ^0.8.9;

// tutorial-hardhat-deploy
// This is the main building block for smart contracts.
contract MyOracle {
    // An address type variable is used to store ethereum accounts.
    address public owner;
    address[] public addresses;

    struct Location {
        string lat;
        string lon;
        string name;
    }

    mapping(address => bool) public whitelistAddress;
    mapping(address => uint256) public values;
    mapping(uint8 => Location) public sensorLocation;


    uint256[10] public arr;
    Location[10] public locations;

    event OracleUpdate(address indexed sender, uint256 idx, uint256 value);

    function get(uint256 i) public view returns (uint256) {
        return arr[i];
    }

    function getArr() public view returns (uint256[10] memory) {
        return arr;
    }

    function set(uint256 i, uint256 value) public {
        arr[i] = value;
        emit OracleUpdate(msg.sender, i, value);
    }

    function setArr(uint256[10] memory _values) public {
        arr = _values;
    }

    function getLength() public view returns (uint256) {
        return arr.length;
    }

    function remove(uint256 index) public {
        delete arr[index];
    }

    function addWhitelist(address _contract) external {
        require(_contract != address(0), "Invalid address");
        require(!whitelistAddress[_contract], "Already whitelisted");
        whitelistAddress[_contract] = true;
    }

    function removeWhitelist(address _contract) external {
        require(whitelistAddress[_contract], "Address not found");
        delete whitelistAddress[_contract];
    }



    /**
     * Contract initialization.
     *
     * The `constructor` is executed only once when the contract is created.
     */
    constructor(address _owner) {
        owner = _owner;
    }

    /**
     * A function to updateValue tokens.
     *
     * The `external` modifier makes a function *only* callable from outside
     * the contract.
     */
    function updateValue(address to, uint256 amount) external returns (uint256) {
        if (values[to] == 0) {
            addresses.push(to);
        }
        // addresses.push(to);
        values[to] = amount;
        return values[to];
    }

    function getAddressList() external view returns (address[] memory) {
        return addresses;
    }

    /**
     * Read only function to retrieve the token balance of a given account.
     *
     * The `view` modifier indicates that it doesn't modify the contract's
     * state, which allows us to call it without executing a transaction.
     */
    function valueOf(address account) external view returns (uint256) {
        return values[account];
    }

    function getValueAt(address account) external view returns (uint256) {
        return values[account];
    }



    function balanceOf(address account) external view returns (uint256) {
        return values[account];
    }

    function dummy() external pure returns (string memory) {
        return "hey";
    }
}