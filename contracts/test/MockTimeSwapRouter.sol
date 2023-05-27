// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import '../ApeSwapMultiSwapRouter.sol';

contract MockTimeApeSwapMultiSwapRouter is ApeSwapMultiSwapRouter {
    uint256 time;

    constructor(
        address _factoryV2,
        address factoryV3,
        address _positionManager,
        address _WETH9
    ) ApeSwapMultiSwapRouter(new address[](0), new bytes32[](0), _WETH9) {}

    function _blockTimestamp() internal view override returns (uint256) {
        return time;
    }

    function setTime(uint256 _time) external {
        time = _time;
    }
}
