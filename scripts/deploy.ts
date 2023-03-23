import { ethers } from 'hardhat'
import { utils } from 'ethers'
import hre from 'hardhat'
import getNetworkConfig from '../deploy-config'

/**
 * // NOTE: This is an example of the default hardhat deployment approach.
 * This project takes deployments one step further by assigning each deployment
 * its own task in ../tasks/ organized by date.
 */
async function main() {
  console.log('START')
  const { factoryV2, factoryV3, positionManager, WNATIVE, factories } = getNetworkConfig(hre.network.name)
  const Router = await ethers.getContractFactory('ApeSwapMultiSwapRouter')
  const router = await Router.deploy(factories, WNATIVE)
  await router.deployed()
  console.log('ApeSwapMultiSwapRouter deployed at: ', router.address)
  console.log(
    'npx hardhat verify --network',
    hre.network.name,
    factories,
    router.address,
    WNATIVE
  )
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
