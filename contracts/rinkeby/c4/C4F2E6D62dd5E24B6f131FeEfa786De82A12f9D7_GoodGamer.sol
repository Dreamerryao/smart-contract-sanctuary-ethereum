// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";

contract GoodGamer is ERC721Enumerable, AccessControl {
    using Strings for uint256;

    // ROLES
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant INIT_ROLE = keccak256("INIT_ROLE");
    // DROPS
    mapping(uint256 => bool) drop_initeds;
    mapping(uint256 => string) drop_names;
    mapping(uint256 => uint256) drop_start_dates;
    mapping(uint256 => uint256) drop_end_dates;
    mapping(uint256 => uint256) drop_maxes;
    mapping(uint256 => uint256) drop_prices;
    mapping(uint256 => uint256) tokens_drop;
    mapping(uint256 => uint256) drop_tokens;

    // CONSTRUCTOR
    constructor() ERC721("Good Gamer", "GG") {
        address owner = address(0x85c8c111AdfF6A98D6d915b0f9c6eE67186CC678);
        _setupRole(OWNER_ROLE, owner);
        _setupRole(INIT_ROLE, owner);
    }

    // OVERRIDE
    function tokenURI(uint256 token)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(token),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            string(
                abi.encodePacked(
                    baseURI,
                    "/",
                    getDropName(getDropOf(token)),
                    "/",
                    token.toString()
                )
            );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://www.goodgamer.gg/api/drop/";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721Enumerable)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    // OWNER
    function addOwner(bytes memory role, address someone)
        public
        onlyRole(OWNER_ROLE)
    {
        _setupRole(keccak256(role), someone);
    }

    function delOwner(bytes memory role, address someone)
        public
        onlyRole(OWNER_ROLE)
    {
        revokeRole(keccak256(role), someone);
    }

    function changeOwner(bytes memory role, address someone)
        public
        onlyRole(OWNER_ROLE)
    {
        addOwner(role, someone);
        delOwner(role, msg.sender);
    }

    // Init
    function init(
        uint256 drop,
        string memory name,
        uint256 start_date,
        uint256 end_date,
        uint256 max,
        uint256 price
    ) public onlyRole(INIT_ROLE) {
        require(drop > 0, "Drop must be a positive integer greater than zero.");
        require(bytes(name).length > 0, "Drop name can not be empty.");
        require(
            start_date >= 0 && end_date >= 0,
            "Dates must be a positive or zero integer."
        );
        require(max > 0, "Max must be a positive integer greater than zero.");
        require(
            price > 0,
            "Price must be a positive integer greater than zero."
        );
        require(
            drop_tokens[drop] == 0,
            "Setting can not be changed after minting."
        );
        drop_initeds[drop] = true;
        drop_names[drop] = name;
        drop_start_dates[drop] = start_date;
        drop_end_dates[drop] = end_date;
        drop_maxes[drop] = max;
        drop_prices[drop] = price;
        drop_tokens[drop] = 0;
    }

    function isDropInited(uint256 drop) public view returns (bool) {
        return drop_initeds[drop];
    }

    function getDropName(uint256 drop) public view returns (string memory) {
        return drop_names[drop];
    }

    function getDropStartDate(uint256 drop) public view returns (uint256) {
        return drop_start_dates[drop];
    }

    function getDropEndDate(uint256 drop) public view returns (uint256) {
        return drop_end_dates[drop];
    }

    function getDropMax(uint256 drop) public view returns (uint256) {
        return drop_maxes[drop];
    }

    function getDropPrice(uint256 drop) public view returns (uint256) {
        return drop_prices[drop];
    }

    function getDropTokensCount(uint256 drop) public view returns (uint256) {
        return drop_tokens[drop];
    }

    function getDropOf(uint256 token) public view returns (uint256) {
        return tokens_drop[token];
    }

    // MINT
    function mint(uint256 drop) public payable {
        require(isDropInited(drop), "Drop has not been inited yet.");
        require(
            getDropStartDate(drop) <= block.timestamp,
            "Drop has not been started yet."
        );
        require(
            getDropEndDate(drop) == 0 ||
                getDropEndDate(drop) >= block.timestamp,
            "Drop has been finished."
        );
        require(
            getDropTokensCount(drop) < getDropMax(drop),
            "All drops have been sold out."
        );
        require(getDropPrice(drop) <= msg.value, "Drop price is not valid");
        uint256 next = totalSupply() + 1;
        drop_tokens[drop]++;
        tokens_drop[next] = drop;
        _mint(msg.sender, next);
    }
}