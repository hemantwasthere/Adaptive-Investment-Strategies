import Deposit from "@/components/deposit";
import Navbar from "@/components/navbar";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import Withdraw from "@/components/withdraw";

export default function Home() {
  return (
    <div>
      <Navbar />

      <main className="h-[calc(100vh-80px)] bg-primary flex items-center justify-center">
        <Tabs defaultValue="deposit" className="w-full max-w-xl">
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
            className="w-full bg-black rounded-md text-white py-3 px-3"
          >
            <Deposit />
          </TabsContent>

          <TabsContent
            value="withdraw"
            className="w-full bg-black rounded-md text-white py-2 px-3"
          >
            <Withdraw />
          </TabsContent>
        </Tabs>
      </main>
    </div>
  );
}
