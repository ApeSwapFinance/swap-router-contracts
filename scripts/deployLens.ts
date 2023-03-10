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
  const { factoryV2, factoryV3, positionManager, WNATIVE } = getNetworkConfig(hre.network.name)
  const RouteQuoter = await ethers.getContractFactory('MixedRouteQuoterV1')
  let routeQuoter = await RouteQuoter.deploy(factoryV3, factoryV2, WNATIVE)
  await routeQuoter.deployed();
  console.log('MixedRouteQuoterV1 deployed at: ', routeQuoter.address)
  console.log('npx hardhat verify --network', hre.network.name, routeQuoter.address, factoryV3, factoryV2, WNATIVE)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
