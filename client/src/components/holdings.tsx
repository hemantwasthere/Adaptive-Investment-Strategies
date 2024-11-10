"use client";

import { useAccount, useReadContract } from "@starknet-react/core";
import React from "react";

import autoVaultAbi from "@/abi/auto-vault.abi.json";
import erc20Abi from "@/abi/erc20.abi.json";
import { userStore } from "@/store/user-store";

const Holdings = () => {
  const { address } = useAccount();
  const { lendingData, dexData } = userStore();

  const { data: lending_data, refetch: refetch_lending } = useReadContract({
    abi: autoVaultAbi,
    functionName: "total_assets",
    address:
      "0x142cdbe00acf31e7a0668aa805ef9594c1c28085201e54ee0b9bb3f624735a9",
    args: [],
  });

  const { data: my_holdings, refetch: refetch_holdings } = useReadContract({
    abi: erc20Abi,
    functionName: "balance_of",
    address:
      "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7",
    args: [address],
  });

  setTimeout(() => {
    refetch_holdings();
    refetch_lending();
    refetch_dex();
  }, 5000);

  const { data: dex_data, refetch: refetch_dex } = useReadContract({
    abi: autoVaultAbi,
    functionName: "dex_assets",
    address:
      "0x142cdbe00acf31e7a0668aa805ef9594c1c28085201e54ee0b9bb3f624735a9",
    args: [],
  });

  console.log(lending_data, "lending data");
  console.log(my_holdings, "my holdings");
  console.log(dex_data, "dex_data");

  return (
    <div className="mt-4 flex items-center justify-between rounded-md bg-primary p-3">
      <div className="flex flex-col items-center gap-1">
        <p className="text-sm font-medium text-muted-foreground">
          Your Holdings
        </p>
        <span className="text-sm font-semibold text-white">
          {my_holdings ? (Number(my_holdings) / 10 ** 18).toFixed(2) : 0}{" "}
          <span className="font-medium">rbETH</span>
        </span>
      </div>

      <div className="flex flex-col items-center gap-1">
        <p className="text-sm font-medium text-muted-foreground">TVL (Dex)</p>
        <span className="text-sm font-semibold text-white">
          {dexData ? dexData : 0}
        </span>
      </div>

      <div className="flex flex-col items-center gap-1">
        <p className="text-sm font-medium text-muted-foreground">
          TVL (Lending)
        </p>
        <span className="text-sm font-semibold text-white">
          {lendingData ? lendingData : 0}
        </span>
      </div>
    </div>
  );
};

export default Holdings;
