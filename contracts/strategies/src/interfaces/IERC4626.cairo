use starknet::ContractAddress;

#[starknet::interface]
pub trait IERC4626<TContractState> {
    // ************************************
    // * Metadata
    // ************************************
    fn name(self: @TContractState) -> ByteArray;
    fn symbol(self: @TContractState) -> ByteArray;
    fn decimals(self: @TContractState) -> u8;

    // ************************************
    // * snake_case
    // ************************************
    fn total_supply(self: @TContractState) -> u256;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;

    // ************************************
    // * camelCase
    // ************************************
    fn totalSupply(self: @TContractState) -> u256;
    fn balanceOf(self: @TContractState, account: ContractAddress) -> u256;
    fn transferFrom(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;

    // ************************************
    // * Additional functions
    // ************************************
    fn asset(self: @TContractState) -> starknet::ContractAddress;
    fn convert_to_assets(self: @TContractState, shares: u256) -> u256;
    fn convert_to_shares(self: @TContractState, assets: u256) -> u256;
    fn deposit(ref self: TContractState, assets: u256, receiver: starknet::ContractAddress) -> u256;
    fn max_deposit(self: @TContractState, address: starknet::ContractAddress) -> u256;
    fn max_mint(self: @TContractState, receiver: starknet::ContractAddress) -> u256;
    fn max_redeem(self: @TContractState, owner: starknet::ContractAddress) -> u256;
    fn max_withdraw(self: @TContractState, owner: starknet::ContractAddress) -> u256;
    fn mint(ref self: TContractState, shares: u256, receiver: starknet::ContractAddress) -> u256;
    fn preview_deposit(self: @TContractState, assets: u256) -> u256;
    fn preview_mint(self: @TContractState, shares: u256) -> u256;
    fn preview_redeem(self: @TContractState, shares: u256) -> u256;
    fn preview_withdraw(self: @TContractState, assets: u256) -> u256;
    fn redeem(
        ref self: TContractState,
        shares: u256,
        receiver: starknet::ContractAddress,
        owner: starknet::ContractAddress
    ) -> u256;
    fn total_assets(self: @TContractState) -> u256;
    fn withdraw(
        ref self: TContractState,
        assets: u256,
        receiver: starknet::ContractAddress,
        owner: starknet::ContractAddress
    ) -> u256;
}

