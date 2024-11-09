const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("VotingSystem", function () {
  let voterRegistration, voting, deployer, addr1, addr2;

  beforeEach(async function () {
    [deployer, addr1, addr2] = await ethers.getSigners();

    // Deploy VoterRegistration contract
    const VoterRegistration = await ethers.getContractFactory("VoterRegistration");
    voterRegistration = await VoterRegistration.deploy();
    await voterRegistration.waitForDeployment();

    // Deploy Voting contract with the address of VoterRegistration contract
    const Voting = await ethers.getContractFactory("Voting");
    voting = await Voting.deploy(voterRegistration.target);
    await voting.waitForDeployment();

    // Set the Voting contract address in the VoterRegistration contract
    await voterRegistration.connect(deployer).setVotingContract(voting.target);

    // Open registration by default for testing
    await voterRegistration.connect(deployer).toggleRegistration();
  });

  it("Should initialize the contracts correctly", async function () {
    expect(await voterRegistration.votingContract()).to.equal(voting.target);
    expect(await voterRegistration.admin()).to.equal(deployer.address);
    expect(await voting.voterRegistration()).to.equal(voterRegistration.target);
  });

  describe("Voter Registration", function () {
    it("Should register a voter", async function () {
      await voterRegistration.connect(deployer).registerVoter(addr1.address);
      const [isRegistered, hasVoted, votedProposalId] = await voterRegistration.getVoter(addr1.address);
      expect(isRegistered).to.be.true;
      expect(hasVoted).to.be.false;
      expect(votedProposalId).to.equal(0);
    });
      it("Should not register the same voter twice", async function () {
        await voterRegistration.connect(deployer).registerVoter(addr1.address);
        await expect(
          voterRegistration.connect(deployer).registerVoter(addr1.address)
        ).to.be.revertedWithCustomError(voterRegistration, "VoterRegistration__AlreadyRegistered");
      });
    });

    describe("Proposal Management", function () {
      it("Should add a proposal", async function () {
        await voting.connect(deployer).addProposal("Proposal 1");

      it("Should not add a proposal with no name", async function () {
        await expect(
          voting.connect(deployer).addProposal("")
        ).to.be.revertedWithCustomError(voting, "Voting__EmptyProposalName");
      });
      const [name, voteCount] = await voting.getProposal(1);
      expect(name).to.equal("Proposal 1");
      expect(voteCount).to.equal(0);
    });

    it("Should not add a proposal with no name", async function () {
      await expect(
        voting.connect(deployer).addProposal("")
      ).to.be.revertedWithCustomError(voting, "Voting__EmptyProposalName");
    });
  });

  describe("Voting", function () {
    beforeEach(async function () {
      // Register a voter
      await voterRegistration.connect(deployer).registerVoter(addr1.address);
      // Add a proposal
      await voting.connect(deployer).addProposal("Proposal 1");
      // Open voting
      await voting.connect(deployer).toggleVoting();
    });

    it("Should allow a registered voter to vote", async function () {
      await voting.connect(addr1).vote(1);
      const [name, voteCount] = await voting.getProposal(1);
      expect(voteCount).to.equal(1);
      const [, hasVoted, votedProposalId] = await voterRegistration.getVoter(addr1.address);
      expect(hasVoted).to.be.true;
      expect(votedProposalId).to.equal(1);
    });
      it("Should not allow an unregistered voter to vote", async function () {
        await expect(
          voting.connect(addr2).vote(1)
        ).to.be.revertedWithCustomError(voting, "Voting__VoterNotRegistered");
      });

      it("Should not allow voting for a non-existent proposal", async function () {
        await expect(
          voting.connect(addr1).vote(999)
        ).to.be.revertedWithCustomError(voting, "Voting__ProposalDoesNotExist");
      });

      it("Should not allow a voter to vote twice", async function () {
        await voting.connect(addr1).vote(1);
        await expect(
          voting.connect(addr1).vote(1)
        ).to.be.revertedWithCustomError(voting, "Voting__VoterAlreadyVoted");
      });
  });
  describe("Result Calculation", function () {
    beforeEach(async function () {
      // Register voters
      await voterRegistration.connect(deployer).registerVoter(addr1.address);
      await voterRegistration.connect(deployer).registerVoter(addr2.address);
      
      // Add proposals
      await voting.connect(deployer).addProposal("Proposal 1");
      await voting.connect(deployer).addProposal("Proposal 2");
      
      // Open voting
      await voting.connect(deployer).toggleVoting();
    });

    it("Should calculate the correct results", async function () {
      await voting.connect(addr1).vote(1);
      await voting.connect(addr2).vote(1);

      const [winningProposalId, name, voteCount] = await voting.getWinningProposal();
      expect(winningProposalId).to.equal(1);
      expect(name).to.equal("Proposal 1");
      expect(voteCount).to.equal(2);
    });
  });
});