// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { BaseHook } from "v4-periphery/BaseHook.sol";
import { Hooks } from "v4-core/src/libraries/Hooks.sol";
import { IPoolManager } from "v4-core/src/interfaces/IPoolManager.sol";
import "./WorldcoinVerifier.sol";
import "./WorldIDVerifiedNFT.sol";
import { PoolKey } from "v4-core/src/types/PoolKey.sol";
import { PoolId, PoolIdLibrary } from "v4-core/src/types/PoolId.sol";
import { BalanceDelta } from "v4-core/src/types/BalanceDelta.sol";
import {
  BeforeSwapDelta,
  BeforeSwapDeltaLibrary
} from "v4-core/src/types/BeforeSwapDelta.sol";
import { OApp } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";

contract SwapHook is BaseHook {
  using PoolIdLibrary for PoolKey;

  // NOTE: ---------------------------------------------------------
  // state variables should typically be unique to a pool
  // a single hook contract should be able to service multiple pools
  // ---------------------------------------------------------------
  IPoolManager poolManager;
  WorldIDVerifiedNFT public immutable worldIdNFT;

  mapping(PoolId => uint256 count) public beforeSwapCount;
  mapping(PoolId => uint256 count) public afterSwapCount;

  constructor(IPoolManager _poolManager, WorldIDVerifiedNFT _worldIdNFT) BaseHook(_poolManager) {
    poolManager = _poolManager;
    worldIdNFT = _worldIdNFT;
}

  function getHookPermissions()
    public
    pure
    override
    returns (Hooks.Permissions memory)
  {
    return Hooks.Permissions({
      beforeInitialize: false,
      afterInitialize: false,
      beforeAddLiquidity: false,
      afterAddLiquidity: false,
      beforeRemoveLiquidity: false,
      afterRemoveLiquidity: false,
      beforeSwap: true,
      afterSwap: true,
      beforeDonate: false,
      afterDonate: false,
      beforeSwapReturnDelta: false,
      afterSwapReturnDelta: true,
      afterAddLiquidityReturnDelta: false,
      afterRemoveLiquidityReturnDelta: false
    });
  }

  // -----------------------------------------------
  // NOTE: see IHooks.sol for function documentation
  // -----------------------------------------------

  function beforeSwap(
    address sender,
    PoolKey calldata key,
    IPoolManager.SwapParams calldata,
    bytes calldata data
  ) external override returns (bytes4, BeforeSwapDelta, uint24) {
    beforeSwapCount[key.toId()]++;

    (address user, uint256 root, uint256 nullifierHash, uint256[8] memory proof) = abi.decode(data, (address, uint256, uint256, uint256[8]));
    
    // Check if the sender has the World ID Verified NFT
    require(WorldIDVerifiedNFT(address(worldIdNFT)).balanceOf(user) > 0, "Sender is not World ID verified");

    return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
  }

  function afterSwap(
    address,
    PoolKey calldata key,
    IPoolManager.SwapParams calldata,
    BalanceDelta delta,
    bytes calldata
  ) external override returns (bytes4, int128) {
    
    afterSwapCount[key.toId()]++;

    poolManager.take(key.currency1, address(this), uint128(delta.amount1()));

    // oERC20 BURN
    // oERC20 MINT
    
    return (BaseHook.afterSwap.selector, delta.amount1());
  }
}
