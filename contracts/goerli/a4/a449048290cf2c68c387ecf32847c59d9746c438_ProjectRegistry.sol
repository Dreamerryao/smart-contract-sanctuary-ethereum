// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./utils/MetaPtr.sol";

/**
 * @title ProjectRegistry
 */
contract ProjectRegistry {
    // Types

    // The project structs contains the minimal data we need for a project
    struct Project {
        uint96 id;
        address recipient;
        MetaPtr metadata;
    }

    // A linked list of owners of a project
    // The use of a linked list allows us to easily add and remove owners,
    // access them directly in O(1), and loop through them.
    //
    // {
    //     count: 3,
    //     list: {
    //         OWNERS_LIST_SENTINEL => owner1Address,
    //         owner1Address => owner2Address,
    //         owner2Address => owner3Address,
    //         owner3Address => OWNERS_LIST_SENTINEL
    //     }
    // }
    struct OwnerList {
        uint256 count;
        mapping(address => address) list;
    }

    // State variables

    // Used as sentinel value in the owners linked list.
    address OWNERS_LIST_SENTINEL = address(0x1);

    // The number of projects created, used to give an incremental id to each one
    uint96 public projectsCount;

    // The mapping of projects, from projectID to Project
    mapping(uint96 => Project) public projects;

    // The mapping projects owners, from projectID to OwnerList
    mapping(uint96 => OwnerList) public projectsOwners;

    // Events

    event ProjectCreated(address indexed owner, uint96 projectID);
    event MetadataUpdated(uint96 indexed projectID, MetaPtr metaPtr);

    // Modifiers

    modifier onlyProjectOwner(uint96 projectID) {
        require(projectsOwners[projectID].list[msg.sender] != address(0), "not owner");
        _;
    }

    constructor() {}

    // External functions

    /**
     * @notice Creates a new project with recipient and a metadata pointer
     * @param recipient the recipient address of a grant application
     * @param metadata the metadata pointer
     */
    function createProject(address recipient, MetaPtr memory metadata) external {
        uint96 projectID = projectsCount++;

        Project storage g = projects[projectID];
        g.id = projectID;
        g.recipient = recipient;
        g.metadata = metadata;

        initProjectOwners(projectID);

        emit ProjectCreated(msg.sender, projectID);
        emit MetadataUpdated(projectID, metadata);
    }

    /**
     * @notice Updates Metadata for singe project
     * @param projectID ID of previously created project
     * @param metadata Updated pointer to external metadata
     */
    function updateProjectMetadata(uint96 projectID, MetaPtr memory metadata) external onlyProjectOwner(projectID) {
        projects[projectID].metadata = metadata;
        emit MetadataUpdated(projectID, metadata);
    }

    /**
     * @notice todo
     * @dev todo
     */
    function addProjectOwner(uint96 projectID, address newOwner) external onlyProjectOwner(projectID) {
        require(newOwner != address(0) && newOwner != OWNERS_LIST_SENTINEL && newOwner != address(this), "bad owner");

        OwnerList storage owners = projectsOwners[projectID];

        require(owners.list[newOwner] == address(0), "already owner");

        owners.list[newOwner] = owners.list[OWNERS_LIST_SENTINEL];
        owners.list[OWNERS_LIST_SENTINEL] = newOwner;
        owners.count++;
    }

    /**
     * @notice todo
     * @dev todo
     */
    function removeProjectOwner(uint96 projectID, address prevOwner, address owner) external onlyProjectOwner(projectID) {
        require(owner != address(0) && owner != OWNERS_LIST_SENTINEL, "bad owner");

        OwnerList storage owners = projectsOwners[projectID];

        require(owners.list[prevOwner] == owner, "bad prevOwner");
        require(owners.count > 1, "single owner");

        owners.list[prevOwner] = owners.list[owner];
        delete owners.list[owner];
        owners.count--;
    }

    // Public functions

    /**
     * @notice todo
     * @dev todo
     */
    function projectOwnersCount(uint96 projectID) public view returns(uint256) {
        return projectsOwners[projectID].count;
    }

    /**
     * @notice todo
     * @dev todo
     */
    function getProjectOwners(uint96 projectID) public view returns(address[] memory) {
        OwnerList storage owners = projectsOwners[projectID];

        address[] memory list = new address[](owners.count);

        uint256 index = 0;
        address current = owners.list[OWNERS_LIST_SENTINEL];

        if (current == address(0x0)) {
            return list;
        }

        while (current != OWNERS_LIST_SENTINEL) {
            list[index] = current;
            current = owners.list[current];
            index++;
        }

        return list;
    }

    // Internal functions

    /**
     * @notice todo
     * @dev todo
     */
    function initProjectOwners(uint96 projectID) internal {
        OwnerList storage owners = projectsOwners[projectID];

        owners.list[OWNERS_LIST_SENTINEL] = msg.sender;
        owners.list[msg.sender] = OWNERS_LIST_SENTINEL;
        owners.count = 1;
    }

    // Private functions
    // ...
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

struct MetaPtr {

    /// @notice Protocol ID corresponding to a specific protocol.
    /// More info at https://github.com/gitcoinco/grants-round/tree/main/packages/contracts/docs/MetaPtrProtocol.md
    uint256 protocol;

    /// @notice Pointer to fetch metadata for the specified protocol
    string pointer;
}