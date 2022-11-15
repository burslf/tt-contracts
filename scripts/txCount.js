const { ethers } = require("hardhat");
const { networks } = require("../hardhat.config");


async function main() {
    const provider = ethers.providers.getDefaultProvider(networks.xdaichain.url)
    // const signer = new ethers.Wallet(process.env["PK2"], provider)
    // const Test = await hre.ethers.Contract(abi, contractAddress, signer);
    
    // const testAsSigner = Billeterie.connect(signer)
    const txCount = await provider.getTransactionCount("0x102BB817B5Acd75d3066B20883a2F917C5677777")
    console.log(txCount)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
