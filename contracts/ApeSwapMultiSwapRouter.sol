// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import './interfaces/IApeSwapMultiSwapRouter.sol';
import './base/FactoryWhitelist.sol';
import './V2SwapRouter.sol';
import './V2Liquidity.sol';
import './V3SwapRouter.sol';
import './base/MulticallExtended.sol';

/// @title Uniswap V2 and V3 Swap Router
contract ApeSwapMultiSwapRouter is IApeSwapMultiSwapRouter, V2SwapRouter, V2Liquidity, V3SwapRouter, MulticallExtended {
    constructor(address[] memory _factories, address _WETH9)
        FactoryWhitelist(_factories)
        PeripheryImmutableState(address(0), _WETH9)
    {}
}
