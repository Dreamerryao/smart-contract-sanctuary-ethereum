/**
 *Submitted for verification at Etherscan.io on 2021-10-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

interface SquidGameCard {

    function ownerOf(uint256 _tokenId) external view returns (address);
    function getGenes(uint256 _tokenId) external view returns (uint8[8] memory);
    function getConsonants(uint256 _tokenId) external view returns (string[3] memory);
    function getConsonantsIndex(uint256 _tokenId) external view returns (uint8[3] memory);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

contract MorphedCard {

    address private mainCardAddress;
    address private deployer;

    constructor(address _mainCardAddress) {
        require(address(_mainCardAddress) != address(0), "token is the zero address");
        deployer = msg.sender;
        mainCardAddress = _mainCardAddress;
    }

    function updateMainCardAddress(address _mainCardAddress) external {
        require(_mainCardAddress != address(0), "Bad main card address");
        require(msg.sender == deployer, "You're not allowed");
        mainCardAddress = _mainCardAddress;
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        return SquidGameCard(mainCardAddress).ownerOf(_tokenId);
    }

    function getGenes(uint256 _tokenId) public view returns (uint8[8] memory) {
        return SquidGameCard(mainCardAddress).getGenes(_tokenId);
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        return SquidGameCard(mainCardAddress).tokenURI(_tokenId);
    }

    function getConsonants(uint256 _tokenId) public view returns (string[3] memory) {
        return SquidGameCard(mainCardAddress).getConsonants(_tokenId);
    }
    function getConsonantsIndex(uint256 _tokenId) public view returns (uint8[3] memory) {
        return SquidGameCard(mainCardAddress).getConsonantsIndex(_tokenId);
    }

    function customizedTokenURI(uint256 _tokenId, string calldata bgImageURI, string calldata fontColor) external view returns (string memory) {      
        
        string[7] memory parts;
        string[16] memory attrParts;
        uint8[8] memory geneArray = getGenes(_tokenId);
        string[3] memory consArray = getConsonants(_tokenId);
        uint8[3] memory consIndex = getConsonantsIndex(_tokenId);        

        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 220"><style>.base {font-family: Verdana; fill: ';
        // font color
        parts[1] = ';}</style><image width="350" height="220" xlink:href="';
        // background image url
        parts[2] = '"/><text x="50%" y="100" dominant-baseline="middle" text-anchor="middle" class="base" style="font-size:700%; letter-spacing: -0.2em;">';
        parts[3] = string(abi.encodePacked(consArray[0], ' ', consArray[1], ' ', consArray[2]));
        parts[4] = '</text><text x="50%" y="180" dominant-baseline="middle" text-anchor="middle" class="base" style="font-size:150%;">&#937; ';
        parts[5] = string(abi.encodePacked(toString(geneArray[0]), toString(geneArray[1]), toString(geneArray[2]), toString(geneArray[3]), ' '));
        parts[6] = string(abi.encodePacked(toString(geneArray[4]), toString(geneArray[5]), toString(geneArray[6]), toString(geneArray[7]), '</text></svg>'));

        string memory output = string(abi.encodePacked(parts[0], fontColor, parts[1], bgImageURI, parts[2], parts[3]));
        output = string(abi.encodePacked(output, parts[4], parts[5], parts[6]));

        string memory attrs = string(abi.encodePacked('[{"trait_type": "Left Consonant", "value": "', consArray[0], '"}, {"trait_type": "Center Consonant", "value": "', consArray[1]));
        attrs = string(abi.encodePacked(attrs, '"}, {"trait_type": "Right Consonant", "value": "', consArray[2], '"}, {"trait_type": "Gene0", "value": "', toString(geneArray[0])));

        attrParts[0] = '"}, {"trait_type": "Gene1", "value": "';
        attrParts[1] = toString(geneArray[1]);
        attrParts[2] = '"}, {"trait_type": "Gene2", "value": "';        
        attrParts[3] = toString(geneArray[2]);
        attrParts[4] = '"}, {"trait_type": "Gene3", "value": "';        
        attrParts[5] = toString(geneArray[3]);
        attrParts[6] = '"}, {"trait_type": "Gene4", "value": "';        
        attrParts[7] = toString(geneArray[4]);
        attrParts[8] = '"}, {"trait_type": "Gene5", "value": "';        
        attrParts[9] = toString(geneArray[5]);
        attrParts[10] = '"}, {"trait_type": "Gene6", "value": "';        
        attrParts[11] = toString(geneArray[6]);
        attrParts[12] = '"}, {"trait_type": "Gene7", "value": "';        
        attrParts[13] = toString(geneArray[7]);
        if (consIndex[0] == 7 && consIndex[1] == 14 && consIndex[2] == 4) {
            attrParts[14] = '"}, {"trait_type": "Ojingeo", "value": "Y"}, {"trait_type": "Same Consonants", "value": "';
        } else {
            attrParts[14] = '"}, {"trait_type": "Ojingeo", "value": "N"}, {"trait_type": "Same Consonants", "value": "';
        }
        if (consIndex[0] == consIndex[1] && consIndex[0] == consIndex[2]) {
            attrParts[15] = 'Y"}]';
        } else {
            attrParts[15] = 'N"}]';
        }

        attrs = string(abi.encodePacked(attrs, attrParts[0], attrParts[1], attrParts[2], attrParts[3], attrParts[4], attrParts[5], attrParts[6], attrParts[7]));
        attrs = string(abi.encodePacked(attrs, attrParts[8], attrParts[9], attrParts[10], attrParts[11], attrParts[12], attrParts[13], attrParts[14], attrParts[15]));
        
        output = Base64.encode(bytes(string(abi.encodePacked('{"name": "Korean Consonants Card NFT #', toString(_tokenId), '", "attributes": ', attrs ,', "description": "The Korean Consonants cards are invitation to enter the adventurous and mysterious metaverse games. Genes characteristics and other functionality are intentionally omitted for unlimited imagination and community-driven game development. Start your journey now!", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        return string(abi.encodePacked('data:application/json;base64,', output));
    }

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}