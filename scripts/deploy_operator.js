const { upgrades, ethers } = require("hardhat");

async function main() {

  const OperatorsRegistry = await ethers.getContractFactory('OperatorsRegistry');

  const operatorsRegistry = await upgrades.deployProxy(OperatorsRegistry, 
                                                       [["0x102BB817B5Acd75d3066B20883a2F917C5677777"], "0x102BB817B5Acd75d3066B20883a2F917C5677777"])

  await operatorsRegistry.deployed();

  console.log("OperatorsRegistry deployed to:", operatorsRegistry.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
