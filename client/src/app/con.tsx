import React from "react";
import { Account, Contract, RpcProvider } from "starknet";

// import { abi } from "./assets/abi.json"

const Con = () => {
  // const PRIVATE_KEY =
  //   "0x0574ba4998dd9aedf1c4d6e56b747b29256a795bc3846437d121cd64b972bdd8";

  // const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS!;
  // const provider = new RpcProvider({
  //   nodeUrl: "http://0.0.0.0:5050/rpc",
  // });
  // const account = new Account(
  //   provider,
  //   "0x05d3a8f378500497479d3a16cfcd54657246dc37da8270b52e49319fac139939",
  //   PRIVATE_KEY,
  // );
  // const contract = new Contract(abi, CONTRACT_ADDRESS, account);

  // async function callContract() {
  //   const res = await contract.get_balance();
  //   console.log(res.toString());
  // }

  // async function writeToContract() {
  //   contract.connect(account);
  //   const myCall = contract.populate("increase_balance", [35]);
  //   const res = await contract.increase_balance(myCall.calldata);
  //   console.log(res);
  // }

  return <div>Con</div>;
};

export default Con;
