"use client";

import React, { useState } from "react";
import { ChevronDownIcon } from "lucide-react";

const SwapInterface = () => {
  const [fromChain, setFromChain] = useState("Ethereum");
  const [toChain, setToChain] = useState("Binance Smart Chain");
  const [fromAsset, setFromAsset] = useState("USDT");
  const [toAsset, setToAsset] = useState("BUSD");

  const chains = ["Ethereum", "Binance Smart Chain", "Polygon", "Avalanche"];
  const assets = {
    Ethereum: ["ETH", "USDT", "USDC", "DAI"],
    "Binance Smart Chain": ["BNB", "BUSD", "CAKE", "XVS"],
    Polygon: ["MATIC", "USDT", "USDC", "QUICK"],
    Avalanche: ["AVAX", "USDT", "USDC", "JOE"],
  };

  return (
    <div className="flex items-center justify-center min-h-screen bg-gray-100">
      <div className="max-w p-6 bg-white rounded-lg border border-gray-200 shadow-md">
        <div className="flex flex-col gap-4">
          {/* Swap From */}
          <div>
            <label htmlFor="from" className="text-sm font-medium text-gray-600">
              Swap From
            </label>
            <div className="flex items-center gap-2 mt-1">
              <input
                id="from"
                className="flex-grow h-10 rounded-md border px-3 py-2 text-sm bg-gray-50 border-gray-300 focus:border-purple-500 focus:ring-purple-500"
                placeholder="0.0"
              />
              <div className="flex gap-1 flex-shrink-0">
                <select
                  value={fromChain}
                  onChange={e => setFromChain(e.target.value)}
                  className="h-10 px-2 rounded-md bg-gray-50 border border-gray-300 text-gray-700 hover:bg-gray-100"
                >
                  {chains.map(chain => (
                    <option key={chain} value={chain}>
                      {chain}
                    </option>
                  ))}
                </select>
                <select
                  value={fromAsset}
                  onChange={e => setFromAsset(e.target.value)}
                  className="h-10 px-2 rounded-md bg-gray-50 border border-gray-300 text-gray-700 hover:bg-gray-100"
                >
                  {assets[fromChain].map(asset => (
                    <option key={asset} value={asset}>
                      {asset}
                    </option>
                  ))}
                </select>
              </div>
            </div>
          </div>

          {/* Swap Arrow */}
          <div className="flex justify-center">
            <button className="p-2 rounded-full bg-gray-100 text-gray-600 hover:bg-gray-200">
              <ChevronDownIcon className="w-5 h-5" />
            </button>
          </div>

          {/* Swap To */}
          <div>
            <label htmlFor="to" className="text-sm font-medium text-gray-600">
              Swap To
            </label>
            <div className="flex items-center gap-2 mt-1">
              <input
                id="to"
                className="flex-grow h-10 rounded-md border px-3 py-2 text-sm bg-gray-50 border-gray-300 focus:border-purple-500 focus:ring-purple-500"
                placeholder="0.0"
              />
              <div className="flex gap-1 flex-shrink-0">
                <select
                  value={toChain}
                  onChange={e => setToChain(e.target.value)}
                  className="h-10 px-2 rounded-md bg-gray-50 border border-gray-300 text-gray-700 hover:bg-gray-100"
                >
                  {chains.map(chain => (
                    <option key={chain} value={chain}>
                      {chain}
                    </option>
                  ))}
                </select>
                <select
                  value={toAsset}
                  onChange={e => setToAsset(e.target.value)}
                  className="h-10 px-2 rounded-md bg-gray-50 border border-gray-300 text-gray-700 hover:bg-gray-100"
                >
                  {assets[toChain].map(asset => (
                    <option key={asset} value={asset}>
                      {asset}
                    </option>
                  ))}
                </select>
              </div>
            </div>
          </div>

          {/* Swap Button */}
          <button className="h-11 rounded-md px-8 w-full bg-purple-600 text-white hover:bg-purple-700 transition-colors">
            Swap
          </button>

          {/* Exchange Info */}
          <div className="text-sm text-gray-600">
            <div className="flex justify-between">
              <span>Exchange Rate</span>
              <span>
                1 {fromAsset} ≈ 50 {toAsset}
              </span>
            </div>
            <div className="flex justify-between">
              <span>Estimated Output</span>
              <span>50 {toAsset}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SwapInterface;
