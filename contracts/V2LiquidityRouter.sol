// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './interfaces/IV2LiquidityRouter.sol';
import './interfaces/IApeFactory.sol';
import './interfaces/IApePair.sol';
import './base/PeripheryPaymentsWithFeeExtended.sol';
import './base/ContractWhitelist.sol';
import './libraries/Constants.sol';

/// @title Uniswap V2 Swap Router
/// @notice Router for stateless execution of swaps against Uniswap V2
abstract contract V2LiquidityRouter is IV2LiquidityRouter, PeripheryPaymentsWithFeeExtended, ContractWhitelist {
    using LowGasSafeMath for uint256;

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
            IApePair(IApeFactory(router.factory()).getPair(tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA < tokenB ? (reserveA, reserveB) : (reserveB, reserveA);

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = router.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'V2LiquidityRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = router.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'V2LiquidityRouter: INSUFFICIENT_A_AMOUNT');
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
        contractWhitelisted(address(router))
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

        liquidity = IApePair(pair).mint(to);
    }
}
