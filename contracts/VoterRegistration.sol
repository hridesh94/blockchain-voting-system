// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

error VoterRegistration__OnlyAdmin();
error VoterRegistration__OnlyVotingContract();
error VoterRegistration__InvalidAddress();
error VoterRegistration__RegistrationClosed();
error VoterRegistration__AlreadyRegistered();
error VoterRegistration__NotRegistered();
error VoterRegistration__AlreadyVoted();
error VoterRegistration__VotingContractAlreadySet();

contract VoterRegistration {
    address public votingContract;
    address public admin;
    bool public registrationOpen;
    uint256 public totalRegisteredVoters;
    uint256 public totalVotesCast;

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
        uint256 registrationTime;
    }

    mapping(address => Voter) public voters;

    event VoterRegistered(address indexed voter, uint256 timestamp);
    event RegistrationToggled(bool isOpen, uint256 timestamp);
    event VoterStatusUpdated(address indexed voter, bool hasVoted, uint256 proposalId, uint256 timestamp);
    event VotingContractSet(address indexed votingContract, uint256 timestamp);
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin, uint256 timestamp);

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

    modifier validAddress(address _address) {
        if (_address == address(0)) {
            revert VoterRegistration__InvalidAddress();
        }
        _;
    }

    constructor() {
        admin = msg.sender;
        emit AdminTransferred(address(0), msg.sender, block.timestamp);
    }

    function setVotingContract(address _votingContract) 
        external 
        onlyAdmin 
        validAddress(_votingContract) 
    {
        if (votingContract != address(0)) {
            revert VoterRegistration__VotingContractAlreadySet();
        }
        votingContract = _votingContract;
        emit VotingContractSet(_votingContract, block.timestamp);
    }

    function registerVoter(address _voter) 
        external 
        onlyAdmin 
        validAddress(_voter) 
    {
        if (!registrationOpen) {
            revert VoterRegistration__RegistrationClosed();
        }
        if (voters[_voter].isRegistered) {
            revert VoterRegistration__AlreadyRegistered();
        }
        
        voters[_voter] = Voter({
            isRegistered: true,
            hasVoted: false,
            votedProposalId: 0,
            registrationTime: block.timestamp
        });
        
        totalRegisteredVoters++;
        emit VoterRegistered(_voter, block.timestamp);
    }
    
    function toggleRegistration() 
        external 
        onlyAdmin 
    {
        registrationOpen = !registrationOpen;
        emit RegistrationToggled(registrationOpen, block.timestamp);
    }
    
    function updateVoterStatus(address _voter, uint256 _proposalId) 
        external 
        onlyVotingContract 
        validAddress(_voter) 
    {
        if (!voters[_voter].isRegistered) {
            revert VoterRegistration__NotRegistered();
        }
        if (voters[_voter].hasVoted) {
            revert VoterRegistration__AlreadyVoted();
        }
        
        voters[_voter].hasVoted = true;
        voters[_voter].votedProposalId = _proposalId;
        totalVotesCast++;
        
        emit VoterStatusUpdated(_voter, true, _proposalId, block.timestamp);
    }

    function transferAdmin(address _newAdmin) 
        external 
        onlyAdmin 
        validAddress(_newAdmin) 
    {
        address oldAdmin = admin;
        admin = _newAdmin;
        emit AdminTransferred(oldAdmin, _newAdmin, block.timestamp);
    }
    
    // View Functions
    function isVoterRegistered(address _voter) 
        external 
        view 
        returns (bool) 
    {
        return voters[_voter].isRegistered;
    }
    
    function hasVoterVoted(address _voter) 
        external 
        view 
        returns (bool) 
    {
        return voters[_voter].hasVoted;
    }

    function getVoter(address _voter) 
        external 
        view 
        returns (
            bool isRegistered, 
            bool hasVoted, 
            uint256 votedProposalId,
            uint256 registrationTime
        ) 
    {
        Voter memory voter = voters[_voter];
        return (
            voter.isRegistered, 
            voter.hasVoted, 
            voter.votedProposalId,
            voter.registrationTime
        );
    }

    function getVoterParticipationRate() 
        external 
        view 
        returns (uint256) 
    {
        if (totalRegisteredVoters == 0) return 0;
        return (totalVotesCast * 100) / totalRegisteredVoters;
    }

    function getRegistrationStatus() 
        external 
        view 
        returns (
            bool isOpen, 
            uint256 registeredVoters,
            uint256 totalVotes
        ) 
    {
        return (registrationOpen, totalRegisteredVoters, totalVotesCast);
    }
}