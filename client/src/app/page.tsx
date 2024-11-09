import MaxWidthWrapper from "@/components/max-width-wrapper";
import Model from "@/components/model";
import Navbar from "@/components/navbar";
import Stats from "@/components/stats";
import Tabs from "@/components/tabs";

export default function Home() {
  return (
    <div className="overflow-y-auto bg-primary selection:bg-blue-700 selection:text-white/90 lg:overflow-hidden">
      <Navbar />

      {/* <Model /> */}

      <MaxWidthWrapper>
        <main className="mx-auto flex max-w-[70rem] items-center justify-center py-3 lg:h-[calc(100vh-81px)] lg:py-0">
          <div className="grid-cols-5 gap-4 lg:grid lg:h-[20rem]">
            <Stats />
            <Tabs />
          </div>
        </main>
      </MaxWidthWrapper>
    </div>
  );
}
