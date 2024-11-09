use starknet::{ContractAddress, ClassHash};
use strategies::components::swap::{AvnuMultiRouteSwap};

#[derive(Drop, Copy, Serde)] 
pub struct Claim {
    pub id: u64,
    pub claimee: ContractAddress,
    pub amount: u128,
}


//
// Re-uses zkLend's oracle middleware contract to interact with
// Pragma. 
// https://github.com/zkLend/zklend-v1-core/blob/master/src/default_price_oracle.cairo
// 
// We deploy the came classhash of contract
// https://starkscan.co/contract/0x023fb3afbff2c0e3399f896dcf7400acf1a161941cfb386e34a123f228c62832#read-write-contract-sub-write
//

#[derive(Drop, Serde)]
pub struct PriceWithUpdateTime {
    price: felt252,
    update_time: felt252
}

#[starknet::interface]
pub trait IPriceOracle<TContractState> {
    /// Get the price of the token in USD with 8 decimals.
    fn get_price(self: @TContractState, token: ContractAddress) -> felt252;

    /// Get the price of the token in USD with 8 decimals and update timestamp.
    fn get_price_with_time(self: @TContractState, token: ContractAddress) -> PriceWithUpdateTime;
}

#[derive(Drop, Serde)]
pub enum PragmaDataType {
    SpotEntry: felt252,
    FutureEntry: (felt252, u64),
    GenericEntry: felt252,
}

#[derive(Drop, Serde)]
pub struct PragmaPricesResponse {
    pub price: u128,
    pub decimals: u32,
    pub last_updated_timestamp: u64,
    pub num_sources_aggregated: u32,
    expiration_timestamp: Option<u64>,
}

#[derive(Drop, Serde)]
pub enum SimpleDataType {
    SpotEntry: (),
    FutureEntry: (),
}

#[derive(Drop, Serde)]
pub enum AggregationMode {
    Median: (),
    Mean: (),
    Error: (),
}

#[starknet::interface]
pub trait IPragmaOracle<TContractState> {
    fn get_data_median(self: @TContractState, data_type: PragmaDataType) -> PragmaPricesResponse;
    fn get_data_with_USD_hop(
        self: @TContractState,
        base_currency_id: felt252,
        quote_currency_id: felt252,
        aggregation_mode: AggregationMode,
        typeof: SimpleDataType,
        expiration_timestamp: Option::<u64>
    ) -> PragmaPricesResponse;
    // fn set_mock_price()
}

#[starknet::interface]
pub trait IPragmaNostraMock<TContractState> {
    fn get_spot_median(self: @TContractState, pair_id: felt252) -> (felt252, felt252, felt252, felt252);
    fn get_spot_with_USD_hop(
        self: @TContractState,
        base_currency_id: felt252,
        quote_currency_id: felt252,
        aggregation_mode: felt252,
    ) -> (felt252, felt252, felt252, felt252);
}

#[derive(Drop, Serde, starknet::Store)]
pub struct MarketReserveData {
    pub enabled: bool,
    pub decimals: u8,
    pub z_token_address: ContractAddress,
    pub interest_rate_model: ContractAddress,
    pub collateral_factor: felt252,
    pub borrow_factor: felt252,
    pub reserve_factor: felt252,
    pub last_update_timestamp: felt252,
    pub lending_accumulator: felt252,
    pub debt_accumulator: felt252,
    pub current_lending_rate: felt252,
    pub current_borrowing_rate: felt252,
    pub raw_total_debt: felt252,
    pub flash_loan_fee: felt252,
    pub liquidation_bonus: felt252,
    pub debt_limit: felt252
}

#[starknet::interface]
pub trait IZkLendMarket<TContractState> {
    fn deposit(ref self: TContractState, token: ContractAddress, amount: felt252);
    fn withdraw(ref self: TContractState, token: ContractAddress, amount: felt252);
    fn enable_collateral(ref self: TContractState, token: ContractAddress);
    fn is_collateral_enabled(self: @TContractState, user: ContractAddress, token: ContractAddress) -> bool;
    fn borrow(ref self: TContractState, token: ContractAddress, amount: felt252);
    fn repay(ref self: TContractState, token: ContractAddress, amount: felt252);
    fn get_reserve_data(self: @TContractState, token: ContractAddress) -> MarketReserveData;
    fn get_user_debt_for_token(
        self: @TContractState, user: ContractAddress, token: ContractAddress
    ) -> felt252;
    fn flash_loan(
        ref self: TContractState, 
        receiver: ContractAddress, 
        token: ContractAddress,
        amount: felt252,
        calldata: Span<felt252>
    );
}

#[starknet::interface]
pub trait IZToken<TContractState> {
    fn underlying_token(self: @TContractState) -> ContractAddress;
}

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct zkLendStruct {
    pub zkLendRouter: IZkLendMarketDispatcher,
    pub oracle: IPriceOracleDispatcher,
}

#[derive(Drop, Copy, Serde, starknet::Event, starknet::Store)]
pub struct Settings {
    pub rewardsContract: ContractAddress, // distribution contract

    pub lendClassHash: ClassHash, // our lending lib contract classhash
    pub swapClassHash: ClassHash, // our swap lib contract classhash
}

#[derive(Drop, Copy, Serde, starknet::Event, starknet::Store)] 
pub struct Harvest {
    pub asset: ContractAddress, // e.g. STRk
    pub amount: u256,
    pub timestamp: u64
}

#[starknet::interface]
pub trait IStrategy<TContractState> {
    fn harvest(
        ref self: TContractState,
        claim: Claim, proof: Span<felt252>,
        swapInfo: AvnuMultiRouteSwap
    );
    fn set_settings(ref self: TContractState, settings: Settings, lend_settings: zkLendStruct);

    fn upgrade(ref self: TContractState, class_hash: ClassHash);

    //
    // view functions
    //

    fn get_settings(self: @TContractState) -> Settings;
}