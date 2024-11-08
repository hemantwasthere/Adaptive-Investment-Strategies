

#[starknet::contract]
mod AutoVault {

    use starknet::{
        ContractAddress, get_caller_address, get_contract_address
    };

    use strategies::interfaces::IAutoVault::IAutoVault;

    #[storage]
    struct Storage {
        // balance: felt252, 
    }

    #[constructor]
        fn constructor(
            ref self: ContractState,
            name: felt252,
            symbol: felt252,
            token: ContractAddress,
            _admin: ContractAddress
        ) {
        //     assert(!token.is_zero(), Errors::ZERO_ADDRESS);
        //     assert(!_admin.is_zero(), Errors::ZERO_ADDRESS);
        //     self.accesscontrol.initializer();
        //     self._set_admin(_admin);
            // self.erc20.initializer(name, symbol);
        }   

    #[abi(embed_v0)]
    impl AutoVaultImpl of IAutoVault<ContractState> {
    
        fn deposit(ref self: ContractState, assets: u256, receiver: ContractAddress) -> u256 {
            // self.reentrancyguard.start();
            // self.pausable.assert_not_paused();

           
            return 0;
        }

        fn mint(ref self: ContractState, shares: u256, receiver: ContractAddress) -> u256 {
            0
        }

        fn withdraw(
            ref self: ContractState, assets: u256, receiver: ContractAddress, owner: ContractAddress
        ) -> u256 {
            0
        }


        fn redeem(
            ref self: ContractState, shares: u256, receiver: ContractAddress, owner: ContractAddress
        ) -> u256 {
            // self.reentrancyguard.start();
            // self.pausable.assert_not_paused();
            
            // self.reentrancyguard.end();
            // return _assets;

            0
        }

        
        fn preview_deposit(self: @ContractState, assets: u256) -> u256 {
            // self.convert_to_shares(assets)
            0
        }

        fn preview_mint(self: @ContractState, shares: u256) -> u256 {
            // self.convert_to_assets(shares)
            0
        }

        fn preview_withdraw(self: @ContractState, assets: u256) -> u256 {
            // self.convert_to_shares(assets)
            0
        }

        fn preview_redeem(self: @ContractState, shares: u256) -> u256 {
            // self.convert_to_assets(shares)
            0
        }

        fn convert_to_shares(self: @ContractState, assets: u256) -> u256 {
            // let supply: u256 = self.erc20.total_supply();
            // if (assets == 0 || supply == 0) {
            //     assets
            // } else {
            //     mul_div_down(assets, supply, self.total_assets())
            // }

            0
        }

        fn convert_to_assets(self: @ContractState, shares: u256) -> u256 {
            // let supply: u256 = self.erc20.total_supply();
            // if (supply == 0) {
            //     shares
            // } else {
            //     mul_div_down(shares, self.total_assets(), supply)
            // }

            0
        }



        fn total_assets(self: @ContractState) -> u256 {
            // self.vault_balance()
            //     + self._eth_due_to_backing_tokens()
            //     + self._get_exchange_rate().eth_in_transit
            0
        }

       
        // /// @notice Upgrades the vault implementaton to new classHash
        // /// @param new_class_has New class Hash
        // fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
        //     self.accesscontrol.assert_only_role('DEFAULT_ADMIN_ROLE');
        //     self.upgradeable._upgrade(new_class_hash);
        // }

        // /// @notice Pauses the contract's functionality
        // fn pause(ref self: ContractState) {
        //     self.accesscontrol.assert_only_role('DEFAULT_ADMIN_ROLE');
        //     self.pausable._pause();
        // }

        // /// @notice Unpauses the contract's functionality
        // fn unpause(ref self: ContractState) {
        //     self.accesscontrol.assert_only_role('DEFAULT_ADMIN_ROLE');
        //     self.pausable._unpause();
        // }

        // /// @notice Changes Vault's admin
        // /// @param new_amdin Address of the new admin
        // /// @dev Revokes admin privilege from old_admin and grants admin privilege to new_admin
        // fn update_admin(ref self: ContractState, new_admin: ContractAddress) {
        //     assert(!new_admin.is_zero(), Errors::ZERO_ADDRESS);
        //     self.accesscontrol.assert_only_role('DEFAULT_ADMIN_ROLE');
        //     self.pausable.assert_not_paused();
        //     let old_admin: ContractAddress = self.get_admin();
        //     self.accesscontrol._grant_role('DEFAULT_ADMIN_ROLE', new_admin);
        //     self._set_admin(new_admin);
        //     self.accesscontrol._revoke_role('DEFAULT_ADMIN_ROLE', old_admin);
        // }


        // /// @notice Get the admin address of the Vault
        // fn get_admin(self: @ContractState) -> ContractAddress {
        //     self.admin.read()
        // }
        

    }

}