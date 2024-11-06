"use client";

import {
  useAccount,
  useConnect,
  useDisconnect,
  useStarkProfile,
} from "@starknet-react/core";
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
import { cn, shortAddress, truncate } from "@/lib/utils";
import MaxWidthWrapper from "./max-width-wrapper";

const Navbar: React.FC = () => {
  const { address } = useAccount();
  const { connect, connectors } = useConnect();
  const { disconnectAsync } = useDisconnect();

  const { data: starkProfile } = useStarkProfile({
    address,
    useDefaultPfp: true,
  });

  console.log(starkProfile);

  return (
    <header className="sticky top-0 z-30 bg-black">
      <MaxWidthWrapper className="flex h-20 items-center justify-between">
        <p className="text-base text-white hover:underline">
          Adaptive Investment Strategies
        </p>

        <DropdownMenu>
          <DropdownMenuTrigger className="text-white rounded-md focus-visible:ring-0 transition-all focus-visible:outline-0 select-none group">
            {address ? (
              <div className="flex items-center gap-2 group-focus-visible:outline-1 group-focus-visible:outline-white">
                <Image
                  src={starkProfile?.profilePicture || "/fallback-avatar.svg"}
                  className="rounded-full shrink-0"
                  width={20}
                  height={20}
                  alt="pfp"
                />
                <p className="flex items-center gap-1">
                  {starkProfile && starkProfile.name
                    ? truncate(starkProfile.name, 6, 6)
                    : shortAddress(address, 4, 4)}{" "}
                  <ChevronDown className="size-3" />
                </p>
              </div>
            ) : (
              <p
                className={cn(
                  "flex items-center gap-1 select-none",
                  buttonVariants()
                )}
              >
                Connect Wallet <ChevronDown className="size-3" />
              </p>
            )}
          </DropdownMenuTrigger>
          <DropdownMenuContent className="border border-accent/10 bg-primary/90 min-w-[9rem] text-white">
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
