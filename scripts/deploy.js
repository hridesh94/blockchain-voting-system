// deploy.js
const hre = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners(); 

  const VoterRegistration = await hre.ethers.getContractFactory("VoterRegistration");
  const voterRegistration = await VoterRegistration.deploy();
  await voterRegistration.waitForDeployment();

  const Voting = await hre.ethers.getContractFactory("Voting");
  const voting = await Voting.deploy(voterRegistration.target); 
  await voting.waitForDeployment();

  // Initialize Voting contract from VoterRegistration as the admin
  await voterRegistration.connect(deployer).setVotingContract(voting.target); 

  // Call initialize() on Voting contract to complete the setup
  await voting.initialize(); 

  console.log("VoterRegistration deployed to:", voterRegistration.target);
  console.log("Voting deployed to:", voting.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});