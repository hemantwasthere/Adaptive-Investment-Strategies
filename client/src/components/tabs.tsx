import React from "react";

import Deposit from "@/components/deposit";
import {
  Tabs as ShadCNTabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from "@/components/ui/tabs";
import Withdraw from "@/components/withdraw";

const Tabs = () => {
  return (
    <ShadCNTabs
      defaultValue="deposit"
      className="col-span-2 mt-4 h-full w-full lg:mt-0"
    >
      <TabsList className="mb-2 w-full border border-accent/10 bg-transparent">
        <TabsTrigger
          value="deposit"
          className="w-full data-[state=active]:bg-accent/20 data-[state=active]:text-white/80"
        >
          Deposit
        </TabsTrigger>
        <TabsTrigger
          value="withdraw"
          className="w-full data-[state=active]:bg-accent/20 data-[state=active]:text-white/80"
        >
          Withdraw
        </TabsTrigger>
      </TabsList>

      <TabsContent
        value="deposit"
        className="h-[calc(19rem-36px)] w-full rounded-md border border-accent/10 bg-black/40 px-4 py-3 text-white"
      >
        <Deposit />
      </TabsContent>

      <TabsContent
        value="withdraw"
        className="h-[calc(19rem-36px)] w-full rounded-md border border-accent/10 bg-black/40 px-4 py-3 text-white"
      >
        <Withdraw />
      </TabsContent>
    </ShadCNTabs>
  );
};

export default Tabs;
