
const VoterRegistration = artifacts.require("VoterRegistration");

contract("VoterRegistration", accounts => {
    let voterRegistration;
    const owner = accounts[0];
    const voter1 = accounts[1];
    const voter2 = accounts[2];

    beforeEach(async () => {
        voterRegistration = await VoterRegistration.new({ from: owner });
    });

    describe("Voter Registration", () => {
        it("should register a new voter", async () => {
            await voterRegistration.registerVoter("John Doe", "123456789", { from: voter1 });
            const voter = await voterRegistration.voters(voter1);
            assert.equal(voter.name, "John Doe");
            assert.equal(voter.idNumber, "123456789");
            assert.equal(voter.isRegistered, true);
        });

        it("should not allow duplicate registration", async () => {
            await voterRegistration.registerVoter("John Doe", "123456789", { from: voter1 });
            try {
                await voterRegistration.registerVoter("John Doe", "123456789", { from: voter1 });
                assert.fail("Expected revert not received");
            } catch (error) {
                assert(error.message.includes("Voter already registered"));
            }
        });

        it("should allow owner to verify voter", async () => {
            await voterRegistration.registerVoter("John Doe", "123456789", { from: voter1 });
            await voterRegistration.verifyVoter(voter1, { from: owner });
            const voter = await voterRegistration.voters(voter1);
            assert.equal(voter.isVerified, true);
        });

        it("should not allow non-owner to verify voter", async () => {
            await voterRegistration.registerVoter("John Doe", "123456789", { from: voter1 });
            try {
                await voterRegistration.verifyVoter(voter1, { from: voter2 });
                assert.fail("Expected revert not received");
            } catch (error) {
                assert(error.message.includes("Ownable: caller is not the owner"));
            }
        });

        it("should get voter details", async () => {
            await voterRegistration.registerVoter("John Doe", "123456789", { from: voter1 });
            const voter = await voterRegistration.getVoter(voter1);
            assert.equal(voter.name, "John Doe");
            assert.equal(voter.idNumber, "123456789");
            assert.equal(voter.isRegistered, true);
            assert.equal(voter.isVerified, false);
        });
    });
});
