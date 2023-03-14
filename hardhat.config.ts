import '@nomiclabs/hardhat-ethers'
import '@nomiclabs/hardhat-etherscan'
import '@nomiclabs/hardhat-waffle'
import 'hardhat-typechain'
import 'hardhat-watcher'
import 'dotenv/config'

const DEFAULT_COMPILER_SETTINGS = {
  version: '0.7.6',
  settings: {
    evmVersion: 'istanbul',
    optimizer: {
      enabled: true,
      runs: 1_000_000,
    },
    metadata: {
      bytecodeHash: 'none',
    },
  },
}

export default {
  networks: {
    hardhat: {
      allowUnlimitedContractSize: false,
    },
    eth: {
      url: 'https://endpoints.omniatech.io/v1/eth/mainnet/public',
      chainId: 1,
      accounts: {
        mnemonic: process.env.MAINNET_DEPLOYER_KEY,
      },
    },
    ropsten: {
      url: `https://ropsten.infura.io/v3/${process.env.INFURA_API_KEY}`,
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${process.env.INFURA_API_KEY}`,
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${process.env.INFURA_API_KEY}`,
    },
    kovan: {
      url: `https://kovan.infura.io/v3/${process.env.INFURA_API_KEY}`,
    },
    arbitrumRinkeby: {
      url: `https://rinkeby.arbitrum.io/rpc`,
    },
    arbitrum: {
      url: `https://endpoints.omniatech.io/v1/arbitrum/one/public`,
      chainId: 42161,
      accounts: {
        mnemonic: process.env.MAINNET_DEPLOYER_KEY,
      },
    },
    optimismKovan: {
      url: `https://kovan.optimism.io`,
    },
    optimism: {
      url: `https://mainnet.optimism.io`,
    },
    polygon: {
      url: 'https://polygon-rpc.com',
      chainId: 137,
      accounts: {
        mnemonic: process.env.MAINNET_DEPLOYER_KEY,
      },
    },
    bscTestnet: {
      url: 'https://data-seed-prebsc-1-s3.binance.org:8545',
      chainId: 97,
      accounts: {
        mnemonic: process.env.TESTNET_DEPLOYER_KEY,
      },
    },
    telos: {
      url: 'https://mainnet.telos.net/evm',
      chainId: 40,
      accounts: {
        mnemonic: process.env.MAINNET_DEPLOYER_KEY,
      },
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY,
      bscTestnet: process.env.BSCSCAN_API_KEY,
      polygon: process.env.POLYGONSCAN_API_KEY,
      arbitrumOne: process.env.ARBISCAN_API_KEY
    },
  },
  solidity: {
    compilers: [DEFAULT_COMPILER_SETTINGS],
  },
  watcher: {
    test: {
      tasks: [{ command: 'test', params: { testFiles: ['{path}'] } }],
      files: ['./test/**/*'],
      verbose: true,
    },
  },
}
