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

    const tx = await billeterieAsSigner.populateTransaction.createTicketing(500, BigNumber.from('100000000000000000'), 'ipfs://QmVz9Yn1z7khcuBGEhxnp1cR4esVx4Sx9tvAJWqLvPsAoj')
    const gasPrice = await provider.getGasPrice()
    tx.gasPrice = gasPrice
    tx.gasLimit = 300000
    let nonce = await provider.getTransactionCount(users.user1.account)
    tx.nonce = nonce 
    
    const signedTx = await signer.signTransaction(tx)

    const txCall = await provider.sendTransaction(signedTx)
    console.log(txCall.nonce)

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
