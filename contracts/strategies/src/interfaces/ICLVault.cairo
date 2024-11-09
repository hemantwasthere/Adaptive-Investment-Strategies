use starknet::{ContractAddress, ClassHash};
use strategies::interfaces::IEkuboCore::{Bounds, PoolKey, PositionKey};
use ekubo::types::position::Position;
use strategies::interfaces::ERC4626Strategy::{IStrategy, Settings, Harvest};

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
    fn position_rebalance(ref self: TContractState, new_bounds: Bounds);
    fn split_primary_token(self: @TContractState, primary_token_amount: u256) -> (u256, u256);
}
