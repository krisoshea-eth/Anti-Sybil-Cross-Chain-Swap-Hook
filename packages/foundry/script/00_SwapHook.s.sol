// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import { Hooks } from "v4-core/src/libraries/Hooks.sol";
import { PoolManager } from "v4-core/src/PoolManager.sol";
import { IPoolManager } from "v4-core/src/interfaces/IPoolManager.sol";
import { WorldcoinVerifier } from "../contracts/WorldcoinVerifier.sol";
import { WorldIDVerifiedNFT } from "../contracts/WorldIDVerifiedNFT.sol";
import { IWorldID } from "../contracts/IWorldID.sol";
import { PoolModifyLiquidityTest } from
  "v4-core/src/test/PoolModifyLiquidityTest.sol";
import { PoolSwapTest } from "v4-core/src/test/PoolSwapTest.sol";
import { PoolDonateTest } from "v4-core/src/test/PoolDonateTest.sol";
import { SwapHook } from "../contracts/SwapHook.sol";
import { HookMiner } from "../test/utils/HookMiner.sol";

contract SwapHookScript is Script {
  address constant CREATE2_DEPLOYER =
    address(0x4e59b44847b379578588920cA78FbF26c0B4956C);

  //TODO change to sepolia
  address constant GOERLI_POOLMANAGER =
    address(0x3A9D48AB9751398BbFa63ad67599Bb04e4BdF98b);

  function setUp() public { }

  function run() public {
    // hook contracts must have specific flags encoded in the address
    uint160 flags = uint160(
        Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG
        | Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG
    );

    // Deploy WorldcoinVerifier first
    vm.broadcast();
    WorldIDVerifiedNFT nft = new WorldIDVerifiedNFT();
    WorldcoinVerifier worldcoinVerifier = new WorldcoinVerifier(IWorldID(address(0)), "your-app-id", "your-action", nft);

    // Mine a salt that will produce a hook address with the correct flags
    (address hookAddress, bytes32 salt) = HookMiner.find(
        CREATE2_DEPLOYER,
        flags,
        type(SwapHook).creationCode,
        abi.encode(address(GOERLI_POOLMANAGER), address(worldcoinVerifier))
    );

    // Deploy the hook using CREATE2
    vm.broadcast();
    SwapHook swapHook = new SwapHook{ salt: salt }(
        IPoolManager(address(GOERLI_POOLMANAGER)),
        nft
    );
    require(
        address(swapHook) == hookAddress, "CounterScript: hook address mismatch"
    );
  }
}
