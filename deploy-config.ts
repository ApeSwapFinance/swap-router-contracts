function getNetworkConfig(network: any) {
  if (['bsc', 'bsc-fork'].includes(network)) {
    console.log(`Deploying with BSC MAINNET config.`)
    return {
      factoryV2: '0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7',
      factoryV3: '0x5a6511F7CD85e5bCaad3D72B0ed22AF163363A63',
      positionManager: '0x3f0256533a4c4670B7E4b4CBcE990d7497216489',
      WNATIVE: '0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c',
      factories: [
        '0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607', //APEV2
        '0x7Bc382DdC5928964D7af60e7e2f6299A1eA6F48d', //APEV3
        '0xdB1d10011AD0Ff90774D0C6Bb92e5C5c8b4461F7', //UNIV3
        '0x10ED43C718714eb63d5aA57B78B54704E256024E', //PCS V2
        '0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865', //PCS V3
      ],
      hashes: [
        '0xf4ccce374816856d11f00e4069e7cada164065686fbef53c6167a63ec2fd8c5b',
        '0x3d5dcdd0a5890dbad55ff9543ece732377aa023ae7180e3ffc94f63eaf1a4ad1',
        '0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54',
        '0x00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5',
        '0x6ce8eb472fa82df5469c6ab6d485f17c3ad13c8cd7af59b3d4a8026c5ce0f7e2',
      ],
    }
  } else if (['bscTestnet', 'bsc-testnet-fork'].includes(network)) {
    console.log(`Deploying with BSC testnet config.`)
    return {
      factoryV2: '0x152349604d49c2Af10ADeE94b918b051104a143E',
      factoryV3: '0x13f321ABC34b9BD13a6Db1b1CfA6bfd0f78b3909',
      positionManager: '0x23EAe0CF648314AE40eB26e4bFfFE129bf4Cd8C8',
      WNATIVE: '0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd',
      factories: [],
      hashes: [],
    }
  } else if (['polygon'].includes(network)) {
    console.log(`Deploying with polygon config.`)
    return {
      factoryV2: '0x0000000000000000000000000000000000000000',
      factoryV3: '0x0000000000000000000000000000000000000000',
      positionManager: '0x0000000000000000000000000000000000000000',
      WNATIVE: '0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270',
      factories: [
        '0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607', //APEV2
        '0x7Bc382DdC5928964D7af60e7e2f6299A1eA6F48d', //APEV3
        '0x1F98431c8aD98523631AE4a59f267346ea31F984', //UNIV3
        '0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff', //QUICKSWAP V2
        '0x411b0fAcC3489691f28ad58c47006AF5E3Ab3A28', //ALGEBRA
      ],
      hashes: [
        '0x511f0f358fe530cda0859ec20becf391718fdf5a329be02f4c95361f3d6a42d8',
        '0x3d5dcdd0a5890dbad55ff9543ece732377aa023ae7180e3ffc94f63eaf1a4ad1',
        '0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54',
        '0x0000000000000000000000000000000000000000000000000000000000000001',
        '0x6ec6c9c8091d160c0aa74b2b14ba9c1717e95093bd3ac085cee99a49aab294a4',
      ],
      // factoryV2: '0xCf083Be4164828f00cAE704EC15a36D711491284',
      // factoryV3: '0x7Bc382DdC5928964D7af60e7e2f6299A1eA6F48d',
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
