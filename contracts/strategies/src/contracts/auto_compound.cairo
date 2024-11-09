#[starknet::contract]
mod HarvestInvestStrat {
    use erc4626::erc4626::erc4626::{ERC4626Component};
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc20::{
        ERC20Component,
        ERC20HooksEmptyImpl
    };
    use openzeppelin::access::ownable::ownable::OwnableComponent;
    use openzeppelin::upgrades::upgradeable::UpgradeableComponent;

    component!(path: ERC4626Component, storage: erc4626, event: ERC4626Event);
    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    use starknet::{
        ContractAddress, ClassHash, 
        contract_address::contract_address_const
    };
    use strategies::interfaces::ERC4626Strategy::{IStrategy, Settings, Harvest};
    use strategies::interfaces::IEkuboDistributor::{IEkuboDistributor, IEkuboDistributorDispatcher, IEkuboDistributorDispatcherTrait, Claim};
    use strategies::components::swap::{AvnuMultiRouteSwap};
    use strategies::{get_contract_address, get_caller_address};
    use strategies::interfaces::zkLend::{IZTokenDispatcher, IZTokenDispatcherTrait};
    use strategies::components::zkLend::{
        zkLendStruct,
        zkLendSettingsImpl
    };
    use strategies::components::harvester::harvester_lib::{
        HarvestConfig, HarvestConfigImpl,
        HarvestHooksTrait
    };
    use strategies::components::harvester::harvester_lib::HarvestBeforeHookResult;
    use strategies::components::harvester::defi_spring_ekubo_style::{
        EkuboStyleClaimSettings,
        ClaimImpl
    };
    use strategies::components::harvester::defi_spring_default_style::{
        SNFStyleClaimSettings,
        ClaimImpl as DefaultClaimImpl
    };
    use strategies::components::harvester::reward_shares::RewardShareComponent;


    use strategies::interfaces::oracle::{IPriceOracle, IPriceOracleDispatcher, IPriceOracleDispatcherTrait, PriceWithUpdateTime};

    #[abi(embed_v0)]
    impl ERC4626AdditionalImpl = ERC4626Component::ERC4626AdditionalImpl<ContractState>;
    #[abi(embed_v0)]
    impl MetadataEntrypointsImpl = ERC4626Component::MetadataEntrypointsImpl<ContractState>;
    #[abi(embed_v0)]
    impl SnakeEntrypointsImpl = ERC4626Component::SnakeEntrypointsImpl<ContractState>;
    #[abi(embed_v0)]
    impl CamelEntrypointsImpl = ERC4626Component::CamelEntrypointsImpl<ContractState>;
    #[abi(embed_v0)]
    impl OwnableTwoStepImpl = OwnableComponent::OwnableTwoStepImpl<ContractState>;
    
    impl ERC4626InternalImpl = ERC4626Component::InternalImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    #[derive(starknet::Store)]
    struct Storage {
        #[substorage(v0)]
        erc4626: ERC4626Component::Storage,
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,

        settings: Settings,
        lend_settings: zkLendStruct,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC4626Event: ERC4626Component::Event,
        #[flat]
        ERC20Event: ERC20Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,

        Harvest: Harvest,
        Settings: Settings,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        asset: ContractAddress,
        name: ByteArray,
        symbol: ByteArray,
        offset: u8,
        settings: Settings,
        lend_settings: zkLendStruct,
        owner: ContractAddress
    ) {
        self.erc4626.initializer(asset, name, symbol, offset);
        self.ownable.initializer(owner);
        self.settings.write(settings);
        lend_settings.assert_valid();
        self.lend_settings.write(lend_settings);
    }

    /// hooks defining before and after actions for the harvest function
    impl HarvestHooksImpl of HarvestHooksTrait<ContractState> {
        fn before_update(
            ref self: ContractState
        ) -> HarvestBeforeHookResult {
            let zTokenAddress = self.asset();
            let zTokenDispatcher = IZTokenDispatcher {contract_address: zTokenAddress};

            let baseTokenAddress = zTokenDispatcher.underlying_token(); // e.g. STRK

            HarvestBeforeHookResult {
                baseToken: baseTokenAddress,
            }
        }
    
        fn after_update(
            ref self: ContractState,
            token: ContractAddress,
            amount: u256
        ) {
            let lendSettings: zkLendStruct = self.lend_settings.read();
            lendSettings.deposit(token, amount);
        }
    }

    #[abi(embed_v0)]
    impl ExternalImpl of IStrategy<ContractState> {
        // Harvests token from distribution contract and invests in zklends pool
        fn harvest(ref self: ContractState, claim: Claim, proof: Span<felt252>, swapInfo: AvnuMultiRouteSwap) {
            let settings = self.get_settings();
            let ekuboSettings = EkuboStyleClaimSettings {
                rewardsContract: settings.rewardsContract,
            };
            let config = HarvestConfig {};

            // just dummy config, not used
            let snfSettings = SNFStyleClaimSettings {
                rewardsContract: contract_address_const::<0>()
            };
            config.simple_harvest(
                ref self,
                ekuboSettings,
                claim,
                proof,
                snfSettings,
                swapInfo,
                self.lend_settings.read().oracle
            );
        }

        fn set_settings(ref self: ContractState, settings: Settings, lend_settings: zkLendStruct) {
            self.ownable.assert_only_owner();
            self.settings.write(settings);
            lend_settings.assert_valid();
            self.lend_settings.write(lend_settings);
        }

        fn upgrade(ref self: ContractState, class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable._upgrade(class_hash);
        }

        //
        // view functions
        //

        fn get_settings(self: @ContractState) -> Settings {
            self.settings.read()
        }
    }
}