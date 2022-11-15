const { ethers } = require("hardhat");
const hre = require("hardhat");
const { networks } = require("../hardhat.config");
const { contractAddress } = require("./helpers/utils");
const users = require("./helpers/users.json");
const { BigNumber } = require("ethers");

async function main() {
    const provider = await ethers.providers.getDefaultProvider(networks.local.url)
    const signer = new ethers.Wallet(process.env.PK, provider)
    const Billeterie = await hre.ethers.getContractAt("Billeterie", contractAddress, signer);

    const billeterieAsSigner = Billeterie.connect(signer)

    const tx = await billeterieAsSigner.populateTransaction.createTicketing(500, BigNumber.from('100000000000000000'), 'ipfs://Qmfriu454j4545hj43u54iu5465g46575')
    // tx.value = BigNumber.from("100000000000000000")
    tx.gasLimit = 300000
    const gasPrice = await provider.getGasPrice()
    console.log('\n Gas Price: ', gasPrice)
    console.log(tx)
    // const gasEstimation = await billeterieAsSigner.estimateGas.mint('0x102BB817B5Acd75d3066B20883a2F917C5677777', 0, 1, '0x')
    const gasEstimation = await signer.estimateGas(tx)
    console.log(gasEstimation)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
