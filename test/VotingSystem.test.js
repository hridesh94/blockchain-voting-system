const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("VotingSystem", function () {
  let voterRegistration;
  let voting;
  let owner;
  let addr1;
  let addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    const VoterRegistration = await ethers.getContractFactory("VoterRegistration");
    voterRegistration = await VoterRegistration.deploy();
    await voterRegistration.waitForDeployment();

    const Voting = await ethers.getContractFactory("Voting");
    voting = await Voting.deploy(voterRegistration.target);
    await voting.waitForDeployment();

  });

  describe("Deployment", function () {
    it("Should initialize the contracts correctly", async function () {
      expect(await voting.voterRegistration()).to.equal(voterRegistration.target);
      expect(await voterRegistration.votingContract()).to.equal(voting.target);
    });
  });

  describe("Voter Registration", function () {
    it("Should register a voter", async function () {
      await voterRegistration.registerVoter(addr1.address);
      expect(await voterRegistration.isVoterRegistered(addr1.address)).to.equal(true);
    });

    it("Should not register the same voter twice", async function () {
      await voterRegistration.registerVoter(addr1.address);
      await expect(voterRegistration.registerVoter(addr1.address)).to.be.revertedWith(
        "Voter already registered"
      );
    });
  });

  describe("Proposal Management", function () {
    it("Should add a proposal", async function () {
      await voting.addProposal("Proposal 1");
      const proposal = await voting.getProposal(1);
      expect(proposal.name).to.equal("Proposal 1");
    });

    it("Should not add a proposal with no name", async function () {
      await expect(voting.addProposal("")).to.be.revertedWith(
        "Proposal name cannot be empty"
      );
    });
  });

  describe("Voting", function () {
    beforeEach(async function () {
      await voterRegistration.registerVoter(addr1.address);
      await voting.addProposal("Proposal 1");
      await voting.toggleVoting(); // Open voting for this set of tests
    });

    it("Should allow a registered voter to vote", async function () {
      await voting.connect(addr1).vote(1);
      const proposal = await voting.getProposal(1);
      expect(proposal.voteCount).to.equal(1);
    });

    it("Should not allow an unregistered voter to vote", async function () {
      await expect(voting.connect(addr2).vote(1)).to.be.revertedWith(
        "Voter is not registered"
      );
    });

    it("Should not allow voting for a non-existent proposal", async function () {
      await expect(voting.connect(addr1).vote(2)).to.be.revertedWith(
        "Proposal does not exist"
      );
    });

    it("Should not allow a voter to vote twice", async function () {
      await voting.connect(addr1).vote(1);
      await expect(voting.connect(addr1).vote(1)).to.be.revertedWith(
        "Voter has already voted"
      );
    });
  });

  describe("Result Calculation", function () {
    beforeEach(async function () {
      await voterRegistration.registerVoter(addr1.address);
      await voterRegistration.registerVoter(addr2.address);
      await voting.addProposal("Proposal 1");
      await voting.toggleVoting(); // Open voting for this set of tests
      await voting.connect(addr1).vote(1); // addr1 votes for Proposal 1
    });

    it("Should calculate the correct results", async function () {
      const [winningProposalId, name, voteCount] = await voting.getWinningProposal();
      expect(winningProposalId).to.equal(1);
      expect(name).to.equal("Proposal 1");
      expect(voteCount).to.equal(1);
    });
  });
});