function getNetworkConfig(network: any) {
  if (['bsc', 'bsc-fork'].includes(network)) {
    console.log(`Deploying with BSC MAINNET config.`)
    return {
      factoryV2: '0x0841BD0B734E4F5853f0dD8d7Ea041c241fb0Da6',
      factoryV3: '0x5a6511F7CD85e5bCaad3D72B0ed22AF163363A63',
      positionManager: '0x3f0256533a4c4670B7E4b4CBcE990d7497216489',
      WNATIVE: '0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c',
      factories: [],
    }
  } else if (['bscTestnet', 'bsc-testnet-fork'].includes(network)) {
    console.log(`Deploying with BSC testnet config.`)
    return {
      factoryV2: '0x152349604d49c2Af10ADeE94b918b051104a143E',
      factoryV3: '0x13f321ABC34b9BD13a6Db1b1CfA6bfd0f78b3909',
      positionManager: '0x23EAe0CF648314AE40eB26e4bFfFE129bf4Cd8C8',
      WNATIVE: '0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd',
      factories: [],
    }
  } else if (['polygon'].includes(network)) {
    console.log(`Deploying with polygon config.`)
    return {
      factoryV2: '0x0000000000000000000000000000000000000000',
      factoryV3: '0x0000000000000000000000000000000000000000',
      positionManager: '0x0000000000000000000000000000000000000000',
      WNATIVE: '0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270',
      factories: [
        '0xCf083Be4164828f00cAE704EC15a36D711491284',
        '0x86A2Ad3771ed3b4722238CEF303048AC44231987',
        '0x1F98431c8aD98523631AE4a59f267346ea31F984',
      ],
      // factoryV2: '0xCf083Be4164828f00cAE704EC15a36D711491284',
      // factoryV3: '0x86A2Ad3771ed3b4722238CEF303048AC44231987',
      // // uniFactoryV3: '0x1F98431c8aD98523631AE4a59f267346ea31F984',
      // positionManager: '0x01B8f5B6647E57607D8d5E323EdBDb3C7Efe86b6',
      // WNATIVE: '0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270',
    }
  } else if (['development'].includes(network)) {
    console.log(`Deploying with development config.`)
    return {}
  } else {
    throw new Error(`No config found for network ${network}.`)
  }
}

export default getNetworkConfig
