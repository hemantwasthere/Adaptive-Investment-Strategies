#[starknet::contract]
mod AutoVault {
    use starknet::{
        ContractAddress, get_caller_address, get_contract_address, get_block_timestamp
    };

    use strategies::utils::errors::Errors;
    use strategies::utils::math::Math::{mul_div_down, mul_div_up};


    use strategies::interfaces::IAutoVault::IAutoVault;
    use strategies::interfaces::IERC20Camel::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};
    use strategies::interfaces::IERC4626::{IERC4626Dispatcher, IERC4626DispatcherTrait};
    


    use openzeppelin_token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    // ERC20 Mixin
    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        token: ContractAddress, 
        rebalancer: ContractAddress, 
        current_mode: u8,
        strkFarm_auto_compound_vault: ContractAddress, 
        
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
        Deposit: Deposit,
        Withdraw: Withdraw,
        Rebalance: Rebalance,
    }

    #[derive(Drop, starknet::Event)]
    struct Deposit {
        sender: ContractAddress,
        owner: ContractAddress,
        assets: u256,
        shares: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Withdraw {
        sender: ContractAddress,
        receiver: ContractAddress,
        owner: ContractAddress,
        assets: u256,
        share: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Rebalance {
        mode: u8,
        timestamp: u64,
    }

    #[constructor]
        fn constructor(
            ref self: ContractState,
            name: ByteArray,
            symbol: ByteArray,
            _token: ContractAddress,
            _admin: ContractAddress,
            _rebalancer: ContractAddress,
            _strkFarm_auto_compound_vault: ContractAddress,
        ) {
            // assert(!token.is_zero(), Errors::ZERO_ADDRESS);
            // assert(!_admin.is_zero(), Errors::ZERO_ADDRESS);
        //     self.accesscontrol.initializer();
        //     self._set_admin(_admin);

            // TODO if felt, change the datatype of name and symbol to byteArray.
            self.erc20.initializer(name, symbol);
            self.token.write(_token);
            self.rebalancer.write(_rebalancer);
            self.strkFarm_auto_compound_vault.write(_strkFarm_auto_compound_vault);
        }   

    #[abi(embed_v0)]
    impl AutoVaultImpl of IAutoVault<ContractState> {
    
        fn deposit(ref self: ContractState, assets: u256, receiver: ContractAddress) -> u256 {
            let _shares = self.preview_deposit(assets);
            self._deposit(get_caller_address(), receiver, assets, _shares);
            return _shares;
        }

        fn mint(ref self: ContractState, shares: u256, receiver: ContractAddress) -> u256 {
            let assets = self.preview_mint(shares);
            let _shares = self.convert_to_shares(assets);
            self._deposit(get_caller_address(), receiver, assets, _shares);
            return assets;
        }

        fn withdraw(
            ref self: ContractState, assets: u256, receiver: ContractAddress, owner: ContractAddress
        ) -> u256 {
            let shares = self.preview_withdraw(assets); 
            let _assets = self.convert_to_assets(shares);           
            self._withdraw(get_caller_address(), receiver, owner, _assets, shares);
            return shares;            
        }


        fn redeem(
            ref self: ContractState, shares: u256, receiver: ContractAddress, owner: ContractAddress
        ) -> u256 {
            let _assets = self.preview_redeem(shares);
            self._withdraw(get_caller_address(), receiver, owner, _assets, shares);
            return _assets;
        }

        
        fn preview_deposit(self: @ContractState, assets: u256) -> u256 {
            self.convert_to_shares(assets)
        }

        fn preview_mint(self: @ContractState, shares: u256) -> u256 {
            self.convert_to_assets(shares)
        }

        fn preview_withdraw(self: @ContractState, assets: u256) -> u256 {
            self.convert_to_shares(assets)
        }

        fn preview_redeem(self: @ContractState, shares: u256) -> u256 {
            self.convert_to_assets(shares)
        }

        fn convert_to_shares(self: @ContractState, assets: u256) -> u256 {
            let supply: u256 = self.erc20.total_supply();
            if (assets == 0 || supply == 0) {
                assets
            } else {
                mul_div_down(assets, supply, self.total_assets())
            }

        }

        fn convert_to_assets(self: @ContractState, shares: u256) -> u256 {
            let supply: u256 = self.erc20.total_supply();
            if (supply == 0) {
                shares
            } else {
                mul_div_down(shares, self.total_assets(), supply)
            }
        }



        fn total_assets(self: @ContractState) -> u256 {
            
            // balance in auto compound vault
            let auto_comp_dispatcher : IERC4626Dispatcher = IERC4626Dispatcher { 
                contract_address: self.strkFarm_auto_compound_vault.read() 
            };    
            let auto_compound_shares = auto_comp_dispatcher.balance_of(get_contract_address());
            let comp_asset_balance = auto_comp_dispatcher.convert_to_assets(auto_compound_shares);

            // TODO balance in CL vault.
            let cl_asset_balance = 0;


            // TODO replace by CL balance
            // NOTE total_assets = comp_asset_balance + cl_asset_balance
            let total_asset = comp_asset_balance + cl_asset_balance;

            return total_asset;
        }

        fn rebalance(ref self: ContractState, _mode: u8) {
            assert(get_caller_address() == self.rebalancer.read(), 'NOT AUTORIZE');
            assert(_mode == 1 || _mode == 2, 'incorrect mode'); // 1 for lending, 2 for CL

            if(self.current_mode.read() != _mode ){
                if(_mode == 1) {
                    //TODO implement CL vault withdrawal and auto_compound vault deposit calls
                } else {
                    //TODO implement auto_compound vault withdrawal and CL vault deposit calls
                }
                self.emit(
                    Rebalance {
                        mode: _mode,
                        timestamp: get_block_timestamp()
                    }
                );
                self.current_mode.write(_mode);
            } 
        }

        

    }


    #[generate_trait]
    impl AutoVault of AutoVaultInternalTrait {
        fn _deposit(
            ref self: ContractState,
            caller: ContractAddress,
            receiver: ContractAddress,
            assets: u256,
            shares: u256
        ) {
            self._erc20_camel().transferFrom(caller, get_contract_address(), assets);
            self.erc20.mint(receiver, shares);


            self
                .emit(
                    Deposit {
                        sender: caller,
                        owner: receiver,
                        assets: assets,
                        shares: shares,
                    }
                );

            // TODO call the lending/dex vaults.

        }

        fn _withdraw(
            ref self: ContractState,
            caller: ContractAddress,
            receiver: ContractAddress,
            owner: ContractAddress,
            assets: u256,
            shares: u256,
        ) {
            // // TODO check OZ spend allowance function,
            // if (caller != owner) {
            //     self.erc20.spend_allowance(owner, caller, shares);
            // }

            self.erc20.transferFrom(owner, get_contract_address(), shares);
            self
                .emit(
                    Withdraw {
                        sender: caller,
                        receiver: receiver,
                        owner: owner,
                        assets: assets,
                        share: shares,
                    }
                );

            // TODO call the auto/CL vault for withdrawal
        }


        fn _erc20_camel(self: @ContractState) -> IERC20CamelDispatcher {
            IERC20CamelDispatcher { contract_address: self.token.read() }
        }
    }

}