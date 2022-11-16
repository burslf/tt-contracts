const hre = require("hardhat");

async function main() {
  const Billeterie = await hre.ethers.getContractFactory("Billeterie");
  const billeterie = await upgrades.deployProxy(Billeterie, 
    ["0x102BB817B5Acd75d3066B20883a2F917C5677777", "0x4b0eace8c65ca4f398ff5e3402873461888ccaf9"])


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
