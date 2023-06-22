// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/ISelfPermit.sol';

import './IV2SwapRouter.sol';
import './IV3SwapRouter.sol';
import './IApproveAndCall.sol';
import './IMulticallExtended.sol';
import './IContractWhitelist.sol';

/// @title Uniswap V2 and V3 Swap Router
interface IApeSwapMultiSwapRouter is IV2SwapRouter, IV3SwapRouter, IMulticallExtended {

}
