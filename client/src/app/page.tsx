import MaxWidthWrapper from "@/components/max-width-wrapper";
import Navbar from "@/components/navbar";
import Stats from "@/components/stats";
import Tabs from "@/components/tabs";

export default function Home() {
  return (
    <div className="bg-primary overflow-y-auto">
      <Navbar />

      <MaxWidthWrapper>
        <main className="h-[calc(100vh-80px)] flex items-center justify-center max-w-[70rem] mx-auto">
          <div className="lg:grid grid-cols-5 gap-4 lg:h-[20rem]">
            <Stats />
            <Tabs />
          </div>
        </main>
      </MaxWidthWrapper>
    </div>
  );
}
