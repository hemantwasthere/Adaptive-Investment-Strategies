import { deployContract, getAccount, myDeclare } from "./utils";

async function main() {
    const account = getAccount()
  
    const auto_vault_tx = await myDeclare('AutoVault');
    const cl_vault_tx = await myDeclare('CLVault');
    const auto_comp_classhash = '0x022cdeceb0ba23d1c5b0dede12066c03a7084fa838ce61f77b1c343e872031bf'; 

    const auto_vault_address = await deployContract('AutoVault', auto_vault_tx.class_hash, []);
    const cl_vault_address = await deployContract('CLVault', cl_vault_tx.class_hash, []);
    const auto_comp_address = await deployContract('HarvestInvestStrat', auto_comp_classhash, []);

  
  }
  
  main();
  
  