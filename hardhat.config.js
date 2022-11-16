require("@nomiclabs/hardhat-waffle");
require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-etherscan");
require('dotenv').config()

let PK = process.env['PRI_KEY']

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.4",
    settings: { 
      optimizer: {
        enabled: true,
        runs: 800
      }
    }
  },
  defaultNetwork: 'local',
  
  etherscan: {
    apiKey: {
      goerli: process.env["ETHERSCAN_API_KEY"]
    }
  },
  networks: {
    mumbai: {
      url: "https://speedy-nodes-nyc.moralis.io/fb1841515bcc2b1e0aed0509/polygon/mumbai/archive",
      accounts: [PK]
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${process.env["INFURA_API_KEY"]}`,
      accounts: [PK]
    },
    xdaichain: {
      url: "https://rpc.gnosischain.com/",
      accounts: [PK]
    },
    local: {
      url: 'http://localhost:8545',
    }
  }
};
