const hre = require("hardhat");

async function main() {
  const Billeterie = await hre.ethers.getContractFactory("Billeterie");
  const billeterie = await upgrades.deployProxy(Billeterie, 
    ["0x102BB817B5Acd75d3066B20883a2F917C5677777", "0x9590aD5C5D511bED9F2185e5D916D10cAc7a0bf0"])


  await billeterie.deployed();

  console.log("Billeterie deployed to:", billeterie.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
