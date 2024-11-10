#[starknet::contract]
mod AutoVault {
    use starknet::{ContractAddress, get_caller_address, get_contract_address, get_block_timestamp};

    use strategies::utils::errors::Errors;
    use strategies::utils::constants::Constants::{LENDING, DEX, DECIMALS};
    use strategies::utils::math::Math::{mul_div_down, mul_div_up, calculateXandY};
    use strategies::utils::helpers::ERC20Helper;

    use strategies::interfaces::IAutoVault::IAutoVault;
    use strategies::interfaces::ICLVault::{ICLVaultDispatcher, ICLVaultDispatcherTrait};
    use strategies::interfaces::IERC20Camel::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};
    use strategies::interfaces::IERC4626::{IERC4626Dispatcher, IERC4626DispatcherTrait};
    use strategies::utils::constants;

    // use openzeppelin_token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    // ERC20 Mixin
    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;


    use strategies::components::swap::{AvnuMultiRouteSwap, AvnuMultiRouteSwapImpl, Route};
    use strategies::interfaces::oracle::{
        IPriceOracle, IPriceOracleDispatcher, IPriceOracleDispatcherTrait
    };
    use integer::BoundedU256;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        token: ContractAddress,
        rebalancer: ContractAddress,
        current_mode: u8,
        auto_compound_vault: ContractAddress,
        cl_vault: ContractAddress,
        cl_token: ContractAddress,
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
        _admin: ContractAddress,
        _rebalancer: ContractAddress,
        _auto_compound_vault: ContractAddress,
        _cl_vault: ContractAddress,
        _cl_token: ContractAddress
    ) {
        // TODO if felt, change the datatype of name and symbol to byteArray.
        self.erc20.initializer(name, symbol);
        self.token.write(constants::ETH());
        self.rebalancer.write(_rebalancer);
        self.auto_compound_vault.write(_auto_compound_vault);
        self.cl_vault.write(_cl_vault);
        self.cl_token.write(_cl_token);
        // @note >> Approve the CLVault for max value of eth and wstETH >> Done
        IERC20Dispatcher { contract_address: constants::ETH() }
            .approve(self.cl_vault.read(), BoundedU256::max());
        IERC20Dispatcher { contract_address: constants::wstETH() }
            .approve(self.cl_vault.read(), BoundedU256::max());
        IERC20Dispatcher { contract_address: self.cl_token.read() }
            .approve(self.cl_vault.read(), BoundedU256::max());
        IERC20Dispatcher { contract_address: self.auto_compound_vault.read() }
            .approve(self.auto_compound_vault.read(), BoundedU256::max());
        IERC20Dispatcher { contract_address: constants::ETH() }
            .approve(self.auto_compound_vault.read(), BoundedU256::max());
        self.current_mode.write(0); //LENDING
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
            let total_asset: u256 = self.lending_assets() + self.dex_assets();
            return total_asset;
        }

        // In ETH AutoCompoundVault
        fn lending_assets(self: @ContractState) -> u256 {
            let auto_comp_dispatcher: IERC4626Dispatcher = IERC4626Dispatcher {
                contract_address: self.auto_compound_vault.read()
            };
            let auto_compound_shares = auto_comp_dispatcher.balance_of(get_contract_address());
            let comp_asset_balance = auto_comp_dispatcher.convert_to_assets(auto_compound_shares);
            return comp_asset_balance;
        }

        // In CLVault
        fn dex_assets(self: @ContractState) -> u256 {
            let CLVault = ICLVaultDispatcher { contract_address: self.cl_vault.read() };
            let auto_vault_liquidity = IERC20Dispatcher { contract_address: CLVault.get_cl_token() }
                .balance_of(get_contract_address());
            let (sqrtRatioA, sqrtRatioB, sqrtRatioCurrent) = CLVault.get_sqrt_values();
            let (x, y) = calculateXandY(
                auto_vault_liquidity.try_into().unwrap(), sqrtRatioA, sqrtRatioB, sqrtRatioCurrent
            );
            let price = CLVault.get_price(sqrtRatioCurrent.into());
            let y_primary = (y * DECIMALS) / price;
            return x + y_primary;
        }

        fn rebalance(ref self: ContractState, _mode: u8) {
            assert(get_caller_address() == self.rebalancer.read(), 'NOT AUTHORIZED');
            assert(_mode == LENDING || _mode == DEX, 'incorrect mode');

            if (self.current_mode.read() != _mode) {
                if (_mode == LENDING) {
                    //withdrawal from CL vault.
                    let (primary_token_amount, secondary_token_amount) = self
                        ._withdraw_all_from_cl();

                    let mut amount_primary_received = 0;
                    if (primary_token_amount != 0 && secondary_token_amount != 0) {
                        // Swap secondary for Primary
                        amount_primary_received = self._swap(secondary_token_amount, false);
                    };
                    if (primary_token_amount == 0) {
                        amount_primary_received = self._swap(secondary_token_amount, false);
                    }
                    amount_primary_received + primary_token_amount;
                    self._deposit_to_auto_comp(amount_primary_received + primary_token_amount);
                } else {
                    // Withdraw from AutoCompound
                    let primary_token = self._withdraw_all_from_auto_comp();
                    // Provide Liquidity to CLVault
                    let CLVault = ICLVaultDispatcher { contract_address: self.cl_vault.read() };
                    let (a, b) = CLVault.split_primary_token(primary_token);
                    let amount_to_swap = (primary_token - a);
                    let balance_secondary_before = IERC20Dispatcher {
                        contract_address: constants::wstETH()
                    }
                        .balance_of(get_contract_address());
                    self._swap(amount_to_swap, true);
                    let balance_secondary_after = IERC20Dispatcher {
                        contract_address: constants::wstETH()
                    }
                        .balance_of(get_contract_address());
                    let t = balance_secondary_after - balance_secondary_before;
                    let (sqrtRatioA, sqrtRatioB, sqrtRatioCurrent) = CLVault.get_sqrt_values();
                    let mut primary_amount = a;
                    if (t < b) {
                        let liquidity_t = t / (sqrtRatioB.into() - sqrtRatioCurrent.into());
                        primary_amount = liquidity_t
                            / (sqrtRatioCurrent.into() - sqrtRatioA.into());
                    }
                    let shares = CLVault
                        .provide_liquidity(primary_amount, t, get_contract_address());
                }
                self.emit(Rebalance { mode: _mode, timestamp: get_block_timestamp() });
                self.current_mode.write(_mode);
            }
        }

        fn rbETH_per_eth(self: @ContractState) -> u256 {
            let supply: u256 = self.erc20.total_supply();
            if (supply == 0 || self.total_assets() == 0) {
                constants::DECIMAL
            } else {
                mul_div_down(supply, constants::DECIMAL, self.total_assets())
            }
        }

        fn eth_per_rbEth(self: @ContractState) -> u256 {
            let supply: u256 = self.erc20.total_supply();
            if (supply == 0 || self.total_assets() == 0) {
                constants::DECIMAL
            } else {
                mul_div_down(self.total_assets(), constants::DECIMAL, supply)
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

        fn _withdraw_all_from_auto_comp(ref self: ContractState) -> u256 {
            let auto_comp_dispatcher: IERC4626Dispatcher = IERC4626Dispatcher {
                contract_address: self.auto_compound_vault.read()
            };
            let total_shares = auto_comp_dispatcher.balance_of(get_contract_address());
            let asset = auto_comp_dispatcher
                .redeem(total_shares, get_contract_address(), get_contract_address());
            return asset;
        }


        // TODO
        // deposit to  CL vault.
        fn _deposit_to_cl(ref self: ContractState, assets: u256,) {
            let CLVault = ICLVaultDispatcher { contract_address: self.cl_vault.read() };
            let (a, b) = CLVault.split_primary_token(assets);
            let amount_to_swap = (assets - a);
            let balance_secondary_before = IERC20Dispatcher {
                contract_address: constants::wstETH()
            }
                .balance_of(get_contract_address());
            self._swap(amount_to_swap, true);
            let balance_secondary_after = IERC20Dispatcher { contract_address: constants::wstETH() }
                .balance_of(get_contract_address());
            let t = balance_secondary_after - balance_secondary_before;
            let (sqrtRatioA, sqrtRatioB, sqrtRatioCurrent) = CLVault.get_sqrt_values();
            let mut primary_amount = a;
            if (t < b) {
                let liquidity_t = t / (sqrtRatioB.into() - sqrtRatioCurrent.into());
                primary_amount = liquidity_t / (sqrtRatioCurrent.into() - sqrtRatioA.into());
            }
            ERC20Helper::strict_transfer_from(
                constants::ETH(), get_caller_address(), self.cl_vault.read(), primary_amount
            );
            ERC20Helper::strict_transfer_from(
                constants::wstETH(), get_caller_address(), self.cl_vault.read(), t
            );
            let shares = CLVault.provide_liquidity(primary_amount, t, get_contract_address());
        }

        // TODO
        // withdraw from CL
        fn _withdraw_all_from_cl(ref self: ContractState) -> (u256, u256) {
            let CLVault = ICLVaultDispatcher { contract_address: self.cl_vault.read() };
            let auto_vault_net_liquidity = IERC20Dispatcher {
                contract_address: CLVault.get_cl_token()
            }
                .balance_of(get_contract_address());
            let (primary_token_amount, secondary_token_amount) = CLVault
                .remove_liquidity(auto_vault_net_liquidity, get_contract_address());
            return (primary_token_amount, secondary_token_amount);
        }

        fn _withdraw_from_cl(ref self: ContractState, assets: u256,) -> u256 {
            let CLVault = ICLVaultDispatcher { contract_address: self.cl_vault.read() };
            let (sqrtRatioA, sqrtRatioB, sqrtRatioCurrent) = CLVault.get_sqrt_values();
            let liquidity_x = assets / (sqrtRatioCurrent.into() - sqrtRatioA.into());
            let (primary_token_amount, secondary_token_amount) = CLVault
                .remove_liquidity(liquidity_x, get_contract_address());
            // Swap
            let mut amount_primary_received = 0;
            if (primary_token_amount != 0 && secondary_token_amount != 0) {
                // Swap secondary for Primary
                amount_primary_received = self._swap(secondary_token_amount, false);
            };
            if (primary_token_amount == 0) {
                amount_primary_received = self._swap(secondary_token_amount, false);
            }
            return amount_primary_received + primary_token_amount;
        }

        fn _erc20_camel(self: @ContractState) -> IERC20CamelDispatcher {
            IERC20CamelDispatcher { contract_address: self.token.read() }
        }

        fn _swap(
            ref self: ContractState, amount: u256, to_secondary: bool // ETH to wstETH ?
        ) -> u256 {
            let mut from_adress: ContractAddress = constants::ETH();
            let mut to_address: ContractAddress = constants::wstETH();
            let mut from_amount = amount;
            let mut to_amount = 0;
            let mut min_amount = 0;
            if (!to_secondary) {
                from_adress = constants::wstETH();
                to_address = constants::ETH();
                to_amount = amount;
                from_amount = 0;
            };

            let route: Route = Route {
                token_from: from_adress,
                token_to: to_address,
                exchange_address: constants::NOSTRA_EXCHANGE(),
                percent: 1000000000000,
                additional_swap_params: array![constants::NOSTRA_PAIR().try_into().unwrap()],
            };

            let swapInfo: AvnuMultiRouteSwap = AvnuMultiRouteSwap {
                token_from_address: from_adress,
                token_from_amount: from_amount,
                token_to_address: to_address,
                token_to_amount: to_amount,
                token_to_min_amount: 0,
                beneficiary: get_contract_address(),
                integrator_fee_amount_bps: 0,
                integrator_fee_recipient: get_contract_address(),
                routes: array![route]
            };

            return swapInfo.swap();
        }
    }
}

