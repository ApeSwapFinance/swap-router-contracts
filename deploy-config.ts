function getNetworkConfig(network: any) {
  if (['bsc', 'bsc-fork'].includes(network)) {
    console.log(`Deploying with BSC MAINNET config.`)
    return {
      factoryV2: '0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7',
      factoryV3: '',
      positionManager: '',
      WNATIVE: '0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c',
    }
  } else if (['bscTestnet', 'bsc-testnet-fork'].includes(network)) {
    console.log(`Deploying with BSC testnet config.`)
    return {
      factoryV2: '0x152349604d49c2Af10ADeE94b918b051104a143E',
      factoryV3: '0x8013540bB4a8d16f1693FFAF308c7583Cd26A6d8',
      positionManager: '0xaC5D5019A1D9d9bbFb1bB171a2F18737FA4dC7dA',
      WNATIVE: '0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd',
    }
  } else if (['polygon'].includes(network)) {
    console.log(`Deploying with polygon config.`)
    return {
      factoryV2: '0xCf083Be4164828f00cAE704EC15a36D711491284',
      factoryV3: '0x86A2Ad3771ed3b4722238CEF303048AC44231987',
      // uniFactoryV3: '0x1F98431c8aD98523631AE4a59f267346ea31F984',
      positionManager: '0x01B8f5B6647E57607D8d5E323EdBDb3C7Efe86b6',
      WNATIVE: '0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270',
    }
  } else if (['development'].includes(network)) {
    console.log(`Deploying with development config.`)
    return {}
  } else {
    throw new Error(`No config found for network ${network}.`)
  }
}

export default getNetworkConfig
