"use client";

import { useEffect, useState } from "react";
import { useDynamicContext } from "@dynamic-labs/sdk-react-core";
import { IDKitWidget, ISuccessResult, VerificationLevel } from "@worldcoin/idkit";
import { BaseError, decodeAbiParameters, parseAbiParameters } from "viem";
import { useWaitForTransactionReceipt } from "wagmi";
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth";

const VerifyOnChain = ({ onSuccess }: { onSuccess: () => void }) => {
  const { primaryWallet } = useDynamicContext();
  const connectedAddress = primaryWallet?.address as `0x${string}` | undefined;

  const [done, setDone] = useState(false);

  const { data: hash, isPending, error, writeContractAsync, isMining } = useScaffoldWriteContract("WorldcoinVerifier");
  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  useEffect(() => {
    console.log("Connected Address: ", connectedAddress);
  }, [connectedAddress]);

  const submitTx = async (proof: ISuccessResult) => {
    if (!connectedAddress) {
      console.error("No connected address");
      return;
    }

    const address = connectedAddress.startsWith("0x")
      ? (connectedAddress as `0x${string}`)
      : (`0x${connectedAddress}` as `0x${string}`);

    console.log("Signal (address) being passed:", address);

    try {
      console.log("Submitting transaction with proof:", proof);
      const formattedProof = decodeAbiParameters(parseAbiParameters("uint256[8]"), proof.proof as `0x${string}`)[0];
      console.log("Formatted Proof:", formattedProof);

      await writeContractAsync({
        functionName: "verifyAndExecute",
        args: [address, BigInt(proof.merkle_root), BigInt(proof.nullifier_hash), formattedProof],
      });
      setDone(true); // Set done state to true if the transaction is sent successfully
      if (onSuccess && typeof onSuccess === "function") {
        onSuccess(); // Call onSuccess prop when verification is successful
      }
      console.log("Transaction submitted successfully");
    } catch (error) {
      console.error("Transaction submission error:", error);
      console.error("Transaction submission error message:", (error as BaseError).shortMessage);
    }
  };

  return (
    <div>
      {connectedAddress ? (
        <>
          <IDKitWidget
            app_id="app_staging_911f3b232bfb4259958b766f6a2baffd" // must be an app set to on-chain in Developer Portal
            action="verifyswap"
            signal={connectedAddress} // proof will only verify if the signal is unchanged, preventing tampering
            onSuccess={submitTx} // use onSuccess to call your smart contract
            verification_level={VerificationLevel.Orb} // use default verification_level, as device credentials are not supported on-chain
            onError={error => {
              console.error("IDKitWidget error:", error);
            }}
          >
            {({ open }: { open: () => void }) => (
              <button onClick={open} disabled={isMining || isPending}>
                {isMining ? "Mining..." : isPending ? "Pending, please check your wallet..." : "Verify with World ID"}
              </button>
            )}
          </IDKitWidget>

          {hash && <p>Transaction Hash: {hash}</p>}
          {isConfirming && <p>Waiting for confirmation...</p>}
          {isConfirmed && done && <p>Transaction confirmed.</p>}
          {error && <p>Error: {(error as BaseError).message}</p>}
        </>
      ) : (
        <p>Please connect your wallet</p>
      )}
    </div>
  );
};

export default VerifyOnChain;
