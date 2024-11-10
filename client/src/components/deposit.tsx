"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import {
  useAccount,
  useBalance,
  useReadContract,
  useSendTransaction,
} from "@starknet-react/core";
import { motion } from "framer-motion";
import { Info } from "lucide-react";
import React, { useMemo } from "react";
import { useForm } from "react-hook-form";
import * as z from "zod";

import erc20Abi from "@/abi/erc20.abi.json";
import { buttonVariants } from "@/components/ui/button";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { toast } from "@/hooks/use-toast";
import { cn } from "@/lib/utils";
import { userStore } from "@/store/user-store";
import { Contract, RpcProvider, uint256 } from "starknet";

const formSchema = z.object({
  ethAmount: z.string().refine(
    (v) => {
      let n = Number(v);
      return !isNaN(n) && v?.length > 0;
    },
    { message: "Invalid eth amount" },
  ),
});

export type FormValues = z.infer<typeof formSchema>;

const Deposit: React.FC = () => {
  const [ethAmount, setEthAmount] = React.useState("0");

  const { setLendingData, setDexData } = userStore();

  const { address } = useAccount();

  const { data } = useBalance({
    address,
  });

  const form = useForm<FormValues>({
    resolver: zodResolver(formSchema),
    values: {
      ethAmount: ethAmount,
    },
    mode: "onChange",
  });

  const provider = new RpcProvider({
    nodeUrl: "http://0.0.0.0:5050/rpc",
  });

  const contract = new Contract(
    erc20Abi,
    "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7",
    provider,
  );

  const call1 = useMemo(() => {
    console.log(ethAmount, "ethAmount");
    return contract.populate("approve", [
      "0x142cdbe00acf31e7a0668aa805ef9594c1c28085201e54ee0b9bb3f624735a9",

      uint256.bnToUint256((Number(ethAmount) * 1.5 * 10 ** 18).toFixed(0)),
    ]);
  }, [ethAmount]);

  const { sendAsync } = useSendTransaction({
    calls: [call1],
  });

  const onSubmit = async (values: FormValues) => {
    const { ethAmount } = values;

    if (!address) return;

    setEthAmount(BigInt(ethAmount).toString());
    setLendingData(ethAmount);
    setDexData(ethAmount);

    setTimeout(async () => {
      const res = await sendAsync();
      console.log(res);
    }, 1000);
  };

  const { data: balance } = useReadContract({
    abi: erc20Abi,
    functionName: "balance_of",
    address:
      "0x142cdbe00acf31e7a0668aa805ef9594c1c28085201e54ee0b9bb3f624735a9",
    args: [address],
  });

  console.log(balance);

  React.useEffect(() => {
    if (!address) setEthAmount("");
  }, [address]);

  return (
    <div className="h-full">
      <div className="flex items-center justify-between">
        <h5 className="flex items-center text-xl">ETH vault</h5>

        <div className="flex animate-pulse items-center gap-2 text-xs">
          <div className="h-1 w-1 rounded-full bg-green-500" />
          Devnet
        </div>
      </div>

      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)}>
          <div className="mt-2 flex h-full flex-col justify-between">
            <FormField
              control={form.control}
              name="ethAmount"
              render={({ field }) => (
                <FormItem className="relative space-y-1">
                  <FormLabel className="text-muted-foreground">
                    your eth amount
                  </FormLabel>
                  <FormControl>
                    <div className="relative">
                      <Input
                        className="border-accent/10 pr-20 lg:pr-[4.6rem]"
                        placeholder="0.43"
                        {...field}
                      />
                      <motion.button
                        className={cn(
                          buttonVariants({ variant: "outline" }),
                          "absolute right-[0.4rem] top-[18%] h-6 rounded-md border-accent/10 bg-primary text-xs uppercase hover:bg-accent/10 hover:text-white",
                        )}
                        type="button"
                        onClick={() => {
                          if (!address) {
                            return toast({
                              description: (
                                <div className="flex items-center gap-2 text-white">
                                  <Info className="size-5" />
                                  Please connect your wallet
                                </div>
                              ),
                            });
                          }
                          if (data) {
                            setEthAmount(data?.formatted?.toString());
                            form.setValue(
                              "ethAmount",
                              data?.formatted?.toString(),
                            );
                            form.clearErrors("ethAmount");
                          }
                        }}
                        whileHover={{ scale: 1.1 }}
                        whileTap={{ scale: 0.9 }}
                        transition={{
                          type: "spring",
                          stiffness: 400,
                          damping: 10,
                        }}
                      >
                        max
                      </motion.button>
                    </div>
                  </FormControl>
                  <FormMessage className="absolute -bottom-5 left-1 text-xs" />
                </FormItem>
              )}
            />

            <div className="mt-7 space-y-1 px-2">
              <div className="flex items-center justify-between text-xs text-muted-foreground">
                <span>You will receive:</span>
                <span>
                  {Number(form.watch("ethAmount")) > 0
                    ? `${
                        form.watch("ethAmount").includes(".") &&
                        form.watch("ethAmount").split(".")[1].length > 7
                          ? `${Number(form.watch("ethAmount")).toFixed(3).slice(0, 6)}...${form.watch("ethAmount").slice(-3)}`
                          : Number(form.watch("ethAmount"))
                      } rbETH`
                    : "0"}
                </span>
              </div>
              <div className="flex items-center justify-between text-xs text-muted-foreground">
                <span>Exchange rate:</span>
                <span>1 ETH = 1 rbETH</span>
              </div>
              <div className="flex items-center justify-between text-xs text-muted-foreground">
                <span>Protocol Fee:</span>
                <span>0.03%</span>
              </div>
              <div className="flex items-center justify-between text-xs font-semibold text-white/90">
                <span>Mode:</span>
                <span>LENDING</span>
              </div>
            </div>
          </div>

          <motion.button
            type="submit"
            className={cn(
              buttonVariants(),
              "ml-auto mt-4 flex w-fit justify-end text-white/70 transition-all hover:text-white/90",
            )}
            whileHover={{ scale: 1.01 }}
            whileTap={{ scale: 0.9 }}
            transition={{ type: "spring", stiffness: 400, damping: 10 }}
          >
            {Number(form.watch("ethAmount")) > 0
              ? `Deposit: ${
                  form.watch("ethAmount").includes(".") &&
                  form.watch("ethAmount").split(".")[1].length > 7
                    ? `${Number(form.watch("ethAmount")).toFixed(3).slice(0, 6)}...${form.watch("ethAmount").slice(-3)}`
                    : Number(form.watch("ethAmount"))
                } ETH`
              : "Deposit"}
          </motion.button>
        </form>
      </Form>
    </div>
  );
};

export default Deposit;
