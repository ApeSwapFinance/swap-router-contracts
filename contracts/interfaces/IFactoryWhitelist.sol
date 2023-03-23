// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

/// @title FactoryWhitelist
/// @notice Whitelisting of factories
interface IFactoryWhitelist {
    function addFactory(address _factory) external;

    function removeFactory(address _factory) external;
}
