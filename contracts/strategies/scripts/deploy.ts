import {cairo, byteArray} from 'starknet'
import { deployContract, getAccount, myDeclare } from "./utils";

async function main() {
  console.log('running')
    const account = getAccount()

    let cl_token_address = await declareAndCL_Token();

    let cl_vault_address = await declareAndCL_Vault(cl_token_address);
  
    let auto_comp_vault_address = await declareAnd_auto_comp_vault();

    let auto_vault_address = await declareAnd_auto_vault(auto_comp_vault_address, cl_vault_address, cl_token_address);

  }
  
  main();


  async function declareAndCL_Token() {
    console.log("============== Deploying CLToken =========================");
    const cl_token_tx = await myDeclare('CLToken');
    const cl_token_deployed_tx = await deployContract('CLToken', cl_token_tx.class_hash, []);
    console.log("============== CLToken DEPLOYED=========================", cl_token_deployed_tx.contract_address);

    return cl_token_deployed_tx.contract_address;

  }

  async function declareAndCL_Vault(cl_token_address: any) {
    console.log(" *********************** Deploying CL Vault ******************* ");


    const cl_vault_tx = await myDeclare('CLVault');




    const cl_vault_address = await deployContract('CLVault', cl_vault_tx.class_hash, 
      {
        ekubo_positions_contract: '0x02e0af29598b407c8716b17f6d2795eca1b471413fa03fb145a5e33722184067', //ekubo position
        bounds_settings: {
            lower: cairo.uint256(1180100000000000000),
            upper: cairo.uint256(1187680000000000000),
            // lower: 1180100000000000000,
            // upper: 1187680000000000000,
          }, // Bounds
        pool_key: {
          token0: '0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7', // ETH
          token1: '0x042b8f0484674ca266ac5d08e4ac6a3fe65bd3129795def2dca5c34ecc5f96d2',  // wstETH
          fee: 30, // 0.3%
          tick_spacing: cairo.uint256(1000001000000000000),
          extension: '0x005e470ff654d834983a46b8f29dfa99963d5044b993cb7b9c92243a69dab38f' // note check
        }, // pool_key
      ekubo_positions_nft: '0x07b696af58c967c1b14c9dde0ace001720635a660a8e90c565ea459345318b30', //ekubo_positions_nft
      ekubo_core: '0x00000005dd3D2F4429AF886cD1a3b08289DBcEa99A294197E9eB43b0e0325b4b', //ekubo_core
      oracle: '0x005e470ff654d834983a46b8f29dfa99963d5044b993cb7b9c92243a69dab38f', //oracle
      cl_token: cl_token_address
    });



    console.log(" *********************** CL Vault DEPLOYED *********************** ", cl_vault_address.contract_address);

    return cl_vault_address.contract_address;

  }


  async function declareAnd_auto_comp_vault() {

      console.log(" ############################### Deploying Auto Compound Vault!!! ############################### ");


      const auto_comp_classhash = '0x022cdeceb0ba23d1c5b0dede12066c03a7084fa838ce61f77b1c343e872031bf'; 

      const swap_hash = '0x56c809dd30d3c06e772f82a91d19e2b8553e538ff7e6699b06c82fc4b796eaf'
      const lend_hash = '0x6f9c4e995d20490d46e3e743a052ad5b728bc5b58c4281f058f7242ac247ed9'


      const auto_comp_address = await deployContract('HarvestInvestStrat', auto_comp_classhash, {
      asset: '0x01b5bd713e72fdc5d63ffd83762f81297f6175a5e0a4771cdadbc1dd5fe72cb1', // zETH
      name: byteArray.byteArrayFromString('AC zETH Vault'),
      symbol: byteArray.byteArrayFromString('frmzETH'),
      offset: 0,
      settings: {
          rewardsContract: '0x7bbdf36eb04b347e1ecd9b9b37eeac1688fa252db68888a79fdef358667feb2',
          depositMarket: '0x04c0a5193d58f74fbace4b74dcf65481e734ed1714121bdc571da345540efa05',
          lendClassHash: lend_hash,
          swapClassHash: swap_hash
      },
      // lend_settings: {
      //   zkLendRouter: '',
      //   oracle: ''
      // },
      owner: '0x64b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691'
  });

  console.log(" *********************** Auto Compound Vault DEPLOYED *********************** ", auto_comp_address.contract_address);
  return auto_comp_address.contract_address;
}


async function declareAnd_auto_vault(auto_comp_address: any, cl_vault_address: any, cl_token_address: any) {
      console.log(" !!!!!!!!!!!!!!!!!!!!!!!!!!!!! Deploying Auto  Vault!!! !!!!!!!!!!!!!!!!!!!!!!!!!!!!! ");
  
      const auto_vault_tx = await myDeclare('AutoVault');

      const auto_vault_deploy_tx = await deployContract('AutoVault', auto_vault_tx.class_hash, 
        {
          name: byteArray.byteArrayFromString('AutoVault'), 
          symbol: byteArray.byteArrayFromString('AutoVault'),   
          _admin: '0x64b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691',     
          _rebalancer: '0x64b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691', //rebalancer
          _auto_compound_vault: auto_comp_address,
          _cl_vault: cl_vault_address,
          _cl_token: cl_token_address
      });


      console.log(" !!!!!!!!!!!!!!!!!!!!!!!!!!!!! Auto Vault DEPLOYED !!!!!!!!!!!!!!!!!!!!!!!!!!!!! ", auto_vault_deploy_tx.contract_address);

      return auto_vault_deploy_tx.contract_address;
    }
  
  