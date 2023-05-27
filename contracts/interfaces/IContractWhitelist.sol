// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

/// @title ContractWhitelist
/// @notice Whitelisting of factories
interface IContractWhitelist {
    function whitelistContracts(address[] memory _contracts, bytes32[] memory _init_code_hashes) external;
}
