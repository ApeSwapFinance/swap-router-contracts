// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import './IPeripheryPaymentsAlgebra.sol';

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of NativeToken
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
interface IPeripheryPaymentsWithFeeAlgebra is IPeripheryPaymentsAlgebra {
    /// @notice Unwraps the contract's WNativeToken balance and sends it to recipient as NativeToken, with a percentage between
    /// 0 (exclusive), and 1 (inclusive) going to feeRecipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WNativeToken from users.
    function unwrapWNativeTokenWithFee(
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient, with a percentage between
    /// 0 (exclusive) and 1 (inclusive) going to feeRecipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) external payable;
}
