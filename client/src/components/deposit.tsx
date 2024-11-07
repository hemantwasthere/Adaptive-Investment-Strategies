"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import React from "react";
import { useForm } from "react-hook-form";
import * as z from "zod";

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

const formSchema = z.object({
  ethAmount: z.number().positive(),
});

export type FormValues = z.infer<typeof formSchema>;

const Deposit: React.FC = () => {
  const form = useForm<FormValues>({
    resolver: zodResolver(formSchema),
    values: {
      ethAmount: 0,
    },
    mode: "onChange",
  });

  const onSubmit = async (values: FormValues) => {
    const { ethAmount } = values;

    console.log(ethAmount);
  };

  return (
    <div className="">
      <h4 className="flex items-center text-xl">
        Pool Pair -<span className="ml-1"> eth {"->"} weth</span>
      </h4>

      <div className="mt-2">
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)}>
            <FormField
              control={form.control}
              name="ethAmount"
              render={({ field }) => (
                <FormItem>
                  <FormLabel className="text-muted-foreground">
                    your eth amount
                  </FormLabel>
                  <FormControl>
                    <Input
                      className="border-primary/90"
                      placeholder="0.43"
                      {...field}
                    />
                  </FormControl>
                  <FormDescription>
                    The amount of eth you want to deposit
                  </FormDescription>
                  <FormMessage />
                </FormItem>
              )}
            />
          </form>
        </Form>
      </div>
    </div>
  );
};

export default Deposit;
