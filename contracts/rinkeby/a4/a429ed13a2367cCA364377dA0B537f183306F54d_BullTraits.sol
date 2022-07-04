// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/ITraits.sol";
import "./interfaces/IRunnerBull.sol";

contract BullTraits is Ownable, ITraits {

  using Strings for uint256;

  // struct to store each trait's data for metadata and rendering
  struct Trait {
    string name;
    string png;
  }

  // mapping from trait type (index) to its name
  string[9] _traitTypes = [
    "Fur",
    "Head",
    "Ears",
    "Eyes",
    "Nose",
    "Mouth",
    "Neck",
    "Feet",
    "Alpha"
  ];
  // storage of each traits name and base64 PNG data
  // mapping(uint8 => mapping(uint8 => Trait)) public traitData;
  mapping(DataTypes.GameType => mapping( uint8 => mapping(uint8 => Trait)))  public traitData;
  // mapping from alphaIndex to its score
  string[4] _alphas = [
    "8",
    "7",
    "6",
    "5"
  ];

  string public defaultTrait;

  IRunnerBull public bull;

  constructor(string memory _defautTrait) {
    defaultTrait = _defautTrait;
  }

  /** ADMIN */

  function setBull(address _bull) external onlyOwner {
    bull = IRunnerBull(_bull);
  }

  /**
   * administrative to upload the names and images associated with each trait
   * @param traitType the trait type to upload the traits for (see traitTypes for a mapping)
   * @param traits the names and base64 encoded PNGs for each trait
   */
  function uploadTraits(DataTypes.GameType gameType, uint8 traitType, uint8[] calldata traitIds, Trait[] calldata traits) external onlyOwner {
    require(traitIds.length == traits.length, "Mismatched inputs");
    for (uint i = 0; i < traits.length; i++) {
      traitData[gameType][traitType][traitIds[i]] = Trait(
        traits[i].name,
        traits[i].png
      );
    }
  }

  /** RENDER */

  /**
   * generates an <image> element using base64 encoded PNGs
   * @param trait the trait storing the PNG data
   * @return the <image> element
   */
  function drawTrait(Trait memory trait) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
      trait.png,
      '"/>'
    ));
  }

  
  function isEmptyString(string memory str) internal pure returns (bool) {
    return bytes(str).length == 0;
  }

  function concatenate(string memory s1, string memory s2) internal pure returns (string memory) {
        return string(abi.encodePacked(s1, s2));
    }

  /**
   * generates an entire SVG by composing multiple <image> elements of PNGs
   * @param tokenId the ID of the token to generate an SVG for
   * @return a valid SVG of the Worker / Stealer
   */
  function drawSVG(uint256 tokenId) public view returns (string memory) {
    IRunnerBull.RunnerBull memory s = bull.getTokenTraits(tokenId);

    // uint8 shift = s.nftType == DataTypes.NFTType.WORKER ? 0 : 9;
    uint8 shift = s.nftType == DataTypes.NFTType.WORKER ? 0 : s.nftType == DataTypes.NFTType.STEALER ? 9 : s.nftType == DataTypes.NFTType.MANAGER ? 18 : 0;
    bool _isWorker = s.nftType == DataTypes.NFTType.WORKER;
    // bool _isStealer = s.nftType == DataTypes.NFTType.STEALER;
    // bool _isManager = s.nftType == DataTypes.NFTType.MANAGER;
   

    Trait memory sfur = traitData[s.gameType][0 + shift][s.fur];
    Trait memory shead = _isWorker ? traitData[s.gameType][1 + shift][s.head] : traitData[s.gameType][1 + shift][s.alphaIndex];
    Trait memory sEar = _isWorker ? traitData[s.gameType][2 + shift][s.ears] : Trait('','');
    Trait memory sEyes = traitData[s.gameType][3 + shift][s.eyes];
    Trait memory sNose = _isWorker ? traitData[s.gameType][4 + shift][s.nose] : Trait('','');
    Trait memory sMouth = traitData[s.gameType][5 + shift][s.mouth];
    Trait memory sNeck = _isWorker ?  Trait('','') : traitData[s.gameType][6 + shift][s.neck];
    Trait memory sFeet = _isWorker ? traitData[s.gameType][7 + shift][s.feet] : Trait('','');


    if (isEmptyString(sfur.png) && isEmptyString(shead.png) && isEmptyString(sEar.png) && isEmptyString(sEyes.png) && isEmptyString(sNose.png) && isEmptyString(sMouth.png) && isEmptyString(sNeck.png) && isEmptyString(sFeet.png) ) {
      return '';
    }

    string memory svgString = string(abi.encodePacked(
      drawTrait(sfur),
      drawTrait(shead),
      drawTrait(sEar),
      drawTrait(sEyes),
      drawTrait(sNose),
      drawTrait(sMouth),
      drawTrait(sNeck),
      drawTrait(sFeet)      
    ));

    return string(abi.encodePacked(
      '<svg id="stealer" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
      svgString,
      "</svg>"
    ));
  }

  /**
   * generates an attribute for the attributes array in the ERC721 metadata standard
   * @param traitType the trait type to reference as the metadata key
   * @param value the token's trait associated with the key
   * @return a JSON dictionary for the single attribute
   */
  function attributeForTypeAndValue(string memory traitType, string memory value) internal pure returns (string memory) {
    return string(abi.encodePacked(
      '{"trait_type":"',
      traitType,
      '","value":"',
      value,
      '"}'
    ));
  }

  /**
   * generates an array composed of all the individual traits and values
   * @param tokenId the ID of the token to compose the metadata for
   * @return a JSON array of all of the attributes for given token ID
   */
  function compileAttributes(uint256 tokenId) public view returns (string memory) {
    IRunnerBull.RunnerBull memory s = bull.getTokenTraits(tokenId);
    string memory traits;
    bool _isWorker = s.nftType == DataTypes.NFTType.WORKER;
    bool _isStealer = s.nftType == DataTypes.NFTType.STEALER;
    bool _isManager = s.nftType == DataTypes.NFTType.MANAGER;
    if (_isWorker) {
      traits = string(abi.encodePacked(
        attributeForTypeAndValue(_traitTypes[0], traitData[s.gameType][0][s.fur].name),',',
        attributeForTypeAndValue(_traitTypes[1], traitData[s.gameType][1][s.head].name),',',
        attributeForTypeAndValue(_traitTypes[2], traitData[s.gameType][2][s.ears].name),',',
        attributeForTypeAndValue(_traitTypes[3], traitData[s.gameType][3][s.eyes].name),',',
        attributeForTypeAndValue(_traitTypes[4], traitData[s.gameType][4][s.nose].name),',',
        attributeForTypeAndValue(_traitTypes[5], traitData[s.gameType][5][s.mouth].name),',',
        attributeForTypeAndValue(_traitTypes[7], traitData[s.gameType][7][s.feet].name),','
      ));
    } else if (_isStealer){
      traits = string(abi.encodePacked(
        attributeForTypeAndValue(_traitTypes[0], traitData[s.gameType][9][s.fur].name),',',
        attributeForTypeAndValue(_traitTypes[1], traitData[s.gameType][10][s.alphaIndex].name),',',
        attributeForTypeAndValue(_traitTypes[3], traitData[s.gameType][12][s.eyes].name),',',
        attributeForTypeAndValue(_traitTypes[5], traitData[s.gameType][14][s.mouth].name),',',
        attributeForTypeAndValue(_traitTypes[6], traitData[s.gameType][15][s.neck].name),',',
        attributeForTypeAndValue("Alpha Score", _alphas[s.alphaIndex]),','
      ));
    } else if (_isManager) {
      traits = string(abi.encodePacked(
        attributeForTypeAndValue(_traitTypes[0], traitData[s.gameType][18][s.fur].name),',',
        attributeForTypeAndValue(_traitTypes[1], traitData[s.gameType][19][s.alphaIndex].name),',',
        attributeForTypeAndValue(_traitTypes[3], traitData[s.gameType][21][s.eyes].name),',',
        attributeForTypeAndValue(_traitTypes[5], traitData[s.gameType][23][s.mouth].name),',',
        attributeForTypeAndValue(_traitTypes[6], traitData[s.gameType][24][s.neck].name),',',
        attributeForTypeAndValue("Alpha Score For Manager", _alphas[s.alphaIndex]),','
      ));
    }
    return string(abi.encodePacked(
      '[',
      traits,
      '{"trait_type":"Generation","value":',
      tokenId <= bull.getPaidTokens() ? '"Gen 0"' : '"Gen 1"',
      '},{"trait_type":"Type","value":',
      _isWorker ? '"Worker"' : _isStealer ? '"Stealer"' : _isManager ? '"Manager"' : '"Unknown"',
      '}]'
    ));
  }

  /**
   * generates a base64 encoded metadata response without referencing off-chain content
   * @param tokenId the ID of the token to generate the metadata for
   * @return a base64 encoded JSON dictionary of the token's metadata and SVG
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    IRunnerBull.RunnerBull memory s = bull.getTokenTraits(tokenId);
    bool _isWorker = s.nftType == DataTypes.NFTType.WORKER;
    bool _isStealer = s.nftType == DataTypes.NFTType.STEALER;
    bool _isManager = s.nftType == DataTypes.NFTType.MANAGER;


    string memory gameType;
    if (s.gameType == DataTypes.GameType.CADET_ALIEN) {
      
      gameType = 'CADET_ALIEN';
    }
    if (s.gameType == DataTypes.GameType.RUNNER_BULL) {
      
      gameType = 'RUNNER_BULL';
    }
    if (s.gameType == DataTypes.GameType.CAT_DOG) {
      
      gameType = 'CAT_DOG';
    }
    if (s.gameType == DataTypes.GameType.BAKER_FOODY) {
      
      gameType = 'BAKER_FOODY';
    }

    string memory svg = drawSVG(tokenId);


    string memory metadata = string(abi.encodePacked(
      '{"name": "',
      _isWorker ? 'Worker #' : _isStealer ? 'Stealer #' : _isManager ? 'Manager #' : 'Unknown #',
      tokenId.toString(),
      '", "description": "Thousands of Worker and Stealers compete on a farm in the metaverse. A tempting prize of $TOPIA awaits, with deadly high stakes. All the metadata and images are generated and stored 100% on-chain. No IPFS. NO API. Just the Ethereum blockchain."',
      ', "image":', isEmptyString(svg) ? concatenate(concatenate('"' , defaultTrait) , '"') : concatenate(concatenate(' "data:image/svg+xml;base64,' , base64(bytes(drawSVG(tokenId)))) , '"'),
      ', "attributes":',
      compileAttributes(tokenId),
      ', "gameType":"',gameType, '"'
      '}'
    ));


    return string(abi.encodePacked(
      "data:application/json;base64,",
      base64(bytes(metadata))
    ));
  }

  /** BASE 64 - Written by Brech Devos */
  
  string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  function base64(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return '';
    
    // load the table into memory
    string memory table = TABLE;

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((data.length + 2) / 3);

    // add some extra buffer at the end required for the writing
    string memory result = new string(encodedLen + 32);

    assembly {
      // set the actual output length
      mstore(result, encodedLen)
      
      // prepare the lookup table
      let tablePtr := add(table, 1)
      
      // input ptr
      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))
      
      // result ptr, jump over length
      let resultPtr := add(result, 32)
      
      // run over the input, 3 bytes at a time
      for {} lt(dataPtr, endPtr) {}
      {
          dataPtr := add(dataPtr, 3)
          
          // read 3 bytes
          let input := mload(dataPtr)
          
          // write 4 characters
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
          resultPtr := add(resultPtr, 1)
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
          resultPtr := add(resultPtr, 1)
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
          resultPtr := add(resultPtr, 1)
          mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
          resultPtr := add(resultPtr, 1)
      }
      
      // padding with '='
      switch mod(mload(data), 3)
      case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
      case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
    }
    
    return result;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT LICENSE 

pragma solidity 0.8.7;

interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.7;

import { DataTypes } from "../libraries/DataTypes.sol";


interface IRunnerBull {

  // struct to store each token's traits
  struct RunnerBull {

    uint8 fur;
    uint8 head;
    uint8 ears;
    uint8 eyes;
    uint8 nose;
    uint8 mouth;
    uint8 neck;
    uint8 feet;
    uint8 alphaIndex;
    DataTypes.GameType gameType;
    DataTypes.NFTType nftType;
  }


  function getPaidTokens() external view returns (uint256);
  function getTokenTraits(uint256 tokenId) external view returns (RunnerBull memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

library DataTypes {

    enum GameType {
        AVOID_ZERO,
        CADET_ALIEN, 
        RUNNER_BULL,
        CAT_DOG,
        BAKER_FOODY
    }

    enum NFTType {
        AVOID_ZERO,
        WORKER,
        STEALER,
        MANAGER
    }

}