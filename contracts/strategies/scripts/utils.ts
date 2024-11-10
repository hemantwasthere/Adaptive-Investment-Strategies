import { existsSync, readFileSync, writeFileSync } from "fs";
import {
  Account,
  RawArgs,
  RpcProvider,
  TransactionExecutionStatus,
  extractContractHashes,
  hash,
  json,
  provider,
} from "starknet";

export function getRpcProvider() {
  return new RpcProvider({
    nodeUrl: "http://127.0.0.1:5050/rpc",
    blockIdentifier: "latest",
  });
}

function getContracts() {
  const PATH = "./contracts.json";
  if (existsSync(PATH)) {
    return JSON.parse(readFileSync(PATH, { encoding: "utf-8" }));
  }
  return {};
}

function saveContracts(contracts: any) {
  const PATH = "./contracts.json";
  writeFileSync(PATH, JSON.stringify(contracts));
}

export function getAccount() {
  return new Account(
    getRpcProvider(),
    "0x64b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691",
    "0x0000000000000000000000000000000071d7bb07b9a64f6f78ac4c816aff4da9"
  ); // 'address' and PK
}

export async function myDeclare(
  contract_name: string,
  package_name: string = "strategies"
) {
  const provider = getRpcProvider();
  const acc = getAccount();
  const compiledSierra = json.parse(
    readFileSync(
      `./target/dev/${package_name}_${contract_name}.contract_class.json`
    ).toString("ascii")
  );
  const compiledCasm = json.parse(
    readFileSync(
      `./target/dev/${package_name}_${contract_name}.compiled_contract_class.json`
    ).toString("ascii")
  );

  const contracts = getContracts();
  const payload = {
    contract: compiledSierra,
    casm: compiledCasm,
  };

  // const fee = await acc.estimateDeclareFee({
  //     contract: compiledSierra,
  //     casm: compiledCasm,
  // })
  // console.log('declare fee', Number(fee.suggestedMaxFee) / 10 ** 18, 'ETH')
  const result = extractContractHashes(payload);
  console.log("classhash:", result.classHash);

  const tx = await acc.declareIfNot(payload);
  console.log(`Declaring: ${contract_name}, tx:`, tx.transaction_hash);
  await provider.waitForTransaction(tx.transaction_hash, {
    successStates: [TransactionExecutionStatus.SUCCEEDED],
  });

  if (!contracts.class_hashes) {
    contracts["class_hashes"] = {};
  }

  // Todo attach cairo and scarb version. and commit ID
  contracts.class_hashes[contract_name] = tx.class_hash;
  saveContracts(contracts);
  console.log(`Contract declared: ${contract_name}`);
  console.log(`Class hash: ${tx.class_hash}`);
  return tx;
}

export async function deployContract(
  contract_name: string,
  classHash: string,
  constructorData: RawArgs
) {
  const provider = getRpcProvider();
  const acc = getAccount();

  // const fee = await acc.estimateDeployFee({
  //     classHash,
  //     constructorCalldata: constructorData,
  // })
  // console.log("Deploy fee", contract_name, Number(fee.suggestedMaxFee) / 10 ** 18, 'ETH')

  const tx = await acc.deployContract({
    classHash,
    constructorCalldata: constructorData,
  });
  console.log("Deploy tx: ", tx.transaction_hash);
  await provider.waitForTransaction(tx.transaction_hash, {
    successStates: [TransactionExecutionStatus.SUCCEEDED],
  });
  const contracts = getContracts();
  if (!contracts.contracts) {
    contracts["contracts"] = {};
  }
  contracts.contracts[contract_name] = tx.contract_address;
  saveContracts(contracts);
  console.log(`Contract deployed: ${contract_name}`);
  console.log(`Address: ${tx.contract_address}`);
  return tx;
}
