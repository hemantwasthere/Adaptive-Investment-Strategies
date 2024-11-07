
#[starknet::contract]
mod AutoVault {

    #[storage]
    struct Storage {
        // balance: felt252, 
    }

    #[abi(embed_v0)]
    impl AutoVaultImpl of super::IAutoVault<ContractState> {
    
        #[constructor]
        fn constructor(
            ref self: ContractState,
            name: felt252,
            symbol: felt252,
            _hashstack_config: ContractAddress,
            _admin: ContractAddress
        ) {
            assert(!_hashstack_config.is_zero(), Errors::ZERO_ADDRESS);
            assert(!_admin.is_zero(), Errors::ZERO_ADDRESS);
            self.hashstack_config.write(_hashstack_config);
            self.accesscontrol.initializer();
            self._set_admin(_admin);
            self.accesscontrol._grant_role('DEFAULT_ADMIN_ROLE', _admin);
            self.erc20.initializer(name, symbol);
            self._create_new_stake_batch();
            self._create_new_unstake_batch();
        }    
        

    }

}