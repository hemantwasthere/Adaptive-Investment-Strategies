#[starknet::contract]
mod CLVault {
    use strategies::interfaces::ICLVault::ICLVault;
    use strategies::interfaces::IERC20Strat::{IERC20StratDispatcher, IERC20StratDispatcherTrait};
    use strategies::interfaces::IEkuboCore::{
        IEkuboCoreDispatcher, IEkuboCoreDispatcherTrait, Bounds, PoolKey, PositionKey
    };
    use ekubo::types::position::Position;
    use strategies::utils::math::Math;
    use strategies::utils::helpers::ERC20Helper;
    use strategies::utils::errors::Errors;
    use strategies::utils::constants::Constants::{LENDING, DEX, DECIMALS};
    use openzeppelin::token::erc721::interface::{ERC721ABIDispatcher, ERC721ABIDispatcherTrait};
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};


    use core::traits::{TryInto, Into};
    use core::array::ArrayTrait;
    use starknet::{ClassHash, ContractAddress, get_caller_address, get_contract_address};

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    #[derive(Drop, Copy, Serde, starknet::Store)]
    pub struct Settings {
        pub asset: ContractAddress,
        pub primary_token: ContractAddress,
        pub secondary_token: ContractAddress,
        pub ekubo_positions_contract: ContractAddress,
        pub bounds_settings: Bounds,
        pub pool_key: PoolKey,
        pub ekubo_positions_nft: ContractAddress,
        pub contract_nft_id: u64,
        pub ekubo_core: ContractAddress,
        pub oracle: ContractAddress
    }

    #[storage]
    struct Storage {
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
        cl_token: ContractAddress
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
    }

    #[abi(embed_v0)]
    impl CLVaultImpl of CLVault<ContractState> {
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

        fn get_position_key(ref self: ContractState) -> PositionKey {
            let position_key = PositionKey {
                salt: self.contract_nft_id.read(),
                owner: get_contract_address(),
                bounds: self.bounds_settings.read()
            };

            position_key
        }

        fn get_position(ref self: ContractState) -> Position {
            let position_key: PositionKey = self.get_position_key();
            let curr_position: Position = IEkuboCoreDispatcher {
                contract_address: self.ekubo_core.read()
            }
                .get_position(self.pool_key.read(), position_key);

            curr_position
        }

        fn get_sqrt_values(ref self: ContractState) -> (u128, u128, u128) {
            let bounds = self.bounds_settings.read();
            let sqrtRatioA = bounds.lower.mag;
            let sqrtRatioB = bounds.upper.mag;
            let sqrtRatioCurrent = IEkuboCoreDispatcher { contract_address: self.ekubo_core.read() }
                .get_pool_price(self.pool_key.read());

            (sqrtRatioA, sqrtRatioB, sqrtRatioCurrent)
        }

        fn getSettings(self: @ContractState) -> Settings {
            Settings {
                asset: self.asset(),
                primary_token: self.primary_token.read(),
                secondary_token: self.secondary_token.read(),
                ekubo_positions_contract: self.ekubo_positions_contract.read(),
                bounds_settings: self.bounds_settings.read(),
                pool_key: self.pool_key.read(),
                ekubo_positions_nft: self.ekubo_positions_nft.read(),
                contract_nft_id: self.contract_nft_id.read(),
                ekubo_core: self.ekubo_core.read(),
                oracle: self.oracle.read()
            }
        }

        fn get_cl_token(self: @ContractState) -> ContractAddress {
            return self.cl_token.read();
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
            let liquidity_x = token_x_amount / (sqrtRatioCurrent - sqrtRatioA);
            let liquidity_y = token_y_amount / (sqrtRatioB - sqrtRatioCurrent);
            let net_liquidity = Math::min(liquidity_x.into(), liquidity_y.into());
            return net_liquidity.into();
        }

        fn _calcualte_tokens_amount(self: @ContractState, liquidity: u256) -> (u256, u256) {
            let _liquidity: u128 = liquidity.try_into().unwrap();
            let (sqrtRatioA, sqrtRatioB, sqrtRatioCurrent) = contract_state.get_sqrt_values();
            let (x, y) = Math::calculateXandY(_liquidity, sqrtRatioA, sqrtRatioB, sqrtRatioCurrent);
            return (x, y);
        }

        fn _deposit(
            ref self: ERC4626Component::ComponentState<ContractState>,
            caller: ContractAddress,
            receiver: ContractAddress,
            assets: u256,
        ) {
            let this: ContractAddress = get_contract_address();
            let mut contract_state = self.get_contract_mut();
            let ekubo_positions_ctr = contract_state.ekubo_positions_contract.read();
            assert(assets > 0, 'Liquidity added cannot be zero');
            let liquidity: u128 = assets.try_into().unwrap();
            let (sqrtRatioA, sqrtRatioB, sqrtRatioCurrent) = contract_state.get_sqrt_values();
            let (x, y) = Math::calculateXandY(liquidity, sqrtRatioA, sqrtRatioB, sqrtRatioCurrent);
            let ctr_primary_token = contract_state.primary_token.read();
            let ctr_secondary_token = contract_state.secondary_token.read();
            assert(
                ERC20Helper::balanceOf(ctr_primary_token, caller) >= x, 'Not enough ETH in caller'
            );
            assert(
                ERC20Helper::balanceOf(ctr_secondary_token, caller) >= y,
                'Not enough wstETH in caller'
            );
            ERC20Helper::strict_transfer_from(ctr_primary_token, caller, ekubo_positions_ctr, x);
            ERC20Helper::strict_transfer_from(ctr_secondary_token, caller, ekubo_positions_ctr, y);
            let ctr_nft_id = contract_state.contract_nft_id.read();
            if (ctr_nft_id == 0) {
                let nft_id: u64 = IEkuboNFTDispatcher {
                    contract_address: contract_state.ekubo_positions_nft.read()
                }
                    .get_next_token_id();
                contract_state.contract_nft_id.write(nft_id);
            }
            let curr_position_before_deposit: Position = contract_state.get_position();
            let disp = ERC721ABIDispatcher {
                contract_address: contract_state.ekubo_positions_nft.read()
            };
            let contract_nft_id_u256: u256 = ctr_nft_id.into();
            assert(disp.owner_of(contract_nft_id_u256) == this, 'Owner not CLVault');
            contract_state.handle_fees(sqrtRatioA, sqrtRatioB, sqrtRatioCurrent);
            IEkuboDispatcher { contract_address: ekubo_positions_ctr }
                .mint_and_deposit(
                    contract_state.pool_key.read(),
                    contract_state.bounds_settings.read(),
                    (liquidity - 100)
                );
            let curr_position_after_deposit: Position = contract_state.get_position();
            assert(
                curr_position_after_deposit.liquidity
                    - curr_position_before_deposit.liquidity == liquidity,
                'Invalid liquidity added'
            );
        }

        fn _withdraw(
            ref self: ERC4626Component::ComponentState<ContractState>,
            caller: ContractAddress,
            receiver: ContractAddress,
            assets: u256,
        ) {
            let this: ContractAddress = get_contract_address();
            let mut contract_state = self.get_contract_mut();
            assert(assets > 0, 'Liquidity remove cannot be zero');
            let liquidity: u128 = assets.try_into().unwrap();
            let curr_position_before_withdraw: Position = contract_state.get_position();
            let disp = ERC721ABIDispatcher {
                contract_address: contract_state.ekubo_positions_nft.read()
            };
            let ctr_nft_id = contract_state.contract_nft_id.read();
            let contract_nft_id_u256: u256 = ctr_nft_id.into();
            assert(disp.owner_of(contract_nft_id_u256) == this, 'Owner is not CLVault');
            let (sqrtRatioA, sqrtRatioB, sqrtRatioCurrent) = contract_state.get_sqrt_values();
            contract_state.handle_fees(sqrtRatioA, sqrtRatioB, sqrtRatioCurrent);
            IEkuboDispatcher { contract_address: contract_state.ekubo_positions_contract.read() }
                .withdraw(
                    ctr_nft_id,
                    contract_state.pool_key.read(),
                    contract_state.bounds_settings.read(),
                    liquidity,
                    0x00,
                    0x00,
                    true
                );
            let curr_position_after_withdraw: Position = contract_state.get_position();
            assert(
                curr_position_before_withdraw.liquidity
                    - curr_position_after_withdraw.liquidity == liquidity,
                'Invalid liquidity removed'
            );
            let nft_balance: u256 = disp.balanceOf(this);
            if (nft_balance == 0) {
                contract_state.contract_nft_id.write(0);
            }
            let ctr_primary_token = contract_state.primary_token.read();
            let ctr_secondary_token = contract_state.secondary_token.read();
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
    }
}

