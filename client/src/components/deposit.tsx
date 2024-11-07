"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import React from "react";
import { useForm } from "react-hook-form";
import * as z from "zod";

import { Button } from "@/components/ui/button";
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { toast } from "@/hooks/use-toast";
import { useAccount, useBalance } from "@starknet-react/core";

const formSchema = z.object({
  ethAmount: z.string().refine(
    (v) => {
      let n = Number(v);
      return !isNaN(n) && v?.length > 0;
    },
    { message: "Invalid eth amount" }
  ),
  wEthAmount: z.string().refine(
    (v) => {
      let n = Number(v);
      return !isNaN(n) && v?.length > 0;
    },
    { message: "Invalid wEth amount" }
  ),
});

export type FormValues = z.infer<typeof formSchema>;

const Deposit: React.FC = () => {
  const [ethAmount, setEthAmount] = React.useState("");
  const [wEthAmount, setWEthAmount] = React.useState("");

  const { address } = useAccount();
  const { data } = useBalance({
    address,
  });

  const form = useForm<FormValues>({
    resolver: zodResolver(formSchema),
    values: {
      ethAmount: ethAmount,
      wEthAmount: wEthAmount,
    },
    mode: "onChange",
  });

  const onSubmit = async (values: FormValues) => {
    const { ethAmount } = values;

    console.log(ethAmount);
  };

  React.useEffect(() => {
    if (!address) {
      setEthAmount("");
      setWEthAmount("");
    }
  }, [address]);

  return (
    <div className="">
      <h4 className="flex items-center text-xl">
        Pool Pair -<span className="ml-1">eth to weth</span>
      </h4>

      <div className="mt-2">
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-3">
            <FormField
              control={form.control}
              name="ethAmount"
              render={({ field }) => (
                <FormItem className="space-y-1">
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
                        className="uppercase h-6 bg-primary text-xs absolute right-1.5 top-1/2 -translate-y-1/2 rounded-md border-accent/10 hover:bg-accent/10 hover:text-white"
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
                          data && setEthAmount(data?.formatted?.toString());
                        }}
                      >
                        max
                      </Button>
                    </div>
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="wEthAmount"
              render={({ field }) => (
                <FormItem className="relative space-y-1">
                  <FormLabel className="text-muted-foreground">
                    your wEth amount
                  </FormLabel>
                  <FormControl>
                    <Input
                      className="border-accent/10"
                      placeholder="1.3"
                      {...field}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <Button type="submit" className="mt-4">
              Deposit
            </Button>
          </form>
        </Form>
      </div>
    </div>
  );
};

export default Deposit;
