// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../contracts/WorldcoinVerifier.sol";
import "../contracts/WorldIDVerifiedNFT.sol";

contract MockWorldID is IWorldID {
    bool private shouldFail;

    function setShouldFail(bool _shouldFail) public {
        shouldFail = _shouldFail;
    }

    function verifyProof(
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256[8] calldata
    ) external view override {
        if (shouldFail) {
            revert("Proof verification failed");
        }
        // This mock succeeds if shouldFail is false
    }
}


contract WorldcoinVerifierTest is Test {
    WorldcoinVerifier public verifier;
    WorldIDVerifiedNFT public nft;
    MockWorldID public mockWorldID;

    address public constant USER = address(0x1234);
    string public constant APP_ID = "app_testing_123";
    string public constant ACTION = "test_action";

    function setUp() public {
        mockWorldID = new MockWorldID();
        nft = new WorldIDVerifiedNFT();
        verifier = new WorldcoinVerifier(
            IWorldID(address(mockWorldID)),
            APP_ID,
            ACTION,
            nft
        );

        // Transfer ownership of NFT contract to the verifier
        nft.transferOwnership(address(verifier));
    }

    function testVerifyAndExecute() public {
        uint256 root = 123;
        uint256 nullifierHash = 456;
        uint256[8] memory proof;

        // Verify that the user doesn't have an NFT before verification
        assertEq(nft.balanceOf(USER), 0);

        // Call verifyAndExecute
        verifier.verifyAndExecute(USER, root, nullifierHash, proof);

        // Check that the user received an NFT
        assertEq(nft.balanceOf(USER), 1);

        // Try to verify again with the same nullifier hash (should revert)
        vm.expectRevert(abi.encodeWithSignature("InvalidNullifier()"));
        verifier.verifyAndExecute(USER, root, nullifierHash, proof);
    }

    function testCannotTransferNFT() public {
        uint256 root = 123;
        uint256 nullifierHash = 456;
        uint256[8] memory proof;

        // Verify and mint NFT
        verifier.verifyAndExecute(USER, root, nullifierHash, proof);

        // Try to transfer the NFT (should revert)
        uint256 tokenId = 0; // Assuming it's the first token minted
        vm.prank(USER);
        vm.expectRevert("This NFT is non-transferrable");
        nft.transferFrom(USER, address(this), tokenId);
    }

    function testCannotApprove() public {
        uint256 root = 123;
        uint256 nullifierHash = 456;
        uint256[8] memory proof;

        // Verify and mint NFT
        verifier.verifyAndExecute(USER, root, nullifierHash, proof);

        // Try to approve (should revert)
        uint256 tokenId = 0; // Assuming it's the first token minted
        vm.prank(USER);
        vm.expectRevert("Approvals are not allowed for this NFT");
        nft.approve(address(this), tokenId);
    }

    function testCannotSetApprovalForAll() public {
        uint256 root = 123;
        uint256 nullifierHash = 456;
        uint256[8] memory proof;

        // Verify and mint NFT
        verifier.verifyAndExecute(USER, root, nullifierHash, proof);

        // Try to set approval for all (should revert)
        vm.prank(USER);
        vm.expectRevert("Approvals are not allowed for this NFT");
        nft.setApprovalForAll(address(this), true);
    }

    function testVerifyProofFailure() public {
        uint256 root = 123;
        uint256 invalidNullifierHash = 789;
        uint256[8] memory proof;

        // Set MockWorldID to fail verification
        mockWorldID.setShouldFail(true);

        // Expect the verification to fail
        vm.expectRevert("Proof verification failed");
        verifier.verifyAndExecute(USER, root, invalidNullifierHash, proof);

        // Check that no NFT was minted
        assertEq(nft.balanceOf(USER), 0);

        // Reset MockWorldID to succeed for other tests
        mockWorldID.setShouldFail(false);
    }

    function testInvalidSignal() public {
        uint256 root = 123;
        uint256 nullifierHash = 456;
        uint256[8] memory proof;

        // Try to verify with address(0) as signal
        vm.expectRevert("Invalid signal");
        verifier.verifyAndExecute(address(0), root, nullifierHash, proof);
    }
}