/* eslint-disable node/no-missing-import */
/* eslint-disable no-undef */
import { ethers } from "hardhat";

async function deployStaking() {
  // We get the contract to deploy
  const Staking = await ethers.getContractFactory("Staking");
  const staking = await Staking.deploy(1);

  await staking.deployed();

  console.log("Staking deployed to:", staking.address);
}

deployStaking().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
