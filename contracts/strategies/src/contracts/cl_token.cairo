#[starknet::contract]
mod CLToken {
    use strategies::interfaces::IERC20Strat::IERC20Strat;
    use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use starknet::{ContractAddress, get_caller_address};

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;

    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        cl_vault: ContractAddress,
        #[substorage(v0)]
        erc20: ERC20Component::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState, cl_vault: ContractAddress) {
        let name = "CLToken";
        let symbol = "CLT";
        self.erc20.initializer(name, symbol);
        self.cl_vault.write(cl_vault);
    }

    #[abi(embed_v0)]
    impl IERC20StratImpl of IERC20Strat<ContractState> {
        fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            self._assert_only_cl_vault();
            self.erc20.mint(recipient, amount);
            true
        }
        fn burn(ref self: ContractState, amount: u256) -> bool {
            self._assert_only_cl_vault();
            self.erc20.burn(get_caller_address(), amount);
            true
        }
    }

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        fn _assert_only_cl_vault(ref self: ContractState) {
            assert(self.cl_vault.read() == get_caller_address(), 'Only owner');
        }
    }
}
