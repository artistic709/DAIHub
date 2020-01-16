require('dotenv').config()

usePlugin('@nomiclabs/buidler-solhint')
usePlugin('@nomiclabs/buidler-ethers')
usePlugin('@nomiclabs/buidler-web3')
usePlugin('buidler-gas-reporter')

// task action function receives the Buidler Runtime Environment as second argument
task('blockNumber', 'Prints the current block number', async (_, { ethers }) => {
  await ethers.provider.getBlockNumber().then((blockNumber) => {
    console.log('Current block number: ' + blockNumber)
  })
})

const INFURA_API_KEY = process.env.INFURA_API_KEY
const MAINNET_PRIVATE_KEY = process.env.MAINNET_PRIVATE_KEY
const ROPSTEN_PRIVATE_KEY = process.env.ROPSTEN_PRIVATE_KEY
const RINKEBY_PRIVATE_KEY = process.env.RINKEBY_PRIVATE_KEY

let networks = {}
if (INFURA_API_KEY) {
  if (MAINNET_PRIVATE_KEY) {
    networks = { ...networks, mainnet: {
      url: `https://infura.io/v3/${INFURA_API_KEY}`,
      accounts: [MAINNET_PRIVATE_KEY],
    }}
  }
  if (ROPSTEN_PRIVATE_KEY) {
    networks = { ...networks, ropsten: {
      url: `https://ropsten.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [ROPSTEN_PRIVATE_KEY],
    }}
  }
  if (RINKEBY_PRIVATE_KEY) {
    networks = { ...networks, rinkeby: {
      url: `https://rinkeby.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [RINKEBY_PRIVATE_KEY],
    }}
  }
}

module.exports = {
  defaultNetwork: 'buidlerevm',
  networks: networks,
  solc: {
    version: '0.5.15',
    optimizer: {
      enabled: true,
      runs: 200,
    },
    evmVersion: 'homestead',
  },
  gasReporter: {
    enabled: (process.env.REPORT_GAS) ? true : false,
    currency: 'USD',
    showTimeSpent: true
  }
}
