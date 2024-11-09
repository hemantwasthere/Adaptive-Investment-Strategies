use starknet::{ContractAddress, get_caller_address, get_contract_address, ClassHash};
use strategies::interfaces::IEkuboCore::{Bounds, PoolKey};

#[starknet::interface]
pub trait IEkubo<TContractState> {
    fn mint_and_deposit(
        ref self: TContractState, pool_key: PoolKey, bounds: Bounds, min_liquidity: u128
    );

    fn deposit(
        ref self: TContractState, id: u256, pool_key: PoolKey, bounds: Bounds, min_liquidity: u128
    );

    fn withdraw(
        ref self: TContractState,
        id: u64,
        pool_key: PoolKey,
        bounds: Bounds,
        liquidity: u128,
        min_token: u128,
        min_token1: u128,
        collect_fees: bool
    );
    fn collect_fees(ref self: TContractState, id: u64, pool_key: PoolKey, bounds: Bounds);
}
