// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './interfaces/IV2SwapRouter.sol';
import './interfaces/IApeFactory.sol';
import './base/PeripheryPaymentsWithFeeExtended.sol';
import './base/FactoryWhitelist.sol';
import './libraries/Constants.sol';

/// @title Uniswap V2 Swap Router
/// @notice Router for stateless execution of swaps against Uniswap V2
abstract contract V2SwapRouter is IV2SwapRouter, PeripheryPaymentsWithFeeExtended, FactoryWhitelist {
    using LowGasSafeMath for uint256;

    // supports fee-on-transfer tokens
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        IApeRouter02 router,
        address[] memory path,
        address _to
    ) private {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = input < output ? (input, output) : (output, input);
            IUniswapV2Pair pair = IUniswapV2Pair(IApeFactory(router.factory()).getPair(input, output));
            uint256 amountInput;
            uint256 amountOutput;
            // scope to avoid stack too deep errors
            {
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) =
                    input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = router.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint256 amount0Out, uint256 amount1Out) =
                input == token0 ? (uint256(0), amountOutput) : (amountOutput, uint256(0));
            address to = i < path.length - 2 ? IApeFactory(router.factory()).getPair(output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    /// @inheritdoc IV2SwapRouter
    function swapExactTokensForTokens(
        IApeRouter02 router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable override dexWhitelisted(address(router)) returns (uint256 amountOut) {
        // use amountIn == Constants.CONTRACT_BALANCE as a flag to swap the entire balance of the contract
        bool hasAlreadyPaid;
        if (amountIn == Constants.CONTRACT_BALANCE) {
            hasAlreadyPaid = true;
            amountIn = IERC20(path[0]).balanceOf(address(this));
        }

        pay(
            path[0],
            hasAlreadyPaid ? address(this) : msg.sender,
            IApeFactory(router.factory()).getPair(path[0], path[1]),
            amountIn
        );

        // find and replace to addresses
        if (to == Constants.MSG_SENDER) to = msg.sender;
        else if (to == Constants.ADDRESS_THIS) to = address(this);

        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);

        _swap(router, path, to);

        amountOut = IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore);
        require(amountOut >= amountOutMin, 'Too little received');
    }

    /// @inheritdoc IV2SwapRouter
    function swapTokensForExactTokens(
        IApeRouter02 router,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) external payable override dexWhitelisted(address(router)) returns (uint256 amountIn) {
        amountIn = router.getAmountsIn(amountOut, path)[0];
        require(amountIn <= amountInMax, 'Too much requested');

        pay(path[0], msg.sender, IApeFactory(router.factory()).getPair(path[0], path[1]), amountIn);

        // find and replace to addresses
        if (to == Constants.MSG_SENDER) to = msg.sender;
        else if (to == Constants.ADDRESS_THIS) to = address(this);

        _swap(router, path, to);
    }

    function _addLiquidity(
        IApeRouter02 router,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        if (IApeFactory(router.factory()).getPair(tokenA, tokenB) == address(0)) {
            IApeFactory(router.factory()).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB, ) =
            IUniswapV2Pair(IApeFactory(router.factory()).getPair(tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA < tokenB ? (reserveA, reserveB) : (reserveB, reserveA);

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = router.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'ApeRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = router.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'ApeRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

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
        virtual
        override
        dexWhitelisted(address(router))
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB) = _addLiquidity(
            router,
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        address pair = IApeFactory(router.factory()).getPair(tokenA, tokenB);
        pay(tokenA, msg.sender, pair, amountA);
        pay(tokenB, msg.sender, pair, amountB);

        // find and replace to addresses
        if (to == Constants.MSG_SENDER) to = msg.sender;
        else if (to == Constants.ADDRESS_THIS) to = address(this);

        liquidity = IUniswapV2Pair(pair).mint(to);
    }
}
