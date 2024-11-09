import React from "react";

import Holdings from "./holdings";

const Stats = () => {
  return (
    <div className="col-span-3 flex h-full flex-col justify-between rounded-md border border-accent/10 bg-black/40 px-5 py-4">
      <div>
        <h4 className="mb-2 text-3xl text-white/90">How does it work?</h4>
        <p className="text-muted-foreground">
          The project is an experimental initiative to test automated token
          rebalancing between lending pools and decentralized exchanges (DEXs),
          aiming to maximize user profit while mitigating impermanent loss.
          Specifically, during periods of heightened market volatility,
          increased trading activity on DEXs can lead to higher yields ( higher
          swap fees) . The solution aims to dynamically reallocates assets
          toward DEXs to capture these enhanced returns, leveraging fluctuations
          in trading activity to optimize returns.
        </p>
      </div>
      <Holdings />
    </div>
  );
};

export default Stats;
