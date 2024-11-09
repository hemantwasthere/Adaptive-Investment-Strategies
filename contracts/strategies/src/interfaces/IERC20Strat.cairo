use starknet::{ContractAddress};

#[starknet::interface]
pub trait IERC20Strat<TContractState> {
    fn mint(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn burn(ref self: TContractState, account: ContractAddress, amount: u256) -> bool;
}
