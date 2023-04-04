// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import './IApeRouter02.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V2
interface IV2LiquidityRouter {
    function addLiquidity(
        IApeRouter02 router,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}
