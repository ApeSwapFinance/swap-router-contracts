// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/IContractWhitelist.sol';

/// @title ContractWhitelist
/// @notice Whitelisting of contracts
abstract contract ContractWhitelist is IContractWhitelist, Ownable {
    event ContractsWhitelistChanged(address[] _contract, bytes32[] _init_code_hashes);
    mapping(address => bytes32) public hashes;

    modifier contractWhitelisted(address contractAddress) {
        require(hashes[contractAddress] != bytes32(0), 'Contract not whitelisted');
        _;
    }

    constructor(address[] memory _contracts, bytes32[] memory _init_code_hashes) Ownable() {
        _whitelistContracts(_contracts, _init_code_hashes);
    }

    function whitelistContracts(address[] memory _contracts, bytes32[] memory _init_code_hashes)
        external
        override
        onlyOwner
    {
        _whitelistContracts(_contracts, _init_code_hashes);
    }

    function _whitelistContracts(address[] memory _contracts, bytes32[] memory _init_code_hashes) private {
        for (uint256 i = 0; i < _contracts.length; i++) {
            hashes[_contracts[i]] = _init_code_hashes[i];
        }
        emit ContractsWhitelistChanged(_contracts, _init_code_hashes);
    }
}
