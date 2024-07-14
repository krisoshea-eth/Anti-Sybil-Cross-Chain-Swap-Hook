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
import { OApp, Origin, MessagingFee } from "LayerZero-v2/oapp/contracts/oapp/OApp.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OFT } from "lib/LayerZero-v2/packages/layerzero-v2/evm/oapp/contracts/oft/OFT.sol";
import { SendParam, OFTReceipt, MessagingReceipt, MessagingFee } from "lib/LayerZero-v2/packages/layerzero-v2/evm/oapp/contracts/oft/interfaces/IOFT.sol";

contract SwapHook is BaseHook, OFT {
  using PoolIdLibrary for PoolKey;

  event CrossChainTransferInitiated(address user, uint256 amount, uint32 dstEid);
  event TokensLockedForCrossChainTransfer(address sender, uint256 amount);
  event DebitCalled(address sender, uint256 amount);
  event CreditCalled(address recipient, uint256 amount);

  // NOTE: ---------------------------------------------------------
  // state variables should typically be unique to a pool
  // a single hook contract should be able to service multiple pools
  // ---------------------------------------------------------------
  IPoolManager poolManager;
  WorldIDVerifiedNFT public immutable worldIdNFT;
  string public crossChainData;

  mapping(PoolId => uint256 count) public beforeSwapCount;
  mapping(PoolId => uint256 count) public afterSwapCount;
  mapping(address => uint256) public lockedTokens;
  mapping(PoolId => address) public lastSwapUser;

  struct CrossChainTransferData {
    uint32 dstEid;
    uint256 crossChainFee;
}

  constructor(string memory _name,
    string memory _symbol,
    address _lzEndpoint,
    address _owner, IPoolManager _poolManager, WorldIDVerifiedNFT _worldIdNFT) BaseHook(_poolManager) OFT(_name, _symbol, _lzEndpoint, _owner) Ownable(_owner)  {
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
    IPoolManager.SwapParams calldata params,
    bytes calldata hookData
  ) external override returns (bytes4, BeforeSwapDelta, uint24) {
    beforeSwapCount[key.toId()]++;

    (address user, uint256 root, uint256 nullifierHash, uint256[8] memory proof) = abi.decode(hookData, (address, uint256, uint256, uint256[8]));
    
    // Check if the sender has the World ID Verified NFT
    require(WorldIDVerifiedNFT(address(worldIdNFT)).balanceOf(user) > 0, "Sender is not World ID verified");

     // Store the user address for this swap
     lastSwapUser[key.toId()] = user;

    return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
  }

  function afterSwap(
    address,
    PoolKey calldata key,
    IPoolManager.SwapParams calldata swapParams,
    BalanceDelta delta,
    bytes calldata hookData
  ) external override returns (bytes4, int128) {
    
    afterSwapCount[key.toId()]++;

    uint256 amountToTransfer = uint256(uint128(delta.amount1()));

    poolManager.take(key.currency1, address(this), uint128(delta.amount1()));

    CrossChainTransferData memory transferData = abi.decode(hookData, (CrossChainTransferData));

    // Retrieve the user (recipient) for this swap
    address recipient = lastSwapUser[key.toId()];
    delete lastSwapUser[key.toId()]; // Clean up storage

    // Lock the tokens for cross-chain transfer
    lockedTokens[recipient] += amountToTransfer;

    // Initiate cross-chain transfer
    uint32 dstEid = 2; // Replace with the actual destination chain ID
    bytes32 to = bytes32(uint256(uint160(recipient)));

    SendParam memory sendParam = SendParam({
      dstEid: dstEid,
      to: to,
      amountLD: amountToTransfer,
      minAmountLD: amountToTransfer,
      extraOptions: "",
      composeMsg: "",
      oftCmd: ""
  });

  MessagingFee memory messagingFee = MessagingFee({
    nativeFee: transferData.crossChainFee,
    lzTokenFee: 0
});

(MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) = this.send{value: transferData.crossChainFee}(sendParam, messagingFee, recipient);

emit CrossChainTransferInitiated(recipient, amountToTransfer, transferData.dstEid);
    
    return (BaseHook.afterSwap.selector, delta.amount1());
  }

  // Override OFT's _debit function to handle the tokens taken from the pool
  function _debit(uint256 _amountLD, uint256 _minAmountLD, uint32 _dstEid) internal virtual override returns (uint256 amountSentLD, uint256 amountReceivedLD) {
    require(lockedTokens[msg.sender] >= _amountLD, "Insufficient locked tokens");

    (amountSentLD, amountReceivedLD) = _debitView(_amountLD, _minAmountLD, _dstEid);

    // Reduce the locked tokens
    lockedTokens[msg.sender] -= amountSentLD;

    emit DebitCalled(msg.sender, amountSentLD);
    emit TokensLockedForCrossChainTransfer(msg.sender, amountSentLD);

    return (amountSentLD, amountReceivedLD);
}

function _credit(address _to, uint256 _amount, uint32 _srcEid) internal virtual override returns (uint256) {
    emit CreditCalled(_to, _amount);
    return super._credit(_to, _amount, _srcEid);
}

function _lzReceive(
    Origin calldata _origin,
    bytes32 _guid,
    bytes calldata _message,
    address _executor,
    bytes calldata _extraData
) internal virtual override {
    emit LzReceiveCalled(_origin.srcEid, _message);
    super._lzReceive(_origin, _guid, _message, _executor, _extraData);
}

receive() external payable {}

event LzReceiveCalled(uint32 srcEid, bytes message);
}
