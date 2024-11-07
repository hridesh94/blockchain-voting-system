// Voting.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./VoterRegistration.sol";

contract Voting {
    struct Proposal {
        string name;
        uint256 voteCount;
        bool exists;
    }
    
    VoterRegistration public voterRegistration;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    bool public votingOpen;
    
    event ProposalAdded(uint256 indexed proposalId, string name);
    event Voted(address indexed voter, uint256 indexed proposalId);
    event VotingToggled(bool isOpen);
    
    modifier onlyAdmin() {
        require(msg.sender == voterRegistration.admin(), "Only admin can perform this action");
        _;
    }
    
    constructor(address _voterRegistrationAddress) {
        voterRegistration = VoterRegistration(_voterRegistrationAddress);
        votingOpen = false;
    }

    // Removed onlyAdmin modifier
    function initialize() external {  
        voterRegistration.setVotingContract(address(this));
    }
    
    function addProposal(string memory _name) external onlyAdmin {
        require(bytes(_name).length > 0, "Proposal name cannot be empty");
        proposalCount++;
        proposals[proposalCount] = Proposal({
            name: _name,
            voteCount: 0,
            exists: true
        });
        
        emit ProposalAdded(proposalCount, _name);
    }
    
    function vote(uint256 _proposalId) external {
        require(votingOpen, "Voting is not open");
        require(voterRegistration.isVoterRegistered(msg.sender), "Voter is not registered");
        require(!voterRegistration.hasVoterVoted(msg.sender), "Voter has already voted");
        require(proposals[_proposalId].exists, "Proposal does not exist");
        
        proposals[_proposalId].voteCount++;
        voterRegistration.updateVoterStatus(msg.sender, _proposalId);
        
        emit Voted(msg.sender, _proposalId);
    }
    
    function toggleVoting() external onlyAdmin {
        votingOpen = !votingOpen;
        emit VotingToggled(votingOpen);
    }
    
    function getProposal(uint256 _proposalId) external view returns (string memory name, uint256 voteCount) {
        require(proposals[_proposalId].exists, "Proposal does not exist");
        Proposal storage proposal = proposals[_proposalId];
        return (proposal.name, proposal.voteCount);
    }
    
    function getWinningProposal() external view returns (uint256 winningProposalId, string memory name, uint256 voteCount) {
        require(proposalCount > 0, "No proposals exist");
        
        uint256 winningVoteCount = 0;
        
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposalId = i;
            }
        }
        
        require(winningVoteCount > 0, "No votes cast");
        return (winningProposalId, proposals[winningProposalId].name, winningVoteCount);
    }
}