"use client";

import {
  useAccount,
  useConnect,
  useDisconnect,
  useStarkProfile,
} from "@starknet-react/core";
import { motion } from "framer-motion";
import { ChevronDown } from "lucide-react";
import Image from "next/image";
import React from "react";

import { buttonVariants } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Skeleton } from "@/components/ui/skeleton";
import { cn, shortAddress, truncate } from "@/lib/utils";

import MaxWidthWrapper from "./max-width-wrapper";

const Navbar: React.FC = () => {
  const { address, isConnecting } = useAccount();
  const { connect, connectors } = useConnect();
  const { disconnectAsync } = useDisconnect();

  const { data: starkProfile } = useStarkProfile({
    address,
    useDefaultPfp: true,
  });

  const rocketAnimation = {
    initial: { x: 0, y: 0 },
    animate: { x: [-5, 5, -5], y: [5, -5, 5] },
    transition: { duration: 3, repeat: Infinity, ease: "easeInOut" },
  };

  return (
    <header className="sticky top-0 z-30 border-b border-accent/10 bg-black/40">
      <MaxWidthWrapper className="flex h-20 items-center justify-between">
        <div className="flex items-center text-base text-white">
          <p>Adaptive Investment Strategies </p>
          <motion.img
            src="/rocket.png"
            className="ml-3 select-none"
            width={20}
            height={20}
            alt="rocket"
            {...rocketAnimation}
          />
        </div>

        <DropdownMenu>
          <DropdownMenuTrigger className="group select-none rounded-md text-white transition-all focus-visible:outline-0 focus-visible:ring-0">
            {!address && isConnecting && (
              <div className="flex h-9 w-[9.5rem] items-center justify-center gap-2 rounded-md border border-accent/10 group-focus-visible:outline-1 group-focus-visible:outline-white">
                <Image
                  src={starkProfile?.profilePicture || "/fallback-avatar.svg"}
                  className="shrink-0 rounded-full"
                  width={20}
                  height={20}
                  alt="skeleton-pfp"
                />
                <p className="flex items-center gap-1 text-sm">
                  <Skeleton className="h-5 w-full" />
                  <ChevronDown className="size-3" />
                </p>
              </div>
            )}

            {address && !isConnecting && (
              <div className="flex h-9 w-[9.5rem] items-center justify-center gap-2 rounded-md border border-accent/10 group-focus-visible:outline-1 group-focus-visible:outline-white">
                <Image
                  src={starkProfile?.profilePicture || "/fallback-avatar.svg"}
                  className="shrink-0 rounded-full"
                  width={20}
                  height={20}
                  alt="strkprofile-pfp"
                />
                <p className="flex items-center gap-1 text-sm">
                  {starkProfile && starkProfile.name
                    ? truncate(starkProfile.name, 6, 6)
                    : shortAddress(address, 4, 4)}
                  <ChevronDown className="size-3" />
                </p>
              </div>
            )}

            {!address && !isConnecting && (
              <p
                className={cn(
                  buttonVariants(),
                  "flex w-[9.5rem] select-none items-center justify-center gap-1 text-sm",
                )}
              >
                Connect Wallet <ChevronDown className="!size-3" />
              </p>
            )}
          </DropdownMenuTrigger>
          <DropdownMenuContent className="min-w-[9rem] border border-accent/10 bg-primary/90 text-white">
            {!address ? (
              connectors?.map((connector) => (
                <DropdownMenuItem
                  key={connector.id}
                  className="hover:!bg-accent/10 hover:!text-white"
                  onClick={() => {
                    connect({ connector });
                  }}
                >
                  <Image
                    src={connector.icon as string}
                    width={15}
                    height={15}
                    alt="icon"
                  />
                  <p>{connector.name}</p>
                </DropdownMenuItem>
              ))
            ) : (
              <DropdownMenuItem
                onClick={() => disconnectAsync()}
                className="hover:!bg-accent/10 hover:!text-white"
              >
                Disconnect
              </DropdownMenuItem>
            )}
          </DropdownMenuContent>
        </DropdownMenu>
      </MaxWidthWrapper>
    </header>
  );
};

export default Navbar;
