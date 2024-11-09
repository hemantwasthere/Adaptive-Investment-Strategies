import React from "react";

const Holdings = () => {
  return (
    <div className="mt-4 flex items-center justify-between rounded-md bg-primary p-3">
      <div className="flex flex-col items-center gap-1">
        <p className="text-sm font-medium text-muted-foreground">
          Your Holdings
        </p>
        <span className="text-sm font-semibold text-white">
          2348.3 <span className="font-medium">rbETH</span>
        </span>
      </div>

      <div className="flex flex-col items-center gap-1">
        <p className="text-sm font-medium text-muted-foreground">TVL (Dex)</p>
        <span className="text-sm font-semibold text-white">12.05M</span>
      </div>

      <div className="flex flex-col items-center gap-1">
        <p className="text-sm font-medium text-muted-foreground">
          TVL (Lending)
        </p>
        <span className="text-sm font-semibold text-white">12.05M</span>
      </div>
    </div>
  );
};

export default Holdings;
