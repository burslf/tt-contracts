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

    const tx = await billeterieAsSigner.populateTransaction.mint(users.user2.account, 0, 1, '0x')
    tx.value = BigNumber.from("100000000000000000")
    tx.gasLimit = 300000

    // console.log(tx)
    const gasEstimation = await signer.estimateGas(tx)
    console.log(Number(gasEstimation.toString()))
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
