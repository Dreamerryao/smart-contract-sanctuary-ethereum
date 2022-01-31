/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

struct NftToken {
    uint tokenId;
    string tokenURI;
}

contract EncodeTest
{
    /*
    function encodeTest(
        address _recipient,
        uint256 _fromChainId,
        uint256 _fromChainTeleportId,
        uint256 _originalTokenChainId,
        address _originalTokenAddr,
        string memory _name,
        string memory _symbol,
        NftToken[] calldata _tokens) external pure returns (bytes memory) {

        return abi.encodeWithSignature(
            "sign(address,uint256,uint256,uint256,address,string,string,(uint256,string)[])",
            _recipient,
            _fromChainId,
            _fromChainTeleportId,
            _originalTokenChainId,
            _originalTokenAddr,
            _name,
            _symbol,
            _tokens);
    }*/
    
    function encodeTest(
        address _msgSender,
        address _fromAsset,
        uint256 _fromAmount,
        uint256 _toExpectedAmount,
        uint32 _refCode,
        uint256 _timestamp) external pure returns (bytes memory) {

        return abi.encodePacked(
            _msgSender,
            _fromAsset,
            _fromAmount,
            _toExpectedAmount,
            _refCode,
            _timestamp);
    }
}