#[starknet::contract]
mod AutoVault {

    use openzeppelin_token::erc20::{ERC20Component, ERC20HooksEmptyImpl};

    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;
    #[abi(embed_v0)]
    impl AccessControlImpl =
        AccessControlComponent::AccessControlImpl<ContractState>;
    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    // ERC20 Mixin
    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    use strategies::interfaces::IAutoVault::IAutoVault;
    use strategies::utils::math::Math::mul_div_down;
    use strategies::utils::errors::Errors;
    use strategies::utils::constants::Constants::{LENDING, DEX, DECIMALS};


    use core::traits::{TryInto, Into};
    use core::array::ArrayTrait;
    use starknet::{ClassHash, ContractAddress, get_caller_address, get_contract_address};


    #[storage]
    struct Storage {
        // components
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        // Stores the address of Vault admin
        admin: ContractAddress,
        // Stores the current mode of the Vault
        // - 0 is LENDING
        // - 1 is DEX
        mode: u8,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        AccessControlEvent: AccessControlComponent::Event,
        SRC5Event: SRC5Component::Event,
        UpgradeableEvent: UpgradeableComponent::Event,
        ReentracnyGuardEvent: ReentrancyGuardComponent::Event,
        ERC20Event: ERC20Component::Event,
        PausableEvent: PausableComponent::Event,
        Deposit: Deposit,
        Withdraw: Withdraw,
    }

    #[derive(Drop, starknet::Event)]
    struct Deposit {
        sender: ContractAddress,
        owner: ContractAddress,
        assets: u256,
        shares: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Withdraw {
        sender: ContractAddress,
        receiver: ContractAddress,
        owner: ContractAddress,
        assets: u256,
        share: u256,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, name: felt252, symbol: felt252, admin: ContractAddress
    ) {}

    #[abi(embed_v0)]
    impl AutoVaultImpl of IAutoVault<ContractState> {
        fn deposit(ref self: ContractState, assets: u256, receiver: ContractAddress) -> u256 {
            self.reentrancyguard.start();
            self.pausable.assert_not_paused();
            assert(
                assets >= self.min_deposit() && assets <= self.max_deposit(receiver),
                'Insufficeint amount'
            );
            let shares = self.preview_deposit(assets);
            self._deposit(get_caller_address(), receiver, assets, shares);
            self.reentrancyguard.end();
            return _shares;
        }

        fn mint(ref self: ContractState, shares: u256, receiver: ContractAddress) -> u256 {
            0
        }

        fn redeem(
            ref self: ContractState, shares: u256, receiver: ContractAddress, owner: ContractAddress
        ) -> u256 {
            self.reentrancyguard.start();
            self.pausable.assert_not_paused();
            assert(shares <= self.max_redeem(owner), Errors::INVALID_SHARES);
            let assets = self.preview_redeem(shares);
            self._withdraw(get_caller_address(), receiver, owner, assets, shares);

            self.reentrancyguard.end();
            return _assets;
        }

        fn withdraw(
            ref self: ContractState, assets: u256, receiver: ContractAddress, owner: ContractAddress
        ) -> u256 {
            0
        }

        fn preview_deposit(self: @ContractState, assets: u256) -> u256 {
            self.convert_to_shares(assets)
        }

        fn preview_mint(self: @ContractState, shares: u256) -> u256 {
            self.convert_to_assets(shares)
        }

        fn preview_withdraw(self: @ContractState, assets: u256) -> u256 {
            self.convert_to_shares(assets)
        }

        fn preview_redeem(self: @ContractState, shares: u256) -> u256 {
            self.convert_to_assets(shares)
        }

        fn convert_to_shares(self: @ContractState, assets: u256) -> u256 {
            let supply: u256 = self.erc20.total_supply();
            if (assets == 0 || supply == 0) {
                assets
            } else {
                mul_div_down(assets, supply, self.total_assets())
            }
        }

        fn convert_to_assets(self: @ContractState, shares: u256) -> u256 {
            let supply: u256 = self.erc20.total_supply();
            if (supply == 0) {
                shares
            } else {
                mul_div_down(shares, self.total_assets(), supply)
            }
        }

        fn min_deposit(self: @ContractState) -> u256 {
            0
        }

        fn max_deposit(self: @ContractState, receiver: ContractAddress) -> u256 {
            0
        }

        fn max_mint(self: @ContractState, receiver: ContractAddress) -> u256 {
            self.convert_to_shares(self.max_deposit(receiver))
        }

        fn max_withdraw(self: @ContractState, owner: ContractAddress) -> u256 {
            self.convert_to_assets(0)
        }

        fn total_assets(self: @ContractState) -> u256 {
            0
            // Will be lendingAssets + dexAssets
        // Need to be computed
        }
    }
}
