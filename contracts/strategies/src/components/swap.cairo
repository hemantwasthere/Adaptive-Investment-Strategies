use starknet::{ContractAddress, get_contract_address};
use strategies::utils::constants;
use openzeppelin_token::erc20::interface::{
    IERC20, IERC20Dispatcher, IERC20DispatcherTrait, ERC20ABIDispatcher, ERC20ABIDispatcherTrait
};


#[derive(Drop, Clone, Serde)]
pub struct Route {
    pub token_from: ContractAddress,
    pub token_to: ContractAddress,
    pub exchange_address: ContractAddress,
    pub percent: u128,
    pub additional_swap_params: Array<felt252>,
}

#[starknet::interface]
pub trait IAvnu<TContractState> {
    fn multi_route_swap(
        ref self: TContractState,
        token_from_address: ContractAddress,
        token_from_amount: u256,
        token_to_address: ContractAddress,
        token_to_amount: u256,
        token_to_min_amount: u256,
        beneficiary: ContractAddress,
        integrator_fee_amount_bps: u128,
        integrator_fee_recipient: ContractAddress,
        routes: Array<Route>,
    ) -> bool;
}

#[derive(Drop, Clone, Serde)]
pub struct AvnuMultiRouteSwap {
    pub token_from_address: ContractAddress,
    pub token_from_amount: u256,
    pub token_to_address: ContractAddress,
    pub token_to_amount: u256,
    pub token_to_min_amount: u256,
    pub beneficiary: ContractAddress,
    pub integrator_fee_amount_bps: u128,
    pub integrator_fee_recipient: ContractAddress,
    pub routes: Array<Route>
}

#[derive(Drop, Clone, Serde)]
pub struct SwapInfoMinusAmount {
    pub token_from_address: ContractAddress,
    pub token_to_address: ContractAddress,
    pub beneficiary: ContractAddress,
    pub integrator_fee_amount_bps: u128,
    pub integrator_fee_recipient: ContractAddress,
    pub routes: Array<Route>
}

// todo assert min price amount using oracle values
// else it could lead to an attacker using bad DEX instead during claim

#[generate_trait]
pub impl AvnuMultiRouteSwapImpl of AvnuMultiRouteSwapTrait {
    fn swap(self: AvnuMultiRouteSwap) -> u256 {
        avnuSwap(
            SwapInfoMinusAmount {
                token_from_address: self.token_from_address,
                token_to_address: self.token_to_address,
                beneficiary: self.beneficiary,
                integrator_fee_amount_bps: self.integrator_fee_amount_bps,
                integrator_fee_recipient: self.integrator_fee_recipient,
                routes: self.routes
            },
            self.token_from_amount,
            self.token_to_amount,
            self.token_to_min_amount
        )
    }
}


#[generate_trait]
pub impl SwapInfoMinusAmountImpl of SwapInfoMinusAmountTrait {
    fn swap(
        self: SwapInfoMinusAmount,
        token_from_amount: u256,
        token_to_amount: u256,
        token_to_min_amount: u256
    ) -> u256 {
        avnuSwap(self, token_from_amount, token_to_amount, token_to_min_amount)
    }
}

fn avnuSwap(
    swapInfo: SwapInfoMinusAmount,
    token_from_amount: u256,
    token_to_amount: u256,
    token_to_min_amount: u256
) -> u256 {
    let toToken = ERC20ABIDispatcher { contract_address: swapInfo.token_to_address };
    let this = get_contract_address();
    let pre_bal = toToken.balanceOf(this);

    assert(swapInfo.integrator_fee_amount_bps == 0, 'require avnu fee bps 0');
    assert(swapInfo.beneficiary == this, 'invalid swap beneficiary');

    let avnuAddress = constants::AVNU_EX();
    IERC20Dispatcher { contract_address: swapInfo.token_from_address }
        .approve(avnuAddress, token_from_amount);
    let swapped = IAvnuDispatcher { contract_address: avnuAddress }
        .multi_route_swap(
            swapInfo.token_from_address,
            token_from_amount,
            swapInfo.token_to_address,
            token_to_amount,
            token_to_min_amount,
            swapInfo.beneficiary,
            swapInfo.integrator_fee_amount_bps,
            swapInfo.integrator_fee_recipient,
            swapInfo.routes
        );
    assert(swapped, 'Swap failed');

    let post_bal = toToken.balanceOf(this);
    let amount = post_bal - pre_bal;
    assert(amount > 0, 'invalid to amount');

    amount
}
