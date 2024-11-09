// deploy.js
const hre = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  const VoterRegistration = await hre.ethers.getContractFactory("VoterRegistration");
  const voterRegistration = await VoterRegistration.deploy();
  await voterRegistration.waitForDeployment();
  console.log("VoterRegistration deployed to:", voterRegistration.target);

  const Voting = await hre.ethers.getContractFactory("Voting");
  const voting = await Voting.deploy(voterRegistration.target);
  await voting.waitForDeployment();
  console.log("Voting deployed to:", voting.target);

  await voterRegistration.connect(deployer).setVotingContract(voting.target);
  console.log("Voting contract address set in VoterRegistration contract");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});