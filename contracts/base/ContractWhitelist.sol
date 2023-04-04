// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/IContractWhitelist.sol';

/// @title ContractWhitelist
/// @notice Whitelisting of factories
abstract contract ContractWhitelist is IContractWhitelist, Ownable {
    event ContractsWhitelistChanged(address[] factory, bool whitelist);
    mapping(address => bool) public factories;

    modifier contractWhitelisted(address factory) {
        require(factories[factory], 'Factory not whitelisted');
        _;
    }

    constructor(address[] memory _contracts) Ownable() {
        whitelistContract(_contracts, true);
    }

    function whitelistContract(address[] memory _contracts, bool _whitelist) public override {
        for (uint256 i = 0; i < _contracts.length; i++) {
            factories[_contracts[i]] = _whitelist;
        }
        emit ContractsWhitelistChanged(_contracts, _whitelist);
    }
}
