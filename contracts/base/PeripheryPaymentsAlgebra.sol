// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '../interfaces/IPeripheryPaymentsAlgebra.sol';
import '../interfaces/external/IWNativeToken.sol';

import '../libraries/TransferHelperAlgebra.sol';

import './PeripheryImmutableStateAlgebra.sol';

/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
abstract contract PeripheryPaymentsAlgebra is IPeripheryPaymentsAlgebra, PeripheryImmutableStateAlgebra {
    receive() external payable {
        require(msg.sender == WNativeToken, 'Not WNativeToken');
    }

    /// @inheritdoc IPeripheryPaymentsAlgebra
    function unwrapWNativeToken(uint256 amountMinimum, address recipient) external payable override {
        uint256 balanceWNativeToken = IWNativeToken(WNativeToken).balanceOf(address(this));
        require(balanceWNativeToken >= amountMinimum, 'Insufficient WNativeToken');

        if (balanceWNativeToken > 0) {
            IWNativeToken(WNativeToken).withdraw(balanceWNativeToken);
            TransferHelperAlgebra.safeTransferNative(recipient, balanceWNativeToken);
        }
    }

    /// @inheritdoc IPeripheryPaymentsAlgebra
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable override {
        uint256 balanceToken = IERC20(token).balanceOf(address(this));
        require(balanceToken >= amountMinimum, 'Insufficient token');

        if (balanceToken > 0) {
            TransferHelperAlgebra.safeTransfer(token, recipient, balanceToken);
        }
    }

    /// @inheritdoc IPeripheryPaymentsAlgebra
    function refundNativeToken() external payable override {
        if (address(this).balance > 0) TransferHelperAlgebra.safeTransferNative(msg.sender, address(this).balance);
    }

    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function pay(
        address token,
        address payer,
        address recipient,
        uint256 value
    ) internal {
        if (token == WNativeToken && address(this).balance >= value) {
            // pay with WNativeToken
            IWNativeToken(WNativeToken).deposit{value: value}(); // wrap only what is needed to pay
            IWNativeToken(WNativeToken).transfer(recipient, value);
        } else if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            TransferHelperAlgebra.safeTransfer(token, recipient, value);
        } else {
            // pull payment
            TransferHelperAlgebra.safeTransferFrom(token, payer, recipient, value);
        }
    }
}
