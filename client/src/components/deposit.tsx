"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import { useAccount, useBalance } from "@starknet-react/core";
import React from "react";
import { useForm } from "react-hook-form";
import * as z from "zod";

import { Button } from "@/components/ui/button";
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
  const [ethAmount, setEthAmount] = React.useState("");

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

  const onSubmit = async (values: FormValues) => {
    const { ethAmount } = values;

    console.log(ethAmount);
  };

  React.useEffect(() => {
    if (!address) setEthAmount("");
  }, [address]);

  return (
    <div className="h-full">
      <h5 className="flex items-center text-xl">ETH Pool</h5>

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
                        className="border-accent/10"
                        placeholder="0.43"
                        {...field}
                      />
                      <Button
                        className="absolute right-1.5 top-1/2 h-6 -translate-y-1/2 rounded-md border-accent/10 bg-primary text-xs uppercase hover:bg-accent/10 hover:text-white"
                        variant="outline"
                        type="button"
                        onClick={() => {
                          if (!address) {
                            return toast({
                              type: "foreground",
                              variant: "default",
                              title: "Please connect your wallet",
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
                      >
                        max
                      </Button>
                    </div>
                  </FormControl>
                  <FormMessage className="absolute -bottom-5 left-1 text-xs" />
                </FormItem>
              )}
            />

            <div className="mt-7 space-y-1 px-2">
              <div className="flex items-center justify-between text-xs text-muted-foreground">
                <span>Exchange rate:</span>
                <span>1 ETH = 1 wETH</span>
              </div>
              <div className="flex items-center justify-between text-xs text-muted-foreground">
                <span>Deposit Fee:</span>
                <span>1.00%</span>
              </div>
              <div className="flex items-center justify-between text-xs text-muted-foreground">
                <span>Staking limit:</span>
                <span>3.04M of 20.00M</span>
              </div>
            </div>
          </div>

          <Button
            type="submit"
            className="ml-auto mt-5 flex w-fit justify-end text-white/70 transition-all hover:text-white/90"
          >
            {Number(form.watch("ethAmount")) > 0
              ? `Deposit: ${form.watch("ethAmount")} ETH`
              : "Deposit"}
          </Button>
        </form>
      </Form>
    </div>
  );
};

export default Deposit;
