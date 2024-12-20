"use client";

import { useAccount, useConnect, useDisconnect } from "@starknet-react/core";
import axios from "axios";
import { motion } from "framer-motion";
import { Check, ChevronDown, CircleCheck, Copy } from "lucide-react";
import Image from "next/image";
import React from "react";

import { Button, buttonVariants } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import { cn, shortAddress } from "@/lib/utils";

import { toast } from "@/hooks/use-toast";
import { userStore } from "@/store/user-store";
import MaxWidthWrapper from "./max-width-wrapper";

const rocketAnimation = {
  initial: { x: 0, y: 0 },
  animate: { x: [-5, 5, -5], y: [5, -5, 5] },
  transition: { duration: 3, repeat: Infinity, ease: "easeInOut" },
};

const Navbar: React.FC = () => {
  const [showTick, setShowTick] = React.useState(false);

  const { setAddress, lastWallet, setLastWallet } = userStore();

  const { address, isConnecting, connector } = useAccount();
  const { connect, connectors } = useConnect();
  const { disconnectAsync } = useDisconnect();

  function autoConnect(retry = 0) {
    try {
      if (!address && lastWallet) {
        const connectorIndex = ["Braavos", "Argent X"].findIndex(
          (name) => name === lastWallet,
        );
        if (connectorIndex >= 0) {
          connect({ connector: connectors[connectorIndex] });
        }
      }
    } catch (error) {
      if (retry < 10) {
        setTimeout(() => {
          autoConnect(retry + 1);
        }, 1000);
      }
    }
  }

  React.useEffect(() => {
    (async () => {
      if (!address) return;

      setAddress(address);

      let bodyContent = JSON.stringify({
        address: address,
        amount: 10000000000000000000000,
        unit: "WEI",
      });

      let reqOptions = {
        url: "http://127.0.0.1:5050/mint",
        method: "POST",
        headers: {
          Accept: "*/*",
          "Content-Type": "application/json",
        },
        data: bodyContent,
      };

      let response = await axios.request(reqOptions);

      console.log(response);
    })();
  }, [address]);

  React.useEffect(() => {
    if (connector) {
      setLastWallet(connector.name);
    }
  }, [connector]);

  React.useEffect(() => {
    autoConnect();
  }, [lastWallet]);

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

        <div className="flex items-center gap-2">
          <DropdownMenu>
            <DropdownMenuTrigger className="group select-none rounded-md text-white transition-all focus-visible:outline-0 focus-visible:ring-0">
              {!address && isConnecting && (
                <div className="flex h-9 w-[9.5rem] items-center justify-center gap-2 rounded-md border border-accent/10 group-focus-visible:outline-1 group-focus-visible:outline-white">
                  <Image
                    // src={starkProfile?.profilePicture || "/fallback-avatar.svg"}
                    src={"/fallback-avatar.svg"}
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
                    src={"/fallback-avatar.svg"}
                    className="shrink-0 rounded-full"
                    width={20}
                    height={20}
                    alt="strkprofile-pfp"
                  />
                  <p className="flex items-center gap-1 text-sm">
                    {address && shortAddress(address, 4, 4)}
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

          {address && (
            <TooltipProvider delayDuration={0}>
              <Tooltip>
                <TooltipTrigger asChild>
                  <Button
                    className="group size-8 cursor-pointer transition-all hover:bg-primary"
                    variant="ghost"
                    onClick={() => {
                      navigator.clipboard.writeText(address);
                      toast({
                        description: (
                          <div className="flex items-center gap-2 text-white">
                            <CircleCheck className="size-5" />
                            Address copied
                          </div>
                        ),
                      });
                      setShowTick(true);
                      setTimeout(() => setShowTick(false), 1000);
                    }}
                  >
                    {!showTick && (
                      <Copy className="size-3 text-accent/30 transition-all group-hover:text-accent" />
                    )}

                    {showTick && (
                      <Check className="size-3 text-accent/30 transition-all group-hover:text-accent" />
                    )}
                  </Button>
                </TooltipTrigger>
                <TooltipContent className="border border-accent/10">
                  copy address
                </TooltipContent>
              </Tooltip>
            </TooltipProvider>
          )}
        </div>
      </MaxWidthWrapper>
    </header>
  );
};

export default Navbar;
