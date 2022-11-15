const { ethers } = require("hardhat");
const hre = require("hardhat");
const { networks } = require("../hardhat.config");
const { contractAddress } = require("./helpers/utils");
const users = require("./helpers/users.json");
const { BigNumber } = require("ethers");

async function main() {
    const provider = ethers.providers.getDefaultProvider(networks.local.url)
    const signer = new ethers.Wallet(process.env.PK, provider)
    const Billeterie = await hre.ethers.getContractAt("Billeterie", contractAddress, signer);

    const billeterieAsSigner = Billeterie.connect(signer)
    
    const totalEvents = await billeterieAsSigner["totalEvents"]()
    console.log(Number(totalEvents.toString()))
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
