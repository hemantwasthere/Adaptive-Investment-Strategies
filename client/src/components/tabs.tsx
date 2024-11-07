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
      className="col-span-2 w-full h-full mt-4 lg:mt-0"
    >
      <TabsList className="w-full mb-2 border border-accent/10 bg-transparent">
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
        className="w-full h-[calc(19rem-36px)] bg-black/40 rounded-md text-white py-3 px-4"
      >
        <Deposit />
      </TabsContent>

      <TabsContent
        value="withdraw"
        className="w-full h-[calc(19rem-36px)] bg-black/40 rounded-md text-white py-2 px-4"
      >
        <Withdraw />
      </TabsContent>
    </ShadCNTabs>
  );
};

export default Tabs;
