// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/libraries/SafeCast.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-periphery/contracts/base/PeripheryValidation.sol';
import '@cryptoalgebra/core/contracts/interfaces/IAlgebraPool.sol';
import '@cryptoalgebra/core/contracts/interfaces/IAlgebraFactory.sol';

import './interfaces/IAlgebraSwapRouter.sol';
import './base/PeripheryPaymentsWithFeeExtended.sol';
import './base/ContractWhitelist.sol';
import './base/CallbackValidation.sol';
import './libraries/ConstantValues.sol';
import './libraries/PathAlgebra.sol';

/// @title Algebra Swap Router
/// @notice Router for stateless execution of swaps against Algebra
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
abstract contract AlgebraSwapRouter is
    IAlgebraSwapRouter,
    PeripheryValidation,
    PeripheryPaymentsWithFeeExtended,
    ContractWhitelist,
    CallbackValidation
{
    using PathAlgebra for bytes;
    using SafeCast for uint256;

    /// @dev Used as the placeholder value for amountInCached, because the computed amount in for an exact output swap
    /// can never actually be this value
    uint256 private constant DEFAULT_AMOUNT_IN_CACHED = type(uint256).max;

    /// @dev Transient storage variable used for returning the computed amount in for an exact output swap.
    uint256 private amountInCached = DEFAULT_AMOUNT_IN_CACHED;

    /// @dev Returns the pool for the given token pair and fee. The pool contract may or may not exist.
    function getPool(
        address factory,
        address tokenA,
        address tokenB
    ) private view returns (IAlgebraPool) {
        return IAlgebraPool(IAlgebraFactory(factory).poolByPair(tokenA, tokenB));
    }

    struct SwapCallbackDataAlgebra {
        bytes path;
        address payer;
    }

    /// @inheritdoc IAlgebraSwapCallback
    function algebraSwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override contractWhitelisted(IAlgebraPool(msg.sender).factory()) {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        SwapCallbackDataAlgebra memory data = abi.decode(_data, (SwapCallbackDataAlgebra));
        (address tokenIn, address tokenOut) = data.path.decodeFirstPool();
        CallbackValidation.verifyCallback(IAlgebraPool(msg.sender).factory(), tokenIn, tokenOut);

        (bool isExactInput, uint256 amountToPay) = amount0Delta > 0
            ? (tokenIn < tokenOut, uint256(amount0Delta))
            : (tokenOut < tokenIn, uint256(amount1Delta));
        if (isExactInput) {
            pay(tokenIn, data.payer, msg.sender, amountToPay);
        } else {
            // either initiate the next swap or pay
            if (data.path.hasMultiplePools()) {
                data.path = data.path.skipToken();
                exactOutputInternal(IAlgebraPool(msg.sender).factory(), amountToPay, msg.sender, 0, data);
            } else {
                amountInCached = amountToPay;
                tokenIn = tokenOut; // swap in/out because exact output swaps are reversed
                pay(tokenIn, data.payer, msg.sender, amountToPay);
            }
        }
    }

    /// @dev Performs a single exact input swap
    function exactInputInternal(
        address factory,
        uint256 amountIn,
        address recipient,
        uint160 limitSqrtPrice,
        SwapCallbackDataAlgebra memory data
    ) private returns (uint256 amountOut) {
        // find and replace recipient addresses
        if (recipient == ConstantValues.MSG_SENDER) recipient = msg.sender;
        else if (recipient == ConstantValues.ADDRESS_THIS) recipient = address(this);

        (address tokenIn, address tokenOut) = data.path.decodeFirstPool();

        bool zeroToOne = tokenIn < tokenOut;

        (int256 amount0, int256 amount1) = getPool(factory, tokenIn, tokenOut).swap(
            recipient,
            zeroToOne,
            amountIn.toInt256(),
            limitSqrtPrice == 0
                ? (zeroToOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                : limitSqrtPrice,
            abi.encode(data)
        );

        return uint256(-(zeroToOne ? amount1 : amount0));
    }

    /// @inheritdoc IAlgebraSwapRouter
    function exactInputSingleAlgebra(ExactInputSingleParamsAlgebra memory params)
        external
        payable
        override
        contractWhitelisted(params.factory)
        checkDeadline(params.deadline)
        returns (uint256 amountOut)
    {
        // use amountIn == ConstantValues.CONTRACT_BALANCE as a flag to swap the entire balance of the contract
        bool hasAlreadyPaid;
        if (params.amountIn == ConstantValues.CONTRACT_BALANCE) {
            hasAlreadyPaid = true;
            params.amountIn = IERC20(params.tokenIn).balanceOf(address(this));
        }

        amountOut = exactInputInternal(
            params.factory,
            params.amountIn,
            params.recipient,
            params.limitSqrtPrice,
            SwapCallbackDataAlgebra({path: abi.encodePacked(params.tokenIn, params.tokenOut), payer: msg.sender})
        );
        require(amountOut >= params.amountOutMinimum, 'Too little received');
    }

    /// @inheritdoc IAlgebraSwapRouter
    function exactInputAlgebra(ExactInputParamsAlgebra memory params)
        external
        payable
        override
        contractWhitelisted(params.factory)
        checkDeadline(params.deadline)
        returns (uint256 amountOut)
    {
        // use amountIn == ConstantValues.CONTRACT_BALANCE as a flag to swap the entire balance of the contract
        bool hasAlreadyPaid;
        if (params.amountIn == ConstantValues.CONTRACT_BALANCE) {
            hasAlreadyPaid = true;
            (address tokenIn, ) = params.path.decodeFirstPool();
            params.amountIn = IERC20(tokenIn).balanceOf(address(this));
        }

        address payer = msg.sender; // msg.sender pays for the first hop

        while (true) {
            bool hasMultiplePools = params.path.hasMultiplePools();

            // the outputs of prior swaps become the inputs to subsequent ones
            params.amountIn = exactInputInternal(
                params.factory,
                params.amountIn,
                hasMultiplePools ? address(this) : params.recipient, // for intermediate swaps, this contract custodies
                0,
                SwapCallbackDataAlgebra({
                    path: params.path.getFirstPool(), // only the first pool in the path is necessary
                    payer: payer
                })
            );

            // decide whether to continue or terminate
            if (hasMultiplePools) {
                payer = address(this); // at this point, the caller has paid
                params.path = params.path.skipToken();
            } else {
                amountOut = params.amountIn;
                break;
            }
        }

        require(amountOut >= params.amountOutMinimum, 'Too little received');
    }

    /// @inheritdoc IAlgebraSwapRouter
    function exactInputSingleSupportingFeeOnTransferTokensAlgebra(ExactInputSingleParamsAlgebra memory params)
        external
        override
        contractWhitelisted(params.factory)
        checkDeadline(params.deadline)
        returns (uint256 amountOut)
    {
        SwapCallbackDataAlgebra memory data = SwapCallbackDataAlgebra({
            path: abi.encodePacked(params.tokenIn, params.tokenOut),
            payer: msg.sender
        });

        // find and replace recipient addresses
        if (params.recipient == ConstantValues.MSG_SENDER) params.recipient = msg.sender;
        else if (params.recipient == ConstantValues.ADDRESS_THIS) params.recipient = address(this);

        bool zeroToOne = params.tokenIn < params.tokenOut;

        (int256 amount0, int256 amount1) = getPool(params.factory, params.tokenIn, params.tokenOut)
            .swapSupportingFeeOnInputTokens(
                msg.sender,
                params.recipient,
                zeroToOne,
                params.amountIn.toInt256(),
                params.limitSqrtPrice == 0
                    ? (zeroToOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                    : params.limitSqrtPrice,
                abi.encode(data)
            );

        amountOut = uint256(-(zeroToOne ? amount1 : amount0));

        require(amountOut >= params.amountOutMinimum, 'Too little received');
    }

    /// @dev Performs a single exact output swap
    function exactOutputInternal(
        address factory,
        uint256 amountOut,
        address recipient,
        uint160 limitSqrtPrice,
        SwapCallbackDataAlgebra memory data
    ) private returns (uint256 amountIn) {
        // find and replace recipient addresses
        if (recipient == ConstantValues.MSG_SENDER) recipient = msg.sender;
        else if (recipient == ConstantValues.ADDRESS_THIS) recipient = address(this);

        (address tokenOut, address tokenIn) = data.path.decodeFirstPool();

        bool zeroToOne = tokenIn < tokenOut;

        (int256 amount0Delta, int256 amount1Delta) = getPool(factory, tokenIn, tokenOut).swap(
            recipient,
            zeroToOne,
            -amountOut.toInt256(),
            limitSqrtPrice == 0
                ? (zeroToOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                : limitSqrtPrice,
            abi.encode(data)
        );

        uint256 amountOutReceived;
        (amountIn, amountOutReceived) = zeroToOne
            ? (uint256(amount0Delta), uint256(-amount1Delta))
            : (uint256(amount1Delta), uint256(-amount0Delta));
        // it's technically possible to not receive the full output amount,
        // so if no price limit has been specified, require this possibility away
        if (limitSqrtPrice == 0) require(amountOutReceived == amountOut);
    }

    /// @inheritdoc IAlgebraSwapRouter
    function exactOutputSingleAlgebra(ExactOutputSingleParamsAlgebra memory params)
        external
        payable
        override
        contractWhitelisted(params.factory)
        checkDeadline(params.deadline)
        returns (uint256 amountIn)
    {
        // avoid an SLOAD by using the swap return data
        amountIn = exactOutputInternal(
            params.factory,
            params.amountOut,
            params.recipient,
            params.limitSqrtPrice,
            SwapCallbackDataAlgebra({path: abi.encodePacked(params.tokenOut, params.tokenIn), payer: msg.sender})
        );

        require(amountIn <= params.amountInMaximum, 'Too much requested');
        amountInCached = DEFAULT_AMOUNT_IN_CACHED; // has to be reset even though we don't use it in the single hop case
    }

    /// @inheritdoc IAlgebraSwapRouter
    function exactOutputAlgebra(ExactOutputParamsAlgebra memory params)
        external
        payable
        override
        contractWhitelisted(params.factory)
        checkDeadline(params.deadline)
        returns (uint256 amountIn)
    {
        // it's okay that the payer is fixed to msg.sender here, as they're only paying for the "final" exact output
        // swap, which happens first, and subsequent swaps are paid for within nested callback frames
        exactOutputInternal(
            params.factory,
            params.amountOut,
            params.recipient,
            0,
            SwapCallbackDataAlgebra({path: params.path, payer: msg.sender})
        );

        amountIn = amountInCached;
        require(amountIn <= params.amountInMaximum, 'Too much requested');
        amountInCached = DEFAULT_AMOUNT_IN_CACHED;
    }
}
