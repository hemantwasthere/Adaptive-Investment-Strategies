import { getAccount } from "./utils";

async function main() {
    const account = getAccount('')
  
    let auto_vault_address = await declareAndDeployAutoVault(account);
    let cl_vault_address = await declareAndDeployAutoCLVault(account);
    let auto_comp_address = await deployAutoCompoundVault(account);
  
    let addressObj = {
      auto_vault_address,
      cl_vault_address,
      auto_comp_address,
    };
  
  }
  
  main();
  

  // entry point contract
  async function declareAndDeployAutoVault(account: any) {
   
  }
  
  async function declareAndDeployAutoCLVault(account: any) {
    
  }
  
  async function deployAutoCompoundVault(account) {
    const auto_comp_classhash = '0x022cdeceb0ba23d1c5b0dede12066c03a7084fa838ce61f77b1c343e872031bf';
    
  }
  