"use client";

import React, { useEffect, useState } from "react";
import { SpinnerIcon, useDynamicContext } from "@dynamic-labs/sdk-react-core";
import { CheckCircleIcon, ExclamationCircleIcon } from "@heroicons/react/24/outline";
import VerifyOnChain from "~~/app/worldcoin-onchain/verify";
import { useScaffoldReadContract } from "~~/hooks/scaffold-eth";

const KYCCheck = () => {
  const { primaryWallet } = useDynamicContext();
  const connectedAddress = primaryWallet?.address as `0x${string}` | undefined;
  const [isPopoverOpen, setIsPopoverOpen] = useState(false);
  const [isVerified, setIsVerified] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [isError, setIsError] = useState(false);
  const [isVerifying, setIsVerifying] = useState(false);

  const args: readonly [`0x${string}` | undefined] = [connectedAddress];

  const { data: tokenBalance, error } = useScaffoldReadContract({
    contractName: "WorldIDVerifiedNFT",
    functionName: "balanceOf",
    args,
  });

  useEffect(() => {
    if (error) {
      setIsError(true);
      setIsLoading(false);
    } else if (tokenBalance !== undefined) {
      setIsVerified(tokenBalance > 0);
      setIsLoading(false);
    }
  }, [tokenBalance, error]);

  const handleVerificationSuccess = () => {
    setIsVerified(true);
    setIsVerifying(false);
    setIsPopoverOpen(false);
  };

  const startVerification = () => {
    setIsVerifying(true);
  };

  return (
    <div className="relative">
      <button
        onClick={() => setIsPopoverOpen(!isPopoverOpen)}
        className="flex items-center gap-2 px-2 py-1 border text-xs rounded-full hover:bg-secondary"
      >
        {isLoading ? (
          <SpinnerIcon className="h-5 w-5 text-gray-500 animate-spin" />
        ) : isVerified ? (
          <CheckCircleIcon className="h-5 w-5 text-green-500" />
        ) : (
          <ExclamationCircleIcon className="h-5 w-5 text-red-500" />
        )}
        <span>KYC Status</span>
      </button>
      {isPopoverOpen && (
        <div className="absolute right-0 mt-2 w-64 p-4 bg-white border shadow-lg rounded-lg text-black">
          <h3 className="text-lg font-semibold mb-2">KYC Verification</h3>
          <p className="mb-4">Current Status: {isLoading ? "Loading..." : isVerified ? "Verified" : "Not Verified"}</p>
          {!isVerified && !isLoading && !isError && (
            <div>
              {!isVerifying ? (
                <button
                  onClick={startVerification}
                  className="w-full py-2 px-4 bg-blue-500 text-white rounded hover:bg-blue-600 transition duration-300"
                >
                  Verify with World ID
                </button>
              ) : (
                <VerifyOnChain onSuccess={handleVerificationSuccess} />
              )}
            </div>
          )}
          {isError && <p className="text-red-500">Error loading KYC status. Please try again.</p>}
        </div>
      )}
    </div>
  );
};

export default KYCCheck;
