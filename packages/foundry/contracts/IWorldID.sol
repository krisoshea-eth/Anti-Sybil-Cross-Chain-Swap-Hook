// contracts/interfaces/IWorldID.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWorldID {
    /// @notice Verifies a zero-knowledge proof that demonstrates the claimer is registered with World ID.
    /// @param root The root to verify against.
    /// @param groupId The group ID to verify against.
    /// @param signalHash The hash of the signal to verify.
    /// @param nullifierHash The nullifier hash for this proof, preventing double signaling.
    /// @param externalNullifierHash The hash of the external nullifier, which identifies the app and action the user is verifying for.
    /// @param proof The zero-knowledge proof to verify.
    function verifyProof(
        uint256 root,
        uint256 groupId,
        uint256 signalHash,
        uint256 nullifierHash,
        uint256 externalNullifierHash,
        uint256[8] calldata proof
    ) external view;
}