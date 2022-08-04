// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: moon moth'
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                           //
//                                                                                                                                                                                           //
//    𝖎𝖓𝖘𝖙𝖎𝖓𝖈𝖙𝖍𝖊𝖆𝖉 𝖆𝖗𝖙𝖜𝖔𝖗𝖐 𝖈𝖔𝖑𝖑𝖊𝖈𝖙𝖎𝖔𝖓 𝖇𝖞 𝖉𝖆𝖗𝖐𝖓𝖔𝖔𝖛                                                                                                     //
//                                                                                                                                                                                           //
//    ℑ 𝔰𝔱𝔞𝔯𝔱𝔢𝔡 𝔡𝔯𝔞𝔴𝔦𝔫𝔤 𝔞𝔯𝔱𝔴𝔬𝔯𝔨𝔰 𝔬𝔣 𝔪𝔶 ℑ𝔫𝔰𝔱𝔦𝔫𝔠𝔱𝔥𝔢𝔞𝔡 𝔠𝔬𝔩𝔩𝔢𝔠𝔱𝔦𝔬𝔫 𝔬𝔫 19 𝔒𝔠𝔱𝔬𝔟𝔢𝔯 2021.                                                   //
//     ℌ𝔞𝔳𝔦𝔫𝔤 𝔞 𝔫𝔬𝔫-𝔠𝔬𝔫𝔠𝔢𝔭𝔱𝔲𝔞𝔩 𝔩𝔦𝔫𝔢 𝔦𝔫 𝔪𝔶 𝔣𝔦𝔯𝔰𝔱 𝔠𝔯𝔢𝔞𝔱𝔦𝔬𝔫 𝔦𝔫𝔰𝔭𝔦𝔯𝔢𝔡 𝔱𝔥𝔢 𝔰𝔲𝔟𝔧𝔢𝔠𝔱 𝔬𝔣 𝔪𝔶 𝔠𝔬𝔩𝔩𝔢𝔠𝔱𝔦𝔬𝔫.                      //
//     ℑ 𝔭𝔯𝔢𝔣𝔢𝔯 𝔱𝔬 𝔣𝔢𝔢𝔡 𝔬𝔫 𝔳𝔞𝔯𝔦𝔬𝔲𝔰 𝔪𝔢𝔞𝔫𝔦𝔫𝔤𝔰 𝔦𝔫 𝔞𝔟𝔰𝔱𝔯𝔞𝔠𝔱𝔦𝔬𝔫.                                                                                        //
//     ℑ 𝔱𝔥𝔦𝔫𝔨 𝔱𝔥𝔞𝔱 ℑ 𝔠𝔞𝔫 𝔟𝔯𝔦𝔫𝔤 𝔱𝔥𝔢 𝔞𝔲𝔡𝔦𝔢𝔫𝔠𝔢 𝔱𝔬𝔤𝔢𝔱𝔥𝔢𝔯 𝔦𝔫 𝔱𝔥𝔢 𝔪𝔦𝔡𝔡𝔩𝔢 𝔟𝔶                                                                      //
//    𝔪𝔞𝔨𝔦𝔫𝔤 𝔲𝔰𝔢 𝔬𝔣 𝔱𝔥𝔢 𝔦𝔫𝔱𝔢𝔯𝔰𝔢𝔠𝔱𝔦𝔬𝔫𝔰 𝔦𝔫 𝔱𝔥𝔢 𝔞𝔟𝔰𝔱𝔯𝔞𝔠𝔱 𝔱𝔬𝔲𝔠𝔥𝔢𝔰 𝔬𝔣 𝔪𝔶 𝔡𝔢𝔰𝔦𝔤𝔫𝔰,                                                       //
//    𝔞𝔭𝔞𝔯𝔱 𝔣𝔯𝔬𝔪 𝔱𝔥𝔢 𝔠𝔬𝔫𝔠𝔯𝔢𝔱𝔢 𝔣𝔯𝔞𝔪𝔢𝔰 𝔬𝔣 𝔱𝔥𝔢 𝔭𝔦𝔢𝔠𝔢𝔰 𝔱𝔥𝔞𝔱 ℑ 𝔞𝔦𝔪 𝔱𝔬 𝔪𝔞𝔨𝔢 𝔢𝔳𝔢𝔯𝔶𝔬𝔫𝔢                                                     //
//    𝔣𝔢𝔢𝔩 𝔡𝔦𝔣𝔣𝔢𝔯𝔢𝔫𝔱 𝔱𝔥𝔦𝔫𝔤𝔰 𝔞𝔫𝔡 𝔞𝔱 𝔱𝔥𝔢 𝔰𝔞𝔪𝔢 𝔱𝔦𝔪𝔢 ℑ 𝔴𝔞𝔫𝔱 𝔱𝔬 𝔱𝔢𝔩𝔩. ℑ'𝔪 𝔡𝔢𝔞𝔩𝔦𝔫𝔤 𝔴𝔦𝔱𝔥                                                   //
//    𝔣𝔢𝔢𝔩𝔦𝔫𝔤𝔰 𝔱𝔥𝔞𝔱 𝔭𝔢𝔬𝔭𝔩𝔢 𝔥𝔞𝔳𝔢 𝔡𝔦𝔰𝔱𝔞𝔫𝔠𝔢𝔡 𝔱𝔥𝔢𝔪𝔰𝔢𝔩𝔳𝔢𝔰 𝔣𝔯𝔬𝔪 𝔞𝔫𝔡 𝔱𝔥𝔢 𝔞𝔯𝔱𝔦𝔣𝔦𝔠𝔦𝔞𝔩 𝔟𝔢𝔥𝔞𝔳𝔦𝔬𝔯𝔰 𝔱𝔥𝔢𝔶                        //
//    𝔟𝔯𝔦𝔫𝔤 𝔦𝔫 𝔱𝔬𝔡𝔞𝔶'𝔰 𝔱𝔦𝔪𝔢. 𝔒𝔫𝔢 𝔬𝔣 𝔱𝔥𝔢 𝔰𝔲𝔟𝔧𝔢𝔠𝔱𝔰 ℑ 𝔴𝔞𝔰 𝔦𝔫𝔰𝔭𝔦𝔯𝔢𝔡 𝔟𝔶 𝔴𝔞𝔰 𝔱𝔥𝔞𝔱 𝔢𝔳𝔢𝔯𝔶𝔬𝔫𝔢 𝔦𝔰 𝔰𝔱𝔲𝔠𝔨 𝔦𝔫                       //
//    𝔰𝔱𝔢𝔯𝔢𝔬𝔱𝔶𝔭𝔦𝔠𝔞𝔩 𝔠𝔥𝔞𝔯𝔞𝔠𝔱𝔢𝔯𝔰 𝔞𝔫𝔡 𝔩𝔦𝔳𝔦𝔫𝔤 𝔞 𝔩𝔦𝔣𝔢 𝔞𝔴𝔞𝔶 𝔣𝔯𝔬𝔪 𝔱𝔥𝔢𝔦𝔯 𝔦𝔫𝔰𝔱𝔦𝔫𝔠𝔱𝔰. ℑ𝔫 𝔱𝔥𝔦𝔰 𝔠𝔬𝔩𝔩𝔢𝔠𝔱𝔦𝔬𝔫 𝔱𝔥𝔞𝔱            //
//    𝔡𝔢𝔞𝔩𝔰 𝔴𝔦𝔱𝔥 𝔰𝔭𝔦𝔯𝔦𝔱𝔲𝔞𝔩 𝔦𝔰𝔰𝔲𝔢𝔰, ℑ 𝔡𝔦𝔰𝔠𝔲𝔰𝔰 𝔱𝔥𝔢 𝔠𝔬𝔫𝔠𝔢𝔭𝔱 𝔬𝔣 '𝔪𝔞𝔱𝔲𝔯𝔢 𝔡𝔞𝔯𝔨𝔫𝔢𝔰𝔰'.                                                      //
//                                                                                                                                                                                           //
//     _, _  _,  _, _, _   _, _  _, ___ _,_ ,                                                                                                                                                //
//     |\/| / \ / \ |\ |   |\/| / \  |  |_| '                                                                                                                                                //
//     |  | \ / \ / | \|   |  | \ /  |  | |                                                                                                                                                  //
//     ~  ~  ~   ~  ~  ~   ~  ~  ~   ~  ~ ~                                                                                                                                                  //
//                                                                                                                                                                                           //
//                                                                                                                                                                                           //
//                                                                                                                                                                                           //
//       𝔐𝔬𝔬𝔫 𝔐𝔬𝔱𝔥' 𝔱𝔞𝔨𝔢𝔰 𝔱𝔥𝔢 𝔪𝔢𝔱𝔞𝔭𝔥𝔬𝔯 𝔬𝔣 𝔢𝔳𝔢𝔯𝔶 𝔥𝔲𝔪𝔞𝔫 𝔟𝔢𝔦𝔫𝔤 𝔞𝔰 𝔞 𝔪𝔬𝔱𝔥. ℑ𝔱 𝔩𝔢𝔞𝔳𝔢𝔰 𝔞 𝔱𝔯𝔢𝔢, 𝔴𝔥𝔦𝔠𝔥                              //
//    𝔦𝔱 𝔠𝔩𝔦𝔫𝔤𝔰 𝔱𝔬 𝔦𝔫 𝔱𝔥𝔢 𝔠𝔬𝔩𝔡 𝔱𝔬𝔫𝔢𝔰 𝔬𝔣 𝔱𝔥𝔢 𝔫𝔦𝔤𝔥𝔱, 𝔱𝔬 𝔱𝔥𝔢 𝔠𝔬𝔪𝔪𝔲𝔫𝔦𝔠𝔞𝔱𝔦𝔬𝔫 𝔬𝔣 𝔱𝔥𝔢 𝔭𝔬𝔴𝔢𝔯𝔣𝔲𝔩 𝔢𝔫𝔢𝔯𝔤𝔶 𝔦𝔱 𝔰𝔥𝔞𝔯𝔢𝔰      //
//    𝔴𝔦𝔱𝔥 𝔬𝔱𝔥𝔢𝔯 𝔪𝔬𝔱𝔥𝔰. 𝔐𝔶 𝔴𝔬𝔯𝔨 𝔦𝔰 𝔱𝔥𝔢 𝔰𝔥𝔞𝔯𝔦𝔫𝔤 𝔬𝔣 𝔱𝔥𝔦𝔰 𝔠𝔬𝔪𝔪𝔲𝔫𝔦𝔠𝔞𝔱𝔦𝔬𝔫. ℑ𝔱 𝔦𝔫𝔳𝔦𝔱𝔢𝔰 𝔢𝔞𝔠𝔥 𝔬𝔣 𝔲𝔰 𝔱𝔬 𝔢𝔵𝔭𝔢𝔯𝔦𝔢𝔫𝔠𝔢     //
//    𝔟𝔢𝔦𝔫𝔤 𝔪𝔬𝔱𝔥. ℑ 𝔱𝔥𝔦𝔫𝔨 𝔱𝔥𝔞𝔱 𝔱𝔥𝔢 𝔭𝔲𝔯𝔦𝔱𝔶 (𝔢𝔰𝔰𝔢𝔫𝔠𝔢) 𝔱𝔥𝔞𝔱 𝔢𝔳𝔢𝔯𝔶 𝔭𝔢𝔯𝔰𝔬𝔫 𝔰𝔥𝔬𝔲𝔩𝔡 𝔢𝔳𝔢𝔫𝔱𝔲𝔞𝔩𝔩𝔶 𝔯𝔢𝔱𝔲𝔯𝔫 𝔱𝔬 𝔟𝔯𝔦𝔫𝔤𝔰      //
//    𝔲𝔰 𝔱𝔬𝔤𝔢𝔱𝔥𝔢𝔯 𝔞𝔫𝔡 𝔦𝔱 𝔦𝔰 𝔞𝔠𝔱𝔲𝔞𝔩𝔩𝔶 𝔞 𝔠𝔯𝔢𝔞𝔱𝔦𝔬𝔫 𝔬𝔣 𝔞𝔡𝔞𝔪𝔰' 𝔰𝔱𝔞𝔤𝔦𝔫𝔤, 𝔴𝔥𝔦𝔠𝔥 𝔴𝔢 𝔠𝔞𝔩𝔩 𝔪𝔬𝔱𝔥' 𝔱𝔬 𝔦𝔱𝔰 𝔢𝔰𝔰𝔢𝔫𝔠𝔢. 𝔱𝔴𝔬     //
//     𝔡𝔦𝔣𝔣𝔢𝔯𝔢𝔫𝔱 𝔱𝔬𝔲𝔠𝔥𝔢𝔰 𝔱𝔥𝔞𝔱 𝔢𝔵𝔱𝔢𝔫𝔡 𝔱𝔬 𝔢𝔞𝔠𝔥 𝔬𝔱𝔥𝔢𝔯 𝔴𝔦𝔱𝔥 𝔯𝔢𝔞𝔩𝔦𝔱𝔶 𝔞𝔫𝔡 𝔬𝔲𝔯 𝔞𝔟𝔰𝔱𝔯𝔞𝔠𝔱 𝔢𝔰𝔰𝔢𝔫𝔠𝔢..                              //
//                                                                                                                                                                                           //
//                                                                                                                                                                                           //
//                                                                                                                                                                                           //
//                                                                                                                                                                                           //
//                                                                                                                                                                                           //
//                                                                                                                                                                                           //
//                                                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract moth is ERC721Creator {
    constructor() ERC721Creator("moon moth'", "moth") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x80d39537860Dc3677E9345706697bf4dF6527f72;
        Address.functionDelegateCall(
            0x80d39537860Dc3677E9345706697bf4dF6527f72,
            abi.encodeWithSignature("initialize(string,string)", name, symbol)
        );
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}