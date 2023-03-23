// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/IFactoryWhitelist.sol';

/// @title FactoryWhitelist
/// @notice Whitelisting of factories
abstract contract FactoryWhitelist is IFactoryWhitelist, Ownable {
    event FactoryAdded(address router);
    event FactoryRemoved(address router);
    mapping(address => bool) public factories;

    modifier factoryWhitelisted(address factory) {
        require(factories[factory], 'Factory not whitelisted');
        _;
    }

    constructor(address[] memory _factories) Ownable() {
        for (uint256 i = 0; i < _factories.length; i++) {
            factories[_factories[i]] = true;
        }
    }

    function addFactory(address _factory) external override onlyOwner {
        require(!factories[_factory], 'Factory is already added');
        factories[_factory] = true;
        emit FactoryAdded(_factory);
    }

    function removeFactory(address _factory) external override onlyOwner {
        require(factories[_factory], 'Factory is not present');
        factories[_factory] = false;
        emit FactoryRemoved(_factory);
    }
}
