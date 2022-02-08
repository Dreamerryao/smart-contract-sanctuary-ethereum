// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./Candidate.sol";
import "./Voter.sol";

contract ElectionCommission {
    address ec_admin;
    Candidate candidateContract;
    Voter voterContract;

    constructor() {
        ec_admin = msg.sender;
        candidateContract = new Candidate(address(this));
        voterContract = new Voter(address(candidateContract));
    }

    modifier is_ECAdmin() {
        require(
            msg.sender == ec_admin,
            " You are not an administrator of this contract"
        );
        _;
    }

    function getCandidateContractAddress()
        public
        view
        returns (address candidateContractAddress)
    {
        return address(candidateContract);
    }

    function getVoterContractAddress()
        public
        view
        returns (address voterContractAddress)
    {
        return address(voterContract);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./Candidate.sol";

contract Voter {
    struct VoterData {
        string nicop;
        address ethereum_address;
    }

    mapping(address => VoterData[]) voters;

    Candidate candidateContract;

    constructor(address _candidateAddress) {
        candidateContract = Candidate(_candidateAddress);
    }

    function insertVoteByParty(
        string memory national_id,
        string memory _party_name
    ) public {
        address ethereum_candidate_address = candidateContract
            .getCandidateAddressByPartyName(_party_name);

        require(
            ethereum_candidate_address != address(0),
            " There is no candidate for this party in the contract"
        );

        VoterData memory vdata;
        vdata.nicop = national_id;
        vdata.ethereum_address = msg.sender;

        voters[ethereum_candidate_address].push(vdata);
    }

    function getVotesByParty(string calldata _party_name)
        public
        view
        returns (uint256 total_votes)
    {
        address ethereum_candidate_address = candidateContract
            .getCandidateAddressByPartyName(_party_name);

        require(
            ethereum_candidate_address != address(0),
            " No candidate found for this party"
        );

        return voters[ethereum_candidate_address].length;
    }

    function verifyMyVote(string calldata _party_name)
        public
        view
        returns (string memory nicop, uint256 voter_index)
    {
        address ethereum_candidate_address = candidateContract
            .getCandidateAddressByPartyName(_party_name);

        require(
            ethereum_candidate_address != address(0),
            " There is no such party exist"
        );

        for (
            uint256 loop = 0;
            loop < voters[ethereum_candidate_address].length;
            loop++
        ) {
            if (
                voters[ethereum_candidate_address][loop].ethereum_address ==
                msg.sender
            ) {
                return (voters[ethereum_candidate_address][loop].nicop, loop);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma abicoder v2;



contract Candidate {
    
    
    struct candidate_template_data {
        
        string fname;
        string lname;
        string party_name;
        string party_symbol;
        address ethereum_address;
    }
    
    
    candidate_template_data [] public candidateData;
    
    address electionCommissionAddress;
    
    constructor (address _electionCommissionAddress) 
    {
        electionCommissionAddress = _electionCommissionAddress;
        
    }
    
    
    function insertCandidateData(string calldata _fname, string calldata _lname, string calldata _party_name,string calldata  _party_symbol, address candidate_address) external 
    {
        
        require(msg.sender == electionCommissionAddress , "Incoming call is not from Election Commission's contract");
        
        candidate_template_data memory obj ;
        
        obj.fname = _fname;
        obj.lname = _lname;
        obj.party_symbol = _party_symbol;
        obj.party_name = _party_name;
        obj.ethereum_address = candidate_address;
        
        candidateData.push(obj);
    }
    
    
    function getCandidateDataByPartyName(string calldata _party_name) public view returns (candidate_template_data memory  _candidate)
    {
        
        for(uint loop= 0; loop<candidateData.length; loop++)
        {
            if(keccak256(bytes(candidateData[loop].party_name)) == keccak256(bytes(_party_name)))
            {
                return candidateData[loop];
            }
        }
        
    }
    
    function getCandidateAddressByPartyName(string calldata _party_name) public view returns (address   _candidate_address)
    {
        
        for(uint loop= 0; loop<candidateData.length; loop++)
        {
            if(keccak256(bytes(candidateData[loop].party_name)) == keccak256(bytes(_party_name)))
            {
                return candidateData[loop].ethereum_address;
            }
        }
        
    }
    
    
    function getPartiesList() external view returns(string [] memory parties)
    {
         parties = new string[](candidateData.length);
         
         for(uint loop=0; loop<candidateData.length; loop++)
         {
             parties[loop] =candidateData[loop].party_name; 
             
         }
        
    }
    
    
    
}