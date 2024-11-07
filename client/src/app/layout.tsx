import type { Metadata } from "next";
import { Figtree } from "next/font/google";

import Providers from "@/components/providers";
import { Toaster } from "@/components/ui/toaster";
import { cn } from "@/lib/utils";

import "./globals.css";

const figTree = Figtree({ subsets: ["latin-ext"] });

export const metadata: Metadata = {
  title: "Adaptive Investment Strategies",
  description: "Adaptive Investment Strategies",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={cn(figTree.className, "bg-primary antialiased")}>
        <Providers>
          {children}
          <Toaster />
        </Providers>
      </body>
    </html>
  );
}
