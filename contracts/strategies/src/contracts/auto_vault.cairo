#[starknet::contract]
mod AutoVault {
    use starknet::{ContractAddress, get_caller_address, get_contract_address, get_block_timestamp};

    use strategies::utils::errors::Errors;
    use strategies::utils::constants::Constants::{LENDING, DEX};
    use strategies::utils::math::Math::{mul_div_down, mul_div_up};


    use strategies::interfaces::IAutoVault::IAutoVault;
    use strategies::interfaces::ICLVault::{ICLVaultDispatcher, ICLVaultDispatcherTrait};
    use strategies::interfaces::IERC20Camel::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};
    use strategies::interfaces::IERC4626::{IERC4626Dispatcher, IERC4626DispatcherTrait};


    // use openzeppelin_token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    // ERC20 Mixin
    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;


    use strategies::components::swap::{AvnuMultiRouteSwap, AvnuMultiRouteSwapImpl};
    use strategies::interfaces::oracle::{
        IPriceOracle, IPriceOracleDispatcher, IPriceOracleDispatcherTrait
    };


    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        token: ContractAddress,
        rebalancer: ContractAddress,
        current_mode: u8,
        auto_compound_vault: ContractAddress,
        cl_vault: ContractAddress,
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
        _auto_compound_vault: ContractAddress,
        _cl_vault: ContractAddress,
    ) {
        // assert(!token.is_zero(), Errors::ZERO_ADDRESS);
        // assert(!_admin.is_zero(), Errors::ZERO_ADDRESS);
        //     self.accesscontrol.initializer();
        //     self._set_admin(_admin);

        // TODO if felt, change the datatype of name and symbol to byteArray.
        self.erc20.initializer(name, symbol);
        self.token.write(_token);
        self.rebalancer.write(_rebalancer);
        self.auto_compound_vault.write(_auto_compound_vault);
        self.cl_vault.write(_cl_vault);
        // @note >> Approve the CLVault for max value of eth and wstETH
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
            self._withdraw(get_caller_address(), receiver, owner, assets, shares);
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
            let auto_comp_dispatcher: IERC4626Dispatcher = IERC4626Dispatcher {
                contract_address: self.auto_compound_vault.read()
            };
            let auto_compound_shares = auto_comp_dispatcher.balance_of(get_contract_address());
            let comp_asset_balance = auto_comp_dispatcher.convert_to_assets(auto_compound_shares);

            // TODO balance in CL vault.
            let cl_asset_balance = 0;

            // NOTE total_assets = comp_asset_balance + cl_asset_balance
            let total_asset = comp_asset_balance + cl_asset_balance;

            return total_asset;
        }

        fn rebalance(ref self: ContractState, _mode: u8) {
            assert(get_caller_address() == self.rebalancer.read(), 'NOT AUTHORIZED');
            assert(_mode == LENDING || _mode == DEX, 'incorrect mode'); // 1 for lending, 2 for CL

            if (self.current_mode.read() != _mode) {
                if (_mode == LENDING) {
                    // CL vault withdrawal and auto_compound vault deposit calls
                    let auto_comp_dispatcher: IERC4626Dispatcher = IERC4626Dispatcher {
                        contract_address: self.auto_compound_vault.read()
                    };
                    let auto_compound_shares = auto_comp_dispatcher
                        .balance_of(get_contract_address());
                    let vault_asset_balance = auto_comp_dispatcher
                        .convert_to_assets(auto_compound_shares);

                    //withdrawal from CL vault.
                    let (primary_token_amount, secondary_token_amount) = self
                        ._withdraw_from_cl(vault_asset_balance);
                    // @note >> Swap secodary to primary, let say amount is t
                    // deposit to auto comp vault
                    self._deposit_to_auto_comp(primary_token_amount + t);
                } else { //TODO implement auto_compound vault withdrawal and CL vault deposit calls
                }
                self.emit(Rebalance { mode: _mode, timestamp: get_block_timestamp() });
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

            self.emit(Deposit { sender: caller, owner: receiver, assets: assets, shares: shares, });

            // TODO call the lending/dex vaults.
            if (self.current_mode.read() == LENDING) {
                self._deposit_to_auto_comp(assets);
            } else {
                self._deposit_to_cl(assets);
            }
        }

        fn _withdraw(
            ref self: ContractState,
            caller: ContractAddress,
            receiver: ContractAddress,
            owner: ContractAddress,
            assets: u256,
            shares: u256,
        ) {
            // self.erc20.transferFrom(owner, get_contract_address(), shares);
            if (caller != owner) {
                self.erc20._spend_allowance(owner, caller, shares);
            }
            self.erc20.burn(owner, shares);
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

            if (self.current_mode.read() == LENDING) {
                let asset = self._withdraw_from_auto_comp(assets);

                // transfer ETH to user
                self.erc20.transfer(receiver, asset);
            } else {
                let asset = self._withdraw_from_cl(assets);
                self.erc20.transfer(receiver, asset);
            }
        }


        // deposit to strkFarm auto compound vault.
        fn _deposit_to_auto_comp(ref self: ContractState, assets: u256,) {
            // Auto compound vault, ZKlend
            let auto_comp_dispatcher: IERC4626Dispatcher = IERC4626Dispatcher {
                contract_address: self.auto_compound_vault.read()
            };
            // NOTE reciever of AutoCompund  LP will be auto vault
            auto_comp_dispatcher.deposit(assets, get_contract_address());
        }

        fn _withdraw_from_auto_comp(ref self: ContractState, assets: u256, // ETH
        ) -> u256 {
            // Auto compound vault, ZKlend
            let auto_comp_dispatcher: IERC4626Dispatcher = IERC4626Dispatcher {
                contract_address: self.auto_compound_vault.read()
            };

            let auto_comp_share = auto_comp_dispatcher.convert_to_shares(assets);
            // NOTE reciever of AutoCompound LP will be auto vault
            let asset = auto_comp_dispatcher
                .redeem(auto_comp_share, get_contract_address(), get_contract_address());
            return asset;
        }


        // TODO
        // deposit to  CL vault.
        fn _deposit_to_cl(ref self: ContractState, assets: u256,) {
            let CLVault = ICLVaultDispatcher { contract_address: self.cl_vault.read() };
            let (a, b) = CLVault.split_primary_token(assets);
            // @note >> Do min check ?
            // @note >> For now directly swapping
            let amount_to_swap = (assets - a);
            // @note >> Get the amount of wsETH after swap, i.e get t
            // - If t < b, Tx could revert
            // use self.swap() >> Once build issue is fixed
            // @note >> Approve the CL Vault ?
            // @note >> Don't approve, transfer from user to AutoVault
            let shares = CLVault.provide_liquidity(a, b, get_contract_address());
        }

        // TODO
        // withdraw from CL
        fn _withdraw_from_cl(ref self: ContractState, assets: u256,) -> (u256, u256) {
            let CLVault = ICLVaultDispatcher { contract_address: self.cl_vault.read() };
            let auto_vault_net_liquidity = IERC20Dispatcher {
                contract_address: CLVault.get_cl_token()
            }
                .balance_of(get_contract_address());
            // @note >> Approve tho burn the CLToken
            let (primary_token_amount, secondary_token_amount) = CLVault
                .remove_liquidity(auto_vault_net_liquidity);
            // @note >> Make sure we have both amount not single token
            return (primary_token_amount, secondary_token_amount);
        }


        fn _erc20_camel(self: @ContractState) -> IERC20CamelDispatcher {
            IERC20CamelDispatcher { contract_address: self.token.read() }
        }


        fn _swap(ref self: ContractState, swapInfo: AvnuMultiRouteSwap,) -> u256 {
            return swapInfo.swap();
        }
    }
}
