import MaxWidthWrapper from "@/components/max-width-wrapper";
import Navbar from "@/components/navbar";
import Stats from "@/components/stats";
import Tabs from "@/components/tabs";

export default function Home() {
  return (
    <div className="overflow-y-auto bg-primary selection:bg-blue-700 selection:text-white/90 lg:overflow-hidden">
      <Navbar />

      <MaxWidthWrapper>
        <main className="mx-auto flex h-[calc(100vh-81px)] max-w-[70rem] items-center justify-center">
          <div className="grid-cols-5 gap-4 lg:grid lg:h-[20rem]">
            <Stats />
            <Tabs />
          </div>
        </main>
      </MaxWidthWrapper>
    </div>
  );
}
