// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./VoterRegistration.sol";

error Voting__OnlyAdmin();
error Voting__InvalidAddress();
error Voting__EmptyProposalName();
error Voting__ProposalDoesNotExist();
error Voting__VotingNotOpen();
error Voting__VoterNotRegistered();
error Voting__VoterAlreadyVoted();
error Voting__NoProposalsExist();
error Voting__NoVotesCast();
error Voting__MaxProposalsReached();
error Voting__ProposalAlreadyExists();

contract Voting {
    struct Proposal {
        string name;
        uint256 voteCount;
        bool exists;
        uint256 creationTime;
        address creator;
    }

    uint256 public constant MAX_PROPOSALS = 100;
    VoterRegistration public immutable voterRegistration;
    
    mapping(uint256 => Proposal) public proposals;
    mapping(string => bool) private proposalNameExists;
    
    uint256 public proposalCount;
    bool public votingOpen;
    uint256 public totalVotesCast;
    uint256 public votingStartTime;
    uint256 public votingEndTime;

    event ProposalAdded(
        uint256 indexed proposalId, 
        string name, 
        address indexed creator, 
        uint256 timestamp
    );
    event Voted(
        address indexed voter, 
        uint256 indexed proposalId, 
        uint256 timestamp
    );
    event VotingToggled(
        bool isOpen, 
        uint256 startTime, 
        uint256 endTime, 
        uint256 timestamp
    );
    event VotingEnded(
        uint256 winningProposalId, 
        string winningProposalName, 
        uint256 winningVoteCount, 
        uint256 timestamp
    );

    modifier onlyAdmin() {
        if (msg.sender != voterRegistration.admin()) {
            revert Voting__OnlyAdmin();
        }
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        if (!proposals[_proposalId].exists) {
            revert Voting__ProposalDoesNotExist();
        }
        _;
    }

    constructor(address _voterRegistrationAddress) {
        if (_voterRegistrationAddress == address(0)) {
            revert Voting__InvalidAddress();
        }
        voterRegistration = VoterRegistration(_voterRegistrationAddress);
    }

    function addProposal(string memory _name) 
        external 
        onlyAdmin 
    {
        if (bytes(_name).length == 0) {
            revert Voting__EmptyProposalName();
        }
        if (proposalCount >= MAX_PROPOSALS) {
            revert Voting__MaxProposalsReached();
        }
        if (proposalNameExists[_name]) {
            revert Voting__ProposalAlreadyExists();
        }

        proposalCount++;
        proposals[proposalCount] = Proposal({
            name: _name,
            voteCount: 0,
            exists: true,
            creationTime: block.timestamp,
            creator: msg.sender
        });
        
        proposalNameExists[_name] = true;

        emit ProposalAdded(
            proposalCount, 
            _name, 
            msg.sender, 
            block.timestamp
        );
    }

    function vote(uint256 _proposalId) 
        external 
        validProposalId(_proposalId) 
    {
        if (!votingOpen) {
            revert Voting__VotingNotOpen();
        }
        if (!voterRegistration.isVoterRegistered(msg.sender)) {
            revert Voting__VoterNotRegistered();
        }
        if (voterRegistration.hasVoterVoted(msg.sender)) {
            revert Voting__VoterAlreadyVoted();
        }

        proposals[_proposalId].voteCount++;
        totalVotesCast++;
        voterRegistration.updateVoterStatus(msg.sender, _proposalId);

        emit Voted(msg.sender, _proposalId, block.timestamp);
    }

    function toggleVoting() 
        external 
        onlyAdmin 
    {
        votingOpen = !votingOpen;
        
        if (votingOpen) {
            votingStartTime = block.timestamp;
            votingEndTime = 0;
        } else {
            votingEndTime = block.timestamp;
            (uint256 winningId, string memory winningName, uint256 votes) = 
                _calculateWinner();
            emit VotingEnded(winningId, winningName, votes, block.timestamp);
        }

        emit VotingToggled(
            votingOpen, 
            votingStartTime, 
            votingEndTime, 
            block.timestamp
        );
    }

    function getProposal(uint256 _proposalId) 
        external 
        view 
        validProposalId(_proposalId) 
        returns (
            string memory name, 
            uint256 voteCount,
            uint256 creationTime,
            address creator
        ) 
    {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.name, 
            proposal.voteCount,
            proposal.creationTime,
            proposal.creator
        );
    }

    function getWinningProposal() 
        external 
        view 
        returns (
            uint256 winningProposalId, 
            string memory name, 
            uint256 voteCount
        ) 
    {
        return _calculateWinner();
    }

    function _calculateWinner() 
        internal 
        view 
        returns (
            uint256 winningProposalId, 
            string memory name, 
            uint256 voteCount
        ) 
    {
        if (proposalCount == 0) {
            revert Voting__NoProposalsExist();
        }

        uint256 winningVoteCount = 0;

        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposalId = i;
            }
        }

        if (winningVoteCount == 0) {
            revert Voting__NoVotesCast();
        }

        return (
            winningProposalId, 
            proposals[winningProposalId].name, 
            winningVoteCount
        );
    }

    function getVotingStatus() 
        external 
        view 
        returns (
            bool isOpen,
            uint256 startTime,
            uint256 endTime,
            uint256 totalProposals,
            uint256 totalVotes
        ) 
    {
        return (
            votingOpen,
            votingStartTime,
            votingEndTime,
            proposalCount,
            totalVotesCast
        );
    }

    function getProposalsByVoteCount() 
        external 
        view 
        returns (
            uint256[] memory proposalIds,
            string[] memory names,
            uint256[] memory voteCounts
        ) 
    {
        proposalIds = new uint256[](proposalCount);
        names = new string[](proposalCount);
        voteCounts = new uint256[](proposalCount);
        
        for (uint256 i = 0; i < proposalCount; i++) {
            uint256 proposalId = i + 1;
            proposalIds[i] = proposalId;
            names[i] = proposals[proposalId].name;
            voteCounts[i] = proposals[proposalId].voteCount;
        }

        // Simple bubble sort by vote count
        for (uint256 i = 0; i < proposalCount - 1; i++) {
            for (uint256 j = 0; j < proposalCount - i - 1; j++) {
                if (voteCounts[j] < voteCounts[j + 1]) {
                    // Swap vote counts
                    (voteCounts[j], voteCounts[j + 1]) = 
                        (voteCounts[j + 1], voteCounts[j]);
                    // Swap names
                    (names[j], names[j + 1]) = 
                        (names[j + 1], names[j]);
                    // Swap IDs
                    (proposalIds[j], proposalIds[j + 1]) = 
                        (proposalIds[j + 1], proposalIds[j]);
                }
            }
        }
    }
}