import React from "react";

const Holdings = () => {
  return (
    <div className="bg-primary rounded-md p-3 flex items-center justify-between mt-4">
      <div className="flex flex-col gap-1">
        <p className="text-muted-foreground text-sm font-medium">
          Your Holdings
        </p>
        <span className="text-sm text-white font-semibold">2518.77 STRK</span>
      </div>

      <div className="flex flex-col gap-1">
        <p className="text-muted-foreground text-sm font-medium">Net Earning</p>
        <span className="text-sm text-white font-semibold">12.05 STRK</span>
      </div>
    </div>
  );
};

export default Holdings;
