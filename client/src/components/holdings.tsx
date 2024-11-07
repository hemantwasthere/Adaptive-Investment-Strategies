import React from "react";

const Holdings = () => {
  return (
    <div className="mt-4 flex items-center justify-between rounded-md bg-primary p-3">
      <div className="flex flex-col gap-1">
        <p className="text-sm font-medium text-muted-foreground">
          Your Holdings
        </p>
        <span className="text-sm font-semibold text-white">2518.77 STRK</span>
      </div>

      <div className="flex flex-col gap-1">
        <p className="text-sm font-medium text-muted-foreground">Net Earning</p>
        <span className="text-sm font-semibold text-white">12.05 STRK</span>
      </div>
    </div>
  );
};

export default Holdings;
