// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/base/PeripheryImmutableState.sol';
import '@uniswap/v3-core/contracts/libraries/SafeCast.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-core/contracts/libraries/TickBitmap.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';
import '@uniswap/v3-periphery/contracts/libraries/Path.sol';
import '@uniswap/v3-periphery/contracts/libraries/CallbackValidation.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

import '../base/ImmutableState.sol';
import '../interfaces/IMixedRouteQuoterV1.sol';
import '../interfaces/IApeFactory.sol';
import '../libraries/PoolTicksCounter.sol';

/// @title Provides on chain quotes for V3, V2, and MixedRoute exact input swaps
/// @notice Allows getting the expected amount out for a given swap without executing the swap
/// @notice Does not support exact output swaps since using the contract balance between exactOut swaps is not supported
/// @dev These functions are not gas efficient and should _not_ be called on chain. Instead, optimistically execute
/// the swap and check the amounts in the callback.
contract MixedRouteQuoterV1 is IMixedRouteQuoterV1, IUniswapV3SwapCallback, PeripheryImmutableState {
    using Path for bytes;
    using SafeCast for uint256;
    using PoolTicksCounter for IUniswapV3Pool;
    /// @dev Value to bit mask with path fee to determine if V2 or V3 route
    // max V3 fee:           000011110100001001000000 (24 bits)
    // mask:       1 << 23 = 100000000000000000000000 = decimal value 8388608
    uint24 private constant flagBitmask = 8388608;

    /// @dev Transient storage variable used to check a safety condition in exact output swaps.
    uint256 private amountOutCached;

    struct LocalVars {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        uint256 amountIn;
    }

    constructor(address _WETH9) PeripheryImmutableState(address(0), _WETH9) {}

    function getPool(
        IUniswapV3Factory factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) private view returns (IUniswapV3Pool) {
        return IUniswapV3Pool(factory.getPool(tokenA, tokenB, fee));
    }

    /// @dev Given an amountIn, fetch the reserves of the V2 pair and get the amountOut
    function getPairAmountOut(
        IApeRouter02 router,
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) private view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(IApeFactory(router.factory()).getPair(tokenIn, tokenOut));
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (uint256 reserveInput, uint256 reserveOutput) =
            tokenIn == tokenOut ? (reserve0, reserve1) : (reserve1, reserve0);
        return router.getAmountOut(amountIn, reserveInput, reserveOutput);
    }

    /// @inheritdoc IUniswapV3SwapCallback
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes memory path
    ) external view override {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        (address tokenIn, address tokenOut, uint24 fee) = path.decodeFirstPool();

        (bool isExactInput, uint256 amountReceived) =
            amount0Delta > 0
                ? (tokenIn < tokenOut, uint256(-amount1Delta))
                : (tokenOut < tokenIn, uint256(-amount0Delta));

        IUniswapV3Pool pool = getPool(IUniswapV3Factory(IUniswapV3Pool(msg.sender).factory()), tokenIn, tokenOut, fee);
        (uint160 v3SqrtPriceX96After, int24 tickAfter, , , , , ) = pool.slot0();

        if (isExactInput) {
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, amountReceived)
                mstore(add(ptr, 0x20), v3SqrtPriceX96After)
                mstore(add(ptr, 0x40), tickAfter)
                revert(ptr, 0x60)
            }
        } else {
            /// since we don't support exactOutput, revert here
            revert('Exact output quote not supported');
        }
    }

    /// @dev Parses a revert reason that should contain the numeric quote
    function parseRevertReason(bytes memory reason)
        private
        pure
        returns (
            uint256 amount,
            uint160 sqrtPriceX96After,
            int24 tickAfter
        )
    {
        if (reason.length != 0x60) {
            if (reason.length < 0x44) revert('Unexpected error');
            assembly {
                reason := add(reason, 0x04)
            }
            revert(abi.decode(reason, (string)));
        }
        return abi.decode(reason, (uint256, uint160, int24));
    }

    function handleV3Revert(
        bytes memory reason,
        IUniswapV3Pool pool,
        uint256 gasEstimate
    )
        private
        view
        returns (
            uint256 amount,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256
        )
    {
        int24 tickBefore;
        int24 tickAfter;
        (, tickBefore, , , , , ) = pool.slot0();
        (amount, sqrtPriceX96After, tickAfter) = parseRevertReason(reason);

        initializedTicksCrossed = pool.countInitializedTicksCrossed(tickBefore, tickAfter);

        return (amount, sqrtPriceX96After, initializedTicksCrossed, gasEstimate);
    }

    /// @dev Fetch an exactIn quote for a V3 Pool on chain
    function quoteExactInputSingleV3(IUniswapV3Factory factory, QuoteExactInputSingleV3Params memory params)
        public
        override
        returns (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        )
    {
        bool zeroForOne = params.tokenIn < params.tokenOut;
        IUniswapV3Pool pool = getPool(factory, params.tokenIn, params.tokenOut, params.fee);

        uint256 gasBefore = gasleft();
        try
            pool.swap(
                address(this), // address(0) might cause issues with some tokens
                zeroForOne,
                params.amountIn.toInt256(),
                params.sqrtPriceLimitX96 == 0
                    ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                    : params.sqrtPriceLimitX96,
                abi.encodePacked(params.tokenIn, params.fee, params.tokenOut)
            )
        {} catch (bytes memory reason) {
            gasEstimate = gasBefore - gasleft();
            return handleV3Revert(reason, pool, gasEstimate);
        }
    }

    /// @dev Fetch an exactIn quote for a V2 pair on chain
    function quoteExactInputSingleV2(IApeRouter02 router, QuoteExactInputSingleV2Params memory params)
        public
        view
        override
        returns (uint256 amountOut)
    {
        amountOut = getPairAmountOut(router, params.amountIn, params.tokenIn, params.tokenOut);
    }

    /// @dev Get the quote for an exactIn swap between an array of V2 and/or V3 pools
    /// @notice To encode a V2 pair within the path, use 0x800000 (hex value of 8388608) for the fee between the two token addresses
    function quoteExactInput(
        bytes[] memory path,
        address[] memory factoryOrRouter,
        uint256 amountIn
    )
        public
        override
        returns (
            uint256 amountOut,
            uint160[] memory v3SqrtPriceX96AfterList,
            uint32[] memory v3InitializedTicksCrossedList,
            uint256 v3SwapGasEstimate
        )
    {
        LocalVars memory vars;
        vars.amountIn = amountIn;
        uint256 poolCount = 0;
        uint256 i = 0;
        for (i = 0; i < path.length; i++) {
            poolCount += path[i].numPools();
        }
        v3SqrtPriceX96AfterList = new uint160[](poolCount);
        v3InitializedTicksCrossedList = new uint32[](poolCount);

        i = 0;
        uint256 pathIndex = 0;
        bytes memory currentPath;
        while (pathIndex < path.length) {
            currentPath = path[pathIndex];
            while (true) {
                (vars.tokenIn, vars.tokenOut, vars.fee) = currentPath.decodeFirstPool();

                if (vars.fee & flagBitmask != 0) {
                    vars.amountIn = quoteExactInputSingleV2(
                        IApeRouter02(factoryOrRouter[pathIndex]),
                        QuoteExactInputSingleV2Params({
                            tokenIn: vars.tokenIn,
                            tokenOut: vars.tokenOut,
                            amountIn: amountIn
                        })
                    );
                } else {
                    /// the outputs of prior swaps become the inputs to subsequent ones
                    (
                        uint256 _amountOut,
                        uint160 _sqrtPriceX96After,
                        uint32 _initializedTicksCrossed,
                        uint256 _gasEstimate
                    ) =
                        quoteExactInputSingleV3(
                            IUniswapV3Factory(factoryOrRouter[pathIndex]),
                            QuoteExactInputSingleV3Params({
                                tokenIn: vars.tokenIn,
                                tokenOut: vars.tokenOut,
                                fee: vars.fee,
                                amountIn: vars.amountIn,
                                sqrtPriceLimitX96: 0
                            })
                        );
                    v3SqrtPriceX96AfterList[i] = _sqrtPriceX96After;
                    v3InitializedTicksCrossedList[i] = _initializedTicksCrossed;
                    v3SwapGasEstimate += _gasEstimate;
                    vars.amountIn = _amountOut;
                }
                i++;

                /// decide whether to continue or terminate
                if (currentPath.hasMultiplePools()) {
                    currentPath = currentPath.skipToken();
                } else {
                    pathIndex++;
                    break;
                }
            }
        }
        return (vars.amountIn, v3SqrtPriceX96AfterList, v3InitializedTicksCrossedList, v3SwapGasEstimate);
    }
}
