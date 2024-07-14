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

  address constant SEPOLIA_POOLMANAGER =
    address(0xFf34e285F8ED393E366046153e3C16484A4dD674);

    address constant LZ_ENDPOINT = address(0x6EDCE65403992e310A62460808c4b910D972f10f); // Add LayerZero endpoint address

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
        abi.encode("SwapHookToken",
                "SHT",
                LZ_ENDPOINT,
                address(this),
                address(SEPOLIA_POOLMANAGER),
                address(nft))
    );

    // Deploy the hook using CREATE2
    vm.broadcast();
    SwapHook swapHook = new SwapHook{ salt: salt }(
            "SwapHookToken",
            "SHT",
            LZ_ENDPOINT,
            address(this),
            IPoolManager(address(SEPOLIA_POOLMANAGER)),
            nft
    );
    require(
        address(swapHook) == hookAddress, "CounterScript: hook address mismatch"
    );
  }
}
