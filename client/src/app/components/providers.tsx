"use client";

import { mainnet } from "@starknet-react/chains";
import {
  argent,
  braavos,
  jsonRpcProvider,
  StarknetConfig,
  useInjectedConnectors,
} from "@starknet-react/core";
import React from "react";
import { constants, RpcProviderOptions } from "starknet";

interface ProvidersProps {
  children: React.ReactNode;
}

const chains = [mainnet];

const provider = jsonRpcProvider({
  rpc: () => {
    const args: RpcProviderOptions = {
      nodeUrl:
        "https://rpc.nethermind.io/mainnet-juno?apikey=t1HPjhplOyEQpxqVMhpwLGuwmOlbXN0XivWUiPAxIBs0kHVK",
      chainId: constants.StarknetChainId.SN_MAIN,
    };
    return args;
  },
});

const Providers: React.FC<ProvidersProps> = ({ children }) => {
  const { connectors } = useInjectedConnectors({
    recommended: [argent(), braavos()],
    includeRecommended: "onlyIfNoConnectors",
    order: "random",
  });

  if (typeof window === "undefined") return null;

  return (
    <StarknetConfig chains={chains} provider={provider} connectors={connectors}>
      {children}
    </StarknetConfig>
  );
};

export default Providers;
