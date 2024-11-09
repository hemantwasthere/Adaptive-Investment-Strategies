use starknet::{ContractAddress, ClassHash};
use strategies::interfaces::IEkuboCore::{PositionKey, Bounds, PoolKey};
use ekubo::types::position::Position;
// use strategies::interfaces::ERC4626Strategy::{IStrategy, Settings, Harvest};




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

#[starknet::interface]
pub trait ICLVault<TContractState> {
    fn provide_liquidity(
        ref self: TContractState,
        primary_token_amount: u256,
        secondary_token_amount: u256,
        receiver: ContractAddress
    ) -> u256;
    fn remove_liquidity(
        ref self: TContractState, liquidity: u256, receiver: ContractAddress
    ) -> (u256, u256);
    fn get_position_key(self: @TContractState) -> PositionKey;
    fn get_position(self: @TContractState) -> Position;
    fn get_sqrt_values(self: @TContractState) -> (u128, u128, u128);
    fn handle_fees(ref self: TContractState, sqrtA: u128, sqrtB: u128, sqrtCurrent: u128);
    fn getSettings(self: @TContractState) -> Settings;
    fn get_cl_token(self: @TContractState) -> ContractAddress;
    fn get_price(self: @TContractState, sqrtRatio: u256) -> u256;
    fn split_primary_token(self: @TContractState, primary_token_amount: u256) -> (u256, u256);

    fn position_rebalance(ref self: TContractState, new_bounds: Bounds);
}
