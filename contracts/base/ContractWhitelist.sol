// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/IContractWhitelist.sol';

/// @title ContractWhitelist
/// @notice Whitelisting of contracts
abstract contract ContractWhitelist is IContractWhitelist, Ownable {
    event ContractsWhitelistChanged(address[] factory, bool whitelist);
    mapping(address => bool) public contracts;

    modifier contractWhitelisted(address contractAddress) {
        require(contracts[contractAddress], 'Contract not whitelisted');
        _;
    }

    constructor(address[] memory _contracts) Ownable() {
        _whitelistContracts(_contracts, true);
    }

    function whitelistContracts(address[] memory _contracts, bool _whitelist) external override onlyOwner {
        _whitelistContracts(_contracts, _whitelist);
    }

    function _whitelistContracts(address[] memory _contracts, bool _whitelist) private {
        for (uint256 i = 0; i < _contracts.length; i++) {
            contracts[_contracts[i]] = _whitelist;
        }
        emit ContractsWhitelistChanged(_contracts, _whitelist);
    }
}
