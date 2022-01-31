/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

// SPDX-License-Identifier: None

pragma solidity ^0.8.3;

interface ICertificateDirectory {
    function addToDirectory(address _certificate, uint256 _serialNumber)
        external;
}

pragma solidity ^0.8.4;

contract Certificate {
    string public name;
    string public field;
    string public certificateType;
    uint256 public issueTime;
    uint256 public expireTime;
    uint256 public serialNumber;
    bool public revoke;
    address public addressDirectory;

    constructor(
        string memory _name,
        string memory _field,
        string memory _certificateType,
        uint256 _expireTime,
        uint256 _serialNumber
    ) {
        name = _name;
        field = _field;
        certificateType = _certificateType;
        issueTime = block.timestamp;
        expireTime = _expireTime;
        serialNumber = _serialNumber;
        revoke = false;
        addressDirectory = 0x7832F10D1548d59D93CACFAA87f19fec39FCFC67;
        ICertificateDirectory certificateDirectory = ICertificateDirectory(
            addressDirectory
        );
        certificateDirectory.addToDirectory(address(this), serialNumber);
    }

    function RevokeCertificate() public {
        revoke = true;
    }
}