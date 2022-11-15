const hre = require("hardhat");

async function main() {
  const Billeterie = await hre.ethers.getContractFactory("Billeterie");
  const billeterie = await upgrades.deployProxy(Billeterie, 
    ["0x102BB817B5Acd75d3066B20883a2F917C5677777", "0x1e5f426989B29abAE1413739F1637ac3b1129230"])


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
