/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
contract GoodBytes {
    address public teacher;
    uint nrOfDiplomas;
    struct Diploma {
        string name;
        uint score;
    }
    mapping(address => Diploma) public diplomas;
    
    constructor(){
        teacher = msg.sender;
        nrOfDiplomas = 0;
    }
    
    function mintDiploma(address studentAddress, string memory studentName, uint studentScore) public {
        require(msg.sender == teacher, "Only the teacher can mint diplomas");
        require(diplomas[studentAddress].score == 0, "Diploma already exists.");
        diplomas[studentAddress] = Diploma(studentName, studentScore); 
        nrOfDiplomas++;
    }
    
    function getMyDiploma(address studentAddress) external view returns (Diploma memory) {
        return diplomas[studentAddress];
    }

}