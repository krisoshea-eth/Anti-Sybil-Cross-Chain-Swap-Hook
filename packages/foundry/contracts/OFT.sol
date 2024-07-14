// SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.22;

// import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
// import { OFT } from "lib/LayerZero-v2/packages/layerzero-v2/evm/oapp/contracts/oft/OFT.sol";

// contract MyOFT is OFT {
//     constructor(
//         string memory _name,
//         string memory _symbol,
//         address _lzEndpoint,
//         address _delegate
//     ) OFT(_name, _symbol, _lzEndpoint, _delegate) Ownable(_delegate) {}

//     function send(
//         SendParam calldata _sendParam,
//         MessagingFee calldata _fee,
//         address _refundAddress
//     ) external payable virtual returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) {
//         // @dev Applies the token transfers regarding this send() operation.
//         // - amountSentLD is the amount in local decimals that was ACTUALLY sent/debited from the sender.
//         // - amountReceivedLD is the amount in local decimals that will be received/credited to the recipient on the remote OFT instance.
//         (uint256 amountSentLD, uint256 amountReceivedLD) = _debit(
//             _sendParam.amountLD,
//             _sendParam.minAmountLD,
//             _sendParam.dstEid
//         );
    
//         // ...
//     }
// }