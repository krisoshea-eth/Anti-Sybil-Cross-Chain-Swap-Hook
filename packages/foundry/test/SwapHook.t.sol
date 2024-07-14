// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { WorldcoinVerifier } from "../contracts/WorldcoinVerifier.sol";
import { WorldIDVerifiedNFT } from "../contracts/WorldIDVerifiedNFT.sol";
import { IWorldID } from "../contracts/IWorldID.sol";
import { IHooks } from "v4-core/src/interfaces/IHooks.sol";
import { Hooks } from "v4-core/src/libraries/Hooks.sol";
import { TickMath } from "v4-core/src/libraries/TickMath.sol";
import { IPoolManager } from "v4-core/src/interfaces/IPoolManager.sol";

import {PoolManager} from "v4-core/src/PoolManager.sol";

import { PoolKey } from "v4-core/src/types/PoolKey.sol";
import { BalanceDelta } from "v4-core/src/types/BalanceDelta.sol";
import { PoolId, PoolIdLibrary } from "v4-core/src/types/PoolId.sol";
import { CurrencyLibrary, Currency } from "v4-core/src/types/Currency.sol";
import { PoolSwapTest } from "v4-core/src/test/PoolSwapTest.sol";
import { Deployers } from "v4-core/test/utils/Deployers.sol";
import { SwapHook } from "../contracts/SwapHook.sol";
import { StateLibrary } from "v4-core/src/libraries/StateLibrary.sol";

contract SwapHookTest is Test, Deployers, IERC721Receiver {
  using PoolIdLibrary for PoolKey;
  using CurrencyLibrary for Currency;
  using StateLibrary for IPoolManager;

  SwapHook hook;
  PoolId poolId;
  IPoolManager poolManager;
  WorldcoinVerifier worldcoinVerifier;
  WorldIDVerifiedNFT nft;
  address public user;
  

  function setUp() public {
      // creates the pool manager, utility routers, and test tokens
      Deployers.deployFreshManagerAndRouters();
      (currency0, currency1) = Deployers.deployMintAndApprove2Currencies();
  
      // Deploy WorldcoinVerifier
      nft = new WorldIDVerifiedNFT();
      worldcoinVerifier = new WorldcoinVerifier(IWorldID(address(0)), "your-app-id", "your-action", nft);
  
      // Create a mock EOA address
      user = makeAddr("user");
      vm.label(user, "user");
  
      // Mint equal amounts of currency0 and currency1 to the user
      uint256 mintAmount = 1000 * 10**18; // 1000 tokens with 18 decimals
      MockERC20(Currency.unwrap(currency0)).transfer(user, mintAmount);
      MockERC20(Currency.unwrap(currency1)).transfer(user, mintAmount);

       // Log the user's balances
    uint256 balance0 = MockERC20(Currency.unwrap(currency0)).balanceOf(user);
    uint256 balance1 = MockERC20(Currency.unwrap(currency1)).balanceOf(user);
    
    console2.log("User balance of currency0:", balance0);
    console2.log("User balance of currency1:", balance1);

     // Approve the swap router to spend the user's tokens
     vm.startPrank(user);
     MockERC20(Currency.unwrap(currency0)).approve(address(swapRouter), type(uint256).max);
     MockERC20(Currency.unwrap(currency1)).approve(address(swapRouter), type(uint256).max);
     vm.stopPrank();
  
      // Deploy the hook to an address with the correct flags
      address payable flags = payable(address(
        uint160(
            Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG
            | Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG
        ) ^ (0x4444 << 144) // Namespace the hook to avoid collisions
    ));
    deployCodeTo("SwapHook.sol:SwapHook", abi.encode(manager, nft), flags);
    hook = SwapHook(flags);
  
      // Create the pool
      key = PoolKey(currency0, currency1, 3000, 60, IHooks(hook));
      poolId = key.toId();
      manager.initialize(key, SQRT_PRICE_1_1, ZERO_BYTES);
  
      // Provide full-range liquidity to the pool
      modifyLiquidityRouter.modifyLiquidity(
          key,
          IPoolManager.ModifyLiquidityParams(
              TickMath.minUsableTick(60), TickMath.maxUsableTick(60), 10_000 ether, 0
          ),
          ZERO_BYTES
      );
  }

    function onERC721Received(
      address,
      address,
      uint256,
      bytes memory
  ) public virtual override returns (bytes4) {
      return this.onERC721Received.selector;
  }

  function testCounterHooks() public {
    assertEq(hook.beforeSwapCount(poolId), 0);
    assertEq(hook.afterSwapCount(poolId), 0);
    // Get the address of the PoolSwapTest contract
    nft.mint(user);

    vm.startPrank(user);

   

     // Generate mock World ID proof data
     uint256 root = 123; // mock root
     uint256 nullifierHash = 456; // mock nullifier hash
     uint256[8] memory proof; // mock proof
 
     // Encode the World ID proof data
     bytes memory worldIDData = abi.encode(user, root, nullifierHash, proof);

    // Perform a test swap //
    bool zeroForOne = true;
    int256 amountSpecified = -1e18; // negative number indicates exact input swap!
    BalanceDelta swapDelta = swap(key, zeroForOne, amountSpecified, worldIDData);
    // ------------------- //

    vm.stopPrank();

    assertEq(int256(swapDelta.amount0()), amountSpecified);

    assertEq(hook.beforeSwapCount(poolId), 1);
    assertEq(hook.afterSwapCount(poolId), 1);
  }

  function test_swap() public {
      // Get the address of the PoolSwapTest contract
     nft.mint(user);

     vm.startPrank(user);


    // Generate mock World ID proof data
    uint256 root = 123; // mock root
    uint256 nullifierHash = 456; // mock nullifier hash
    uint256[8] memory proof; // mock proof

    // Encode the World ID proof data
    // Encode the World ID proof data, including the user's address
    bytes memory worldIDData = abi.encode(user, root, nullifierHash, proof);

    // Perform a test swap //
    bool zeroForOne = true;
    int256 amountSpecified = -1e18; // negative number indicates exact input swap!
    BalanceDelta swapDelta = swap(key, zeroForOne, amountSpecified, worldIDData);
    // ------------------- //

    // Stop pranking
    vm.stopPrank();

       // Add your assertions here
       assertEq(int256(swapDelta.amount0()), amountSpecified);

       
    // Add your assertions here
  }

  function testWorldIDVerification() public {
    nft.mint(user);

    vm.startPrank(user);

    // Generate valid mock World ID proof data
    uint256 root = 123;
    uint256 nullifierHash = 456;
    uint256[8] memory proof;

    // Encode the valid World ID proof data
    bytes memory worldIDData = abi.encode(user, root, nullifierHash, proof);

    // This swap should succeed
    swap(key, true, -1e18, worldIDData);

    vm.stopPrank();
  }

  function testNoWorldIDVerification() public {
      // Ensure the user doesn't have an NFT to start with
      assertEq(nft.balanceOf(user), 0);

      // Prepare swap parameters
      bool zeroForOne = true;
      int256 amountSpecified = -1e18; // negative number indicates exact input swap
      bytes memory emptyProofData = new bytes(0);

      // Try to perform a swap without having the NFT
      vm.startPrank(user);
      vm.expectRevert(abi.encodeWithSignature("FailedHookCall()"));
      swap(key, zeroForOne, amountSpecified, emptyProofData);
      vm.stopPrank();

      // Verify that the user still doesn't have an NFT
      assertEq(nft.balanceOf(user), 0);
  }

  // Helper function to decode FailedHookCall error
  function getFailedHookCallError() internal pure returns (bytes memory) {
      return abi.encodeWithSignature("FailedHookCall()");
  }
}
