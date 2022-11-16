const { upgrades, ethers } = require("hardhat");

async function main() {

  //   const OperatorsRegistry = await ethers.getContractFactory('contracts/OperatorRegistry_flat.sol:OperatorsRegistry');

  //   const operatorsRegistry = await upgrades.deployProxy(OperatorsRegistry, 
  //                                                        [["0x622093074b6E53A372f0e542B8f22f1c1511E1Fc"], "0x622093074b6E53A372f0e542B8f22f1c1511E1Fc"])
  // const operatorsRegistry = await OperatorsRegistry.deploy();

  //   const changed = await upgrades.admin.changeProxyAdmin("0xac6e1c3e770e38fd2bc88b690fafcb7d4eada56a", "0xfa4C559D93e754216252Ecc4F0F365882B4aF311")
  //   await operatorsRegistry.deployed();
  const Billeterie = await ethers.getContractFactory('Billeterie')

  const upgraded = await upgrades.upgradeProxy("0x937301d5CA9035948D168fFC6Da3c76CB0b2E91f", Billeterie)

  console.log("Changed: ",upgraded);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
