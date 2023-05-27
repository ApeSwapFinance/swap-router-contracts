// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import './interfaces/IApeSwapMultiSwapRouter.sol';
import './base/ContractWhitelist.sol';
import './V2SwapRouter.sol';
import './V2LiquidityRouter.sol';
import './V3SwapRouter.sol';
import './AlgebraSwapRouter.sol';
import './base/MulticallExtended.sol';

/// @title Uniswap V2 and V3 Swap Router
contract ApeSwapMultiSwapRouter is
    IApeSwapMultiSwapRouter,
    V2SwapRouter,
    V2LiquidityRouter,
    V3SwapRouter,
    AlgebraSwapRouter,
    MulticallExtended
{
    constructor(
        address[] memory _factories,
        bytes32[] memory _init_code_hashes,
        address _WETH9
    ) ContractWhitelist(_factories, _init_code_hashes) PeripheryImmutableState(address(0), _WETH9) {}
}
