/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

pragma solidity ^0.4.22;

contract assignmentTwo {
    
    uint public studentNumber;
    uint public GasUsed;
    address public student;
    
    constructor() public {
        student = msg.sender;
    }
    
    function setGasUsed(uint _gasUsed) public {
        GasUsed = _gasUsed;
    }
    function setStudentNumber(uint _studentNumber) public {
        studentNumber = _studentNumber;
    }
       
}