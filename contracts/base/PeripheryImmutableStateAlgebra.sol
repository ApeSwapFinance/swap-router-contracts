// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '../interfaces/IPeripheryImmutableStateAlgebra.sol';

/// @title Immutable state
/// @notice Immutable state used by periphery contracts
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
abstract contract PeripheryImmutableStateAlgebra is IPeripheryImmutableStateAlgebra {
    /// @inheritdoc IPeripheryImmutableStateAlgebra
    address public immutable override factory;
    /// @inheritdoc IPeripheryImmutableStateAlgebra
    address public immutable override poolDeployer;
    /// @inheritdoc IPeripheryImmutableStateAlgebra
    address public immutable override WNativeToken;

    constructor(
        address _factory,
        address _WNativeToken,
        address _poolDeployer
    ) {
        factory = _factory;
        poolDeployer = _poolDeployer;
        WNativeToken = _WNativeToken;
    }
}
