
const Voting = artifacts.require("./Voting.sol");

contract("Voting", accounts => {
  let votingInstance;

  beforeEach(async () => {
    votingInstance = await Voting.new();
  });

  it("initializes with zero candidates", async () => {
    const count = await votingInstance.candidatesCount();
    assert.equal(count, 0);
  });

  it("allows adding a candidate", async () => {
    await votingInstance.addCandidate("Candidate 1");
    const count = await votingInstance.candidatesCount();
    const candidate = await votingInstance.candidates(1);
    
    assert.equal(count, 1);
    assert.equal(candidate.name, "Candidate 1");
    assert.equal(candidate.voteCount, 0);
  });

  it("allows a voter to cast a vote", async () => {
    await votingInstance.addCandidate("Candidate 1");
    await votingInstance.vote(1, { from: accounts[1] });
    
    const candidate = await votingInstance.candidates(1);
    const hasVoted = await votingInstance.voters(accounts[1]);
    
    assert.equal(candidate.voteCount, 1);
    assert.equal(hasVoted, true);
  });

  it("throws an exception for invalid candidates", async () => {
    try {
      await votingInstance.vote(99, { from: accounts[1] });
      assert.fail("Expected revert not received");
    } catch (error) {
      assert(error.message.includes("revert"), "Expected 'revert' but got " + error.message);
    }
  });

  it("throws an exception for double voting", async () => {
    await votingInstance.addCandidate("Candidate 1");
    await votingInstance.vote(1, { from: accounts[1] });
    
    try {
      await votingInstance.vote(1, { from: accounts[1] });
      assert.fail("Expected revert not received");
    } catch (error) {
      assert(error.message.includes("revert"), "Expected 'revert' but got " + error.message);
    }
  });
});
