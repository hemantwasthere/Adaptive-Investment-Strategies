use starknet::ContractAddress;
use starknet::contract_address::contract_address_const;
use strategies::components::swap::{AvnuMultiRouteSwap, AvnuMultiRouteSwapImpl, Route};


pub mod Constants {
    pub const LENDING: u8 = 0;
    pub const DEX: u8 = 1;
    pub const DECIMALS: u256 = 1000000000000000000; // 18 Decimal units
}


pub const BASIS_POINTS_FACTOR: u32 = 10000;
pub const TWO_POWER_128: u128 = 0xffffffffffffffffffffffffffffffff;
pub const TWO_POWER_256: u256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

// mainnet address
pub fn STRK_ADDRESS() -> ContractAddress {
    contract_address_const::<0x4718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d>()
}

pub fn AVNU_EX() -> ContractAddress {
    contract_address_const::<0x04270219d365d6b017231b52e92b3fb5d7c8378b05e9abc97724537a80e93b0f>()
}

// ETH-wstETH Pair
pub fn NOSTRA_PAIR() -> ContractAddress {
    contract_address_const::<>
    0x0577521a1f005bd663d0fa7f37f0dbac4d7f55b98791d280b158346d9551ff2b
    ()
}

pub fn ETH() -> ContractAddress {
    contract_address_const::<>
    0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
    ()
}

pub fn wstETH() -> ContractAddress {
    contract_address_const::<>
    0x042b8f0484674ca266ac5d08e4ac6a3fe65bd3129795def2dca5c34ecc5f96d2
    ()
}

pub fn NOSTRA_EXCHANGE() -> ContractAddress {
    contract_address_const::<>
    0x49ff5b3a7d38e2b50198f408fa8281635b5bc81ee49ab87ac36c8324c214427
    ()
}

