// VoterRegistration.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

error VoterRegistration__OnlyAdmin(); 
error VoterRegistration__OnlyVotingContract(); 

contract VoterRegistration {
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }
    
    mapping(address => Voter) public voters;
    address public admin;
    bool public registrationOpen;
    address public votingContract;
    
    event VoterRegistered(address indexed voter);
    event RegistrationToggled(bool isOpen);
    event VoterStatusUpdated(address indexed voter, bool hasVoted, uint256 proposalId);
    
    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert VoterRegistration__OnlyAdmin(); 
        }
        _;
    }

    modifier onlyVotingContract() {
        if (msg.sender != votingContract) {
            revert VoterRegistration__OnlyVotingContract(); 
        }
        _;
    }
    
    constructor() {
        admin = msg.sender;
        registrationOpen = true;
    }

    function setVotingContract(address _votingContract) external onlyAdmin {
        require(_votingContract != address(0), "Invalid voting contract address");
        votingContract = _votingContract;
    }
    
    function registerVoter(address _voter) external onlyAdmin {
        require(registrationOpen, "Registration is closed");
        require(!voters[_voter].isRegistered, "Voter already registered");
        
        voters[_voter] = Voter({
            isRegistered: true,
            hasVoted: false,
            votedProposalId: 0
        });
        
        emit VoterRegistered(_voter);
    }
    
    function toggleRegistration() external onlyAdmin {
        registrationOpen = !registrationOpen;
        emit RegistrationToggled(registrationOpen);
    }
    
    function updateVoterStatus(address _voter, uint256 _proposalId) external onlyVotingContract {
        require(voters[_voter].isRegistered, "Voter not registered");
        require(!voters[_voter].hasVoted, "Voter has already voted");
        
        voters[_voter].hasVoted = true;
        voters[_voter].votedProposalId = _proposalId;
        
        emit VoterStatusUpdated(_voter, true, _proposalId);
    }
    
    function isVoterRegistered(address _voter) external view returns (bool) {
        return voters[_voter].isRegistered;
    }
    
    function hasVoterVoted(address _voter) external view returns (bool) {
        return voters[_voter].hasVoted;
    }

    function getVoter(address _voter) external view returns (bool isRegistered, bool hasVoted, uint256 votedProposalId) {
        Voter memory voter = voters[_voter];
        return (voter.isRegistered, voter.hasVoted, voter.votedProposalId);
    }
}