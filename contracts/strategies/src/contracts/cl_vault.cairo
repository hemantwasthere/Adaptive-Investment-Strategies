#[starknet::contract]
mod CLVault {
    use strategies::interfaces::ICLVault::ICLVault;
    use strategies::interfaces::IERC20Strat::{IERC20StratDispatcher, IERC20StratDispatcherTrait};
    use strategies::interfaces::IEkuboCore::{IEkuboCoreDispatcher, IEkuboCoreDispatcherTrait};
    use strategies::interfaces::IEkuboCore::{Bounds, PoolKey, PositionKey};
    use strategies::interfaces::IEkuboPositions::{IEkuboDispatcher, IEkuboDispatcherTrait};
    use strategies::interfaces::IEkuboNFT::{IEkuboNFTDispatcher, IEkuboNFTDispatcherTrait};
    use strategies::interfaces::IOracle::{
        IPriceOracle, IPriceOracleDispatcher, IPriceOracleDispatcherTrait, PriceWithUpdateTime
    };
    use ekubo::types::position::Position;
    use strategies::utils::math::Math;
    use strategies::utils::helpers::ERC20Helper;
    use strategies::utils::errors::Errors;
    // use strategies::utils::constants::Constants::{DECIMALS, ETH, wstETH};
    // use strategies::utils::constants::{TWO_POWER_128};
    use strategies::utils::constants;

    use openzeppelin::token::erc721::interface::{ERC721ABIDispatcher, ERC721ABIDispatcherTrait};
    use strategies::components::swap::{AvnuMultiRouteSwap, AvnuMultiRouteSwapImpl, Route};
    // use openzeppelin::introspection::src5::SRC5Component;
    // use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};


    use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    // ERC20 Mixin
    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;


    use core::traits::{TryInto, Into};
    use core::array::ArrayTrait;
    use starknet::{ClassHash, ContractAddress, get_caller_address, get_contract_address};
    use strategies::interfaces::ERC4626Strategy::Settings;
    // component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    // component!(path: SRC5Component, storage: src5, event: SRC5Event);

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        admin: ContractAddress,
        primary_token: ContractAddress,
        secondary_token: ContractAddress,
        ekubo_positions_contract: ContractAddress,
        bounds_settings: Bounds,
        pool_key: PoolKey,
        ekubo_positions_nft: ContractAddress,
        contract_nft_id: u64,
        ekubo_core: ContractAddress,
        oracle: ContractAddress,
        cl_token: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
    }


    #[constructor]
    fn constructor(
        ref self: ContractState,
        asset: ContractAddress,
        name: ByteArray,
        symbol: ByteArray,
        offset: u8,
        owner: ContractAddress,
        primary_token: ContractAddress,
        secondary_token: ContractAddress,
        ekubo_positions_contract: ContractAddress,
        bounds_settings: Bounds,
        pool_key: PoolKey,
        ekubo_positions_nft: ContractAddress,
        ekubo_core: ContractAddress,
        oracle: ContractAddress,
        cl_token: ContractAddress,
        admin: ContractAddress,
    ) {
        self.primary_token.write(primary_token);
        self.secondary_token.write(secondary_token);
        self.ekubo_positions_contract.write(ekubo_positions_contract);
        self.bounds_settings.write(bounds_settings);
        self.pool_key.write(pool_key);
        self.ekubo_positions_nft.write(ekubo_positions_nft);
        self.ekubo_core.write(ekubo_core);
        self.oracle.write(oracle);
        self.cl_token.write(cl_token);
        self.admin.write(admin);
    }

    #[abi(embed_v0)]
    impl CLVaultImpl of ICLVault<ContractState> {
        fn provide_liquidity(
            ref self: ContractState,
            primary_token_amount: u256,
            secondary_token_amount: u256,
            receiver: ContractAddress
        ) -> u256 {
            assert(primary_token_amount > 0, 'Invalid amount');
            assert(secondary_token_amount > 0, 'Invalid amount');
            assert(!receiver.is_zero(), 'Zero address');
            let liquidity = self._calculate_liquidity(primary_token_amount, secondary_token_amount);
            self._deposit(get_caller_address(), receiver, liquidity);
            IERC20StratDispatcher { contract_address: self.get_cl_token() }
                .mint(receiver, liquidity);
            return liquidity;
        }

        fn remove_liquidity(
            ref self: ContractState, liquidity: u256, receiver: ContractAddress
        ) -> (u256, u256) {
            assert(!receiver.is_zero(), 'Zero address');
            let cl_token = self.get_cl_token();
            let caller = get_caller_address();
            let user_liquidity = IERC20Dispatcher { contract_address: cl_token }.balance_of(caller);
            assert(user_liquidity >= liquidity, 'Not enough liquidity');
            let (primary_token_amount, secondary_token_amount) = self
                ._calcualte_tokens_amount(liquidity);
            self._withdraw(caller, receiver, liquidity);
            IERC20StratDispatcher { contract_address: self.get_cl_token() }.burn(caller, liquidity);
            return (primary_token_amount, secondary_token_amount);
        }

        fn get_position_key(self: @ContractState) -> PositionKey {
            let position_key = PositionKey {
                salt: self.contract_nft_id.read(),
                owner: get_contract_address(),
                bounds: self.bounds_settings.read()
            };

            position_key
        }

        // fn position_rebalance(ref self: ContractState, new_bounds: Bounds) {
        //     self._assert_only_admin();
        //     // Check if rebalancing is needed or not
        //     let (sqrtRatioA, sqrtRatioB, sqrtRatioCurrent) = self.get_sqrt_values();
        //     assert(
        //         sqrtRatioCurrent <= sqrtRatioA || sqrtRatioCurrent >= sqrtRatioB,
        //         'Rebalance not required'
        //     );
        //     // Withdraw the position ( Total Liquidity )
        //     let position = self.get_position();
        //     let liquidity = position.liquidity;
        //     let disp = ERC721ABIDispatcher { contract_address: self.ekubo_positions_nft.read() };
        //     let position_nft_id_u256: u256 = (self.contract_nft_id.read()).into();
        //     assert(
        //         disp.owner_of(position_nft_id_u256) == get_contract_address(),
        //         'Owner is not CLVault'
        //     );

        //     IEkuboDispatcher { contract_address: self.ekubo_positions_contract.read() }
        //         .withdraw(
        //             self.contract_nft_id.read(),
        //             self.pool_key.read(),
        //             self.bounds_settings.read(),
        //             liquidity,
        //             0x00,
        //             0x00,
        //             true
        //         );
        //     // @note-question >> Do I need to burn NFT
        //     // Check which amount is now zero is token a or token b
        //     let primary_balanee = IERC20Dispatcher { contract_address: constants::ETH() }
        //         .balance_of(get_caller_address());
        //     let secondary_balanee = IERC20Dispatcher { contract_address: constants::wstETH() }
        //         .balance_of(get_caller_address());

        //     if (sqrtRatioCurrent <= sqrtRatioA) { // Amount of secondary is zero
        //         // Split this amount and do swap
        //         let (a, b) = self.split_primary_token(primary_balanee);
        //         let amount_to_swap = primary_balanee - a;
        //         let amount_receive = _swap(amount_to_swap, true);
        //     } else { // Amount of token a is zero
        //     // Split this amount and do swap
        //     }
        //     // @note >> Once swap is ready, using above conditions get primary_token_amount and
        //     // secondary_token_amount Update the new bounds
        //     self.bounds_settings.write(new_bounds);
        //     // Calculate new liquidity
        //     let new_liquidity = self
        //         ._calculate_liquidity(primary_token_amount, secondary_token_amount);
        //     // Approve the EKubo Position contract

        //     // Use transfer
        //     // deposit in new range
        //     IEkuboDispatcher { contract_address: ekubo_positions_ctr }
        //         .deposit(
        //             position_nft_id_u256.into(),
        //             self.pool_key.read(),
        //             self.bounds_settings.read(),
        //             (new_liquidity - 100)
        //         );
        // }

        fn get_position(self: @ContractState) -> Position {
            let position_key: PositionKey = self.get_position_key();
            let curr_position: Position = IEkuboCoreDispatcher {
                contract_address: self.ekubo_core.read()
            }
                .get_position(self.pool_key.read(), position_key);

            curr_position
        }

        fn get_sqrt_values(self: @ContractState) -> (u128, u128, u128) {
            let bounds = self.bounds_settings.read();
            let sqrtRatioA = bounds.lower.mag;
            let sqrtRatioB = bounds.upper.mag;
            let sqrtRatioCurrent = IEkuboCoreDispatcher { contract_address: self.ekubo_core.read() }
                .get_pool_price(self.pool_key.read());

            (sqrtRatioA, sqrtRatioB, sqrtRatioCurrent)
        }

        // fn getSettings(self: @ContractState) -> Settings {
        //     Settings {
        //         asset: self.get_cl_token(),
        //         primary_token: self.primary_token.read(),
        //         secondary_token: self.secondary_token.read(),
        //         ekubo_positions_contract: self.ekubo_positions_contract.read(),
        //         bounds_settings: self.bounds_settings.read(),
        //         pool_key: self.pool_key.read(),
        //         ekubo_positions_nft: self.ekubo_positions_nft.read(),
        //         contract_nft_id: self.contract_nft_id.read(),
        //         ekubo_core: self.ekubo_core.read(),
        //         oracle: self.oracle.read()
        //     }
        // }

        fn get_cl_token(self: @ContractState) -> ContractAddress {
            return self.cl_token.read();
        }

        fn get_price(self: @ContractState, sqrtRatio: u256) -> u256 {
            assert(sqrtRatio > 0, 'Invalid sqrtRatio');
            // Price = ( sqrtRatio / 2**128 )**2
            let price = sqrtRatio / (constants::TWO_POWER_128).into();
            return (price * price);
        }

        fn split_primary_token(self: @ContractState, primary_token_amount: u256) -> (u256, u256) {
            let (sqrtRatioA, sqrtRatioB, sqrtRatioCurrent) = self.get_sqrt_values();
            let a_primary = primary_token_amount
                * (sqrtRatioB.into() - sqrtRatioCurrent.into())
                / (sqrtRatioB.into() - sqrtRatioA.into());
            let b_secondary = (primary_token_amount - a_primary)
                / self.get_price(sqrtRatioCurrent.into());
            return (a_primary, b_secondary);
        }

        fn handle_fees(ref self: ContractState, sqrtA: u128, sqrtB: u128, sqrtCurrent: u128) {
            let this: ContractAddress = get_contract_address();
            let tokenA: ContractAddress = self.primary_token.read();
            let tokenB: ContractAddress = self.secondary_token.read();
            let oracle_disp = IPriceOracleDispatcher { contract_address: self.oracle.read() };
            let priceA = oracle_disp.get_price(tokenA);
            let priceA_u256: u256 = priceA.into();
            let priceB = oracle_disp.get_price(tokenB);
            let priceB_u256: u256 = priceB.into();
            IEkuboDispatcher { contract_address: self.ekubo_positions_contract.read() }
                .collect_fees(
                    self.contract_nft_id.read(), self.pool_key.read(), self.bounds_settings.read()
                );
            let ethValue: u256 = ERC20Helper::balanceOf(tokenA, this);
            let wstEthValue: u256 = ERC20Helper::balanceOf(tokenB, this);
            let (x, y) = Math::calculateFeesXandY(
                ethValue, wstEthValue, sqrtA, sqrtB, sqrtCurrent, priceA_u256, priceB_u256
            );
            ERC20Helper::strict_transfer_from(
                self.primary_token.read(), this, self.ekubo_positions_contract.read(), x
            );
            ERC20Helper::strict_transfer_from(
                self.secondary_token.read(), this, self.ekubo_positions_contract.read(), y
            );
            IEkuboDispatcher { contract_address: self.ekubo_positions_contract.read() }
                .mint_and_deposit(self.pool_key.read(), self.bounds_settings.read(), 100);
        }
    }

    #[generate_trait]
    impl CLVaultInternal of CLVaultInternalTrait {
        fn _calculate_liquidity(
            self: @ContractState, token_x_amount: u256, token_y_amount: u256
        ) -> u256 {
            let (sqrtRatioA, sqrtRatioB, sqrtRatioCurrent) = self.get_sqrt_values();
            let liquidity_x = token_x_amount / (sqrtRatioCurrent.into() - sqrtRatioA.into());
            let liquidity_y = token_y_amount / (sqrtRatioB.into() - sqrtRatioCurrent.into());
            let net_liquidity = Math::min(
                liquidity_x.try_into().unwrap(), liquidity_y.try_into().unwrap()
            );
            return net_liquidity.into();
        }

        fn _calcualte_tokens_amount(self: @ContractState, liquidity: u256) -> (u256, u256) {
            let _liquidity: u128 = liquidity.try_into().unwrap();
            let (sqrtRatioA, sqrtRatioB, sqrtRatioCurrent) = self.get_sqrt_values();
            let (x, y) = Math::calculateXandY(_liquidity, sqrtRatioA, sqrtRatioB, sqrtRatioCurrent);
            return (x, y);
        }

        fn _deposit(
            ref self: ContractState,
            caller: ContractAddress,
            receiver: ContractAddress,
            assets: u256,
        ) {
            let this: ContractAddress = get_contract_address();
            let ekubo_positions_ctr = self.ekubo_positions_contract.read();
            assert(assets > 0, 'Liquidity added cannot be zero');
            let liquidity: u128 = assets.try_into().unwrap();
            let (sqrtRatioA, sqrtRatioB, sqrtRatioCurrent) = self.get_sqrt_values();
            let (x, y) = Math::calculateXandY(liquidity, sqrtRatioA, sqrtRatioB, sqrtRatioCurrent);
            let ctr_primary_token = self.primary_token.read();
            let ctr_secondary_token = self.secondary_token.read();
            assert(
                ERC20Helper::balanceOf(ctr_primary_token, caller) >= x, 'Not enough ETH in caller'
            );
            assert(
                ERC20Helper::balanceOf(ctr_secondary_token, caller) >= y,
                'Not enough wstETH in caller'
            );
            ERC20Helper::strict_transfer_from(ctr_primary_token, caller, ekubo_positions_ctr, x);
            ERC20Helper::strict_transfer_from(ctr_secondary_token, caller, ekubo_positions_ctr, y);
            let ctr_nft_id = self.contract_nft_id.read();
            if (ctr_nft_id == 0) {
                let nft_id: u64 = IEkuboNFTDispatcher {
                    contract_address: self.ekubo_positions_nft.read()
                }
                    .get_next_token_id();
                self.contract_nft_id.write(nft_id);
            }
            let curr_position_before_deposit: Position = self.get_position();
            let disp = ERC721ABIDispatcher { contract_address: self.ekubo_positions_nft.read() };
            let contract_nft_id_u256: u256 = ctr_nft_id.into();
            assert(disp.owner_of(contract_nft_id_u256) == this, 'Owner not CLVault');
            self.handle_fees(sqrtRatioA, sqrtRatioB, sqrtRatioCurrent);
            // @note-anubhav >> Missing approval to Ekubo Position contract
            IEkuboDispatcher { contract_address: ekubo_positions_ctr }
                .mint_and_deposit(
                    self.pool_key.read(), self.bounds_settings.read(), (liquidity - 100)
                );
            let curr_position_after_deposit: Position = self.get_position();
            assert(
                curr_position_after_deposit.liquidity
                    - curr_position_before_deposit.liquidity == liquidity,
                'Invalid liquidity added'
            );
        }

        fn _withdraw(
            ref self: ContractState,
            caller: ContractAddress,
            receiver: ContractAddress,
            assets: u256,
        ) {
            let this: ContractAddress = get_contract_address();
            assert(assets > 0, 'Liquidity remove cannot be zero');
            let liquidity: u128 = assets.try_into().unwrap();
            let curr_position_before_withdraw: Position = self.get_position();
            let disp = ERC721ABIDispatcher { contract_address: self.ekubo_positions_nft.read() };
            let ctr_nft_id = self.contract_nft_id.read();
            let contract_nft_id_u256: u256 = ctr_nft_id.into();
            assert(disp.owner_of(contract_nft_id_u256) == this, 'Owner is not CLVault');
            let (sqrtRatioA, sqrtRatioB, sqrtRatioCurrent) = self.get_sqrt_values();
            self.handle_fees(sqrtRatioA, sqrtRatioB, sqrtRatioCurrent);
            IEkuboDispatcher { contract_address: self.ekubo_positions_contract.read() }
                .withdraw(
                    ctr_nft_id,
                    self.pool_key.read(),
                    self.bounds_settings.read(),
                    liquidity,
                    0x00,
                    0x00,
                    true
                );
            let curr_position_after_withdraw: Position = self.get_position();
            assert(
                curr_position_before_withdraw.liquidity
                    - curr_position_after_withdraw.liquidity == liquidity,
                'Invalid liquidity removed'
            );
            let nft_balance: u256 = disp.balanceOf(this);
            if (nft_balance == 0) {
                self.contract_nft_id.write(0);
            }
            let ctr_primary_token = self.primary_token.read();
            let ctr_secondary_token = self.secondary_token.read();
            ERC20Helper::strict_transfer_from(
                ctr_primary_token, this, receiver, ERC20Helper::balanceOf(ctr_primary_token, this)
            );
            ERC20Helper::strict_transfer_from(
                ctr_secondary_token,
                this,
                receiver,
                ERC20Helper::balanceOf(ctr_secondary_token, this)
            );
            assert(ERC20Helper::balanceOf(ctr_primary_token, this) == 0, 'Invalid ETH removed');
            assert(
                ERC20Helper::balanceOf(ctr_secondary_token, this) == 0, 'Invalid wstETH removed'
            );
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


        fn _assert_only_admin(self: @ContractState) {
            assert(get_caller_address() == self.admin.read(), 'Not Authorized');
        }
    }
}

