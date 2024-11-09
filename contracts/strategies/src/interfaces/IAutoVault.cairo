use starknet::{ContractAddress, ClassHash};

#[starknet::interface]
pub trait IAutoVault<TContractState> {
    fn deposit(ref self: TContractState, assets: u256, receiver: ContractAddress) -> u256;
    fn mint(ref self: TContractState, shares: u256, receiver: ContractAddress) -> u256;
    fn redeem(
        ref self: TContractState, shares: u256, receiver: ContractAddress, owner: ContractAddress
    ) -> u256;
    fn withdraw(
        ref self: TContractState, assets: u256, receiver: ContractAddress, owner: ContractAddress
    ) -> u256;
    fn preview_deposit(self: @TContractState, assets: u256) -> u256;
    fn preview_withdraw(self: @TContractState, assets: u256) -> u256;
    fn preview_mint(self: @TContractState, shares: u256) -> u256;
    fn preview_redeem(self: @TContractState, shares: u256) -> u256;
    fn convert_to_assets(self: @TContractState, shares: u256) -> u256;
    fn convert_to_shares(self: @TContractState, assets: u256) -> u256;
    fn total_assets(self: @TContractState) -> u256;

    fn rebalance(ref self: TContractState, _mode: u8);
    fn lending_assets(self: @TContractAddress) -> u256;
    fn dex_assets(self: @TContractAddress) -> u256;
}
