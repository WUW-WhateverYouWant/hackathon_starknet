
use starknet::{
    ContractAddress
};

use wuw_contracts::types::launch:: {
    Launch, AmountLaunch,
    DepositByUser
};


#[starknet::interface]
trait ILaunchpad<TContractState> {
    fn create_launch(ref self:TContractState,
        asset:ContractAddress, 
        quote_token_address:ContractAddress, 
        total_amount:u256, 
        token_received_per_one_base:u256,
        start_date:u64, 
        end_date:u64, 
        soft_cap:u256,
        hard_cap:u256,
        min_deposit_by_user:u256,
        max_deposit_by_user:u256,
     
     )-> u64;


    fn create_launch_base_oracle(ref self:TContractState,
        asset:ContractAddress, 
        quote_token_address:ContractAddress, 
        total_amount:u256, 
        start_date:u64, 
        end_date:u64, 
        soft_cap:u256, 
        hard_cap:u256,
        min_deposit_by_user:u256,
        max_deposit_by_user:u256,
        token_per_dollar:u256
    )-> u64;

    fn refund_launch(ref self:TContractState,launch_id:u64)-> u64;
    fn refund_deposit_amount(ref self:TContractState, launch_id:u64);
    fn buy_token(ref self:TContractState,launch_id:u64, token_amount_base:u256)-> u64;
    fn withdraw_token(ref self:TContractState,launch_id:u64)-> u64;
    fn cancel_launch(ref self:TContractState,launch_id:u64)-> u64;
    fn launch_liquidity(ref self:TContractState,launch_id:u64)-> u64;

    // Admin
    fn set_oracle_base_asset(ref self:TContractState,asset_address:ContractAddress, is_oracle:bool);
    fn set_pragma_address(ref self:TContractState,pragma_oracle_address:ContractAddress);
    fn set_address_jediswap_factory_v2(ref self:TContractState, address_jediswap_factory_v2:ContractAddress);
    fn set_is_paid_dollar_launch(ref self:TContractState, is_paid_dollar_launch:bool);
    fn set_address_token_to_pay_launch(ref self:TContractState, address_token_to_pay_launch:ContractAddress);
    fn set_amount_paid_dollar_launch(ref self:TContractState, amount_paid_dollar_launch:u256);
    fn set_token_selector(ref self:TContractState, address:ContractAddress, selector:felt252);
    fn set_params_fees(
        ref self:TContractState, 
        is_paid_dollar_launch:bool,
        address_token_to_pay:ContractAddress, 
        amount_paid_dollar_launch:u256,
        selector:felt252
    );
    fn set_address_jediswap_nft_router_v2(ref self:TContractState, address_jediswap_nft_router_v2:ContractAddress);
    // fn transfer_token_amount(ref self:TContractState, address:ContractAddress, token_amount:u256);
   
    // Views
    // TODO add getters before indexer 
    fn get_launch_by_id(self: @TContractState, launch_id:u64) -> Launch;
    fn get_all_launchs(self: @TContractState)-> Span<Launch>;
    fn get_launchs_by_owner(self: @TContractState, owner:ContractAddress)-> Span<Launch>;
    fn get_deposit_by_users(self: @TContractState, address:ContractAddress)-> Span<DepositByUser>;
    fn get_is_dollar_paid_launch(self: @TContractState)-> bool;
    fn get_address_token_to_pay_launch(self:@TContractState) -> ContractAddress;
    fn get_amount_paid_dollar_launch(self:@TContractState) -> u256;
    fn get_amount_token_to_pay_launch(self:@TContractState) -> u256;
    fn get_price_token_selector(self:@TContractState, selector:felt252) -> u256;

    fn get_amount_token_to_pay_launch_median(self:@TContractState) -> u256;
    fn get_asset_price_median_selector(self:@TContractState, selector:felt252) -> u256;
}

#[starknet::contract]
mod Launchpad {

    use pragma_lib::abi::{IPragmaABIDispatcher, IPragmaABIDispatcherTrait};
    use pragma_lib::types::{AggregationMode, DataType, PragmaPricesResponse};

    use wuw_contracts::types::launch:: {
        Launch, AmountLaunch,
        DepositByUser,

        // Event 
        LaunchCreated,
        EventDepositSend,
        EventBaseOracleSet,
        RefundBuyToken,
        PragmaOracleAddressSet,
        SetJediwapV2Factory,
        SetIsPaidDollarLaunch,
        SetAddressTokenToPayLaunch,
        SetJediwapNFTRouterV2,
        AddLiquidity,
        LiquidityCreated
    };
    use wuw_contracts::types::jediswap:: {
      MintParams
    };

    use wuw_contracts::interfaces::erc20::{
      IERC20Dispatcher,
      IERC20DispatcherTrait,
    };

    use wuw_contracts::interfaces::jediswap:: {
       IJediswapFactoryV2,
       IJediswapFactoryV2Dispatcher,
       IJediswapFactoryV2DispatcherTrait,
       IJediswapNFTRouterV2,
       IJediswapNFTRouterV2Dispatcher,
       IJediswapNFTRouterV2DispatcherTrait,
    };

    use openzeppelin::token::erc20::ERC20Component;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::access::accesscontrol::AccessControlComponent;
    use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};

    use core::starknet::event::EventEmitter;
    use core::result::ResultTrait;
    use starknet::{
        get_caller_address, ContractAddress, contract_address_const, get_contract_address,
        get_block_timestamp,
        
    };
 
    use openzeppelin::token::erc20::dual20::{
         DualCaseERC20,
    };
    use alexandria_math::pow;
    use array::ArrayTrait;
    use traits::Into;
    use zeroable::Zeroable;

    // SR5 Component 
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    // Owner access

    use openzeppelin::access::ownable::OwnableComponent;
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    #[abi(embed_v0)]
    impl OwnableCamelOnlyImpl =
        OwnableComponent::OwnableCamelOnlyImpl<ContractState>;
    impl InternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // Access control role 
    const ADMIN_ROLE: felt252 = selector!("ADMIN_ROLE");
    const OWNER_ROLE: felt252 = selector!("OWNER_ROLE");
    const MANAGER_ROLE: felt252 = selector!("MANAGER_ROLE");

    
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    // AccessControl
    #[abi(embed_v0)]
    impl AccessControlImpl =
        AccessControlComponent::AccessControlImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;



    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,

        LaunchCreated: LaunchCreated,
        EventDepositSend: EventDepositSend,
        EventBaseOracleSet:EventBaseOracleSet,
        RefundBuyToken:RefundBuyToken,
        PragmaOracleAddressSet:PragmaOracleAddressSet,
        SetJediwapV2Factory:SetJediwapV2Factory,
        SetJediwapNFTRouterV2:SetJediwapNFTRouterV2,
        SetIsPaidDollarLaunch:SetIsPaidDollarLaunch,
        SetAddressTokenToPayLaunch:SetAddressTokenToPayLaunch,
        AddLiquidity:AddLiquidity,
        LiquidityCreated:LiquidityCreated
     
    }

    #[storage]
    struct Storage {

        next_launch_id:u64,
        launchs:LegacyMap::<u64, Launch>,
        deposit_user_by_launch: LegacyMap::<(ContractAddress, u64), DepositByUser>,

        // Admin
        tokens_blacklisted_for_buy:LegacyMap::<ContractAddress, bool>,
        tokens_boosted:LegacyMap::<ContractAddress, bool>,
        is_assets_base_oracle:LegacyMap::<ContractAddress, bool>,
        tokens_launch_ids:LegacyMap::<ContractAddress, u64>,

        // Management external contracts
        pragma_oracle_address:ContractAddress,
        own_pragma_oracle_address:ContractAddress,
        address_jediswap_factory_v2:ContractAddress,
        address_jediswap_nft_router_v2:ContractAddress,
        market_felt_by_asset:LegacyMap::<ContractAddress, felt252>,
        tokens_selectors:LegacyMap::<ContractAddress, felt252>,

        // Fees management
        protocol_fee_launch_creation:u8,
        base_protocol_fee_launch_creation:u8,
        amount_paid_dollar_launch:u256,
        is_paid_dollar_launch:bool,
        address_token_to_pay_launch:ContractAddress,
        is_tokens_address_paid_launch_enable:LegacyMap::<ContractAddress, bool>,
        tokens_oracle_pair_market_dollar:LegacyMap::<ContractAddress, felt252>,
        
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,

        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,

        #[substorage(v0)]
        src5: SRC5Component::Storage,
    }
 
    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        // pragma_oracle_address: ContractAddress,
    ) {

        // let owner=get_caller_address();
        self.next_launch_id.write(0);
        self.ownable.initializer(owner);

        // AccessControl-related initialization
        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(ADMIN_ROLE, owner);
        self.accesscontrol._grant_role(OWNER_ROLE, owner);

        // Init admin 
        // self.is_paid_dollar_launch.write(true);
    }


    // TODO implement internal functions and refacto
    #[generate_trait]
    impl LaunchpadInternalImpl of LaunchpadInternalTrait {
 
        // TODO finish
        // Owner cancel launch and receive their tokens back
        fn _add_liquidity(
            ref self:ContractState,
            launch:Launch,
            // fee:u32, // TODO add fee select by user
            // token_a:ContractAddress,
            // token_b:ContractAddress
        ){

            let contract_address=get_contract_address();
            let factory_address = self.address_jediswap_factory_v2.read();
            let nft_router_address =  self.address_jediswap_nft_router_v2.read();

            let fee:u32 = 10_000;
            let factory = IJediswapFactoryV2Dispatcher {contract_address:factory_address};
            let nft_router = IJediswapNFTRouterV2Dispatcher {contract_address:nft_router_address};

            let token_a = launch.asset;
            let token_b= launch.quote_token_address;
            // TODO tokens check 
            // assert!(token_a != token_b, "same token");
            // Look if pool already exist 
            // Init and Create pool if not exist 
            let mut pool:ContractAddress = factory.get_pool(token_a, token_b, fee);
            let sqrt_price_X96=0; // TODO change sqrt_price_X96

            // TODO check if pool exist 
            // Pool need to be create
            
            let amount0_desired=0;
            let amount1_desired=0;
            let amount0_min=0;
            let amount1_min=0;
            let tick_lower:i32=0;
            let tick_upper:i32=0;
            let deadline:u64= get_block_timestamp();

            if pool.into() == 0_felt252 {
                pool = factory.create_pool(token_a,token_b, fee);
                pool= nft_router.create_and_initialize_pool(token_a, token_b, fee, sqrt_price_X96);
                // TODO Increase liquidity with router if exist
                // Approve token asset and quote to be transfered
                let token_asset = IERC20Dispatcher {contract_address:token_a};
                let token_quote = IERC20Dispatcher {contract_address:token_b};
                token_asset.approve(nft_router_address, launch.total_amount);
                token_quote.approve(nft_router_address, launch.amounts.deposited);
                // TODO verify Mint params 
                // Test snforge in Sepolia
                let mint_params = MintParams {
                    token0:token_a,
                    token1:token_b,
                    fee:fee,
                    tick_lower:tick_lower,
                    tick_upper:tick_upper,
                    amount0_desired:amount0_desired,
                    amount1_desired:amount1_desired,
                    amount0_min:amount0_min,
                    amount1_min:amount1_min,
                    recipient:launch.owner, // TODO add 
                    deadline:deadline,
                };

                let (token_id, _, _, _) = nft_router.mint(mint_params);

                self.emit( LiquidityCreated {
                    id:launch.launch_id,
                    pool:pool,
                    quote_token_address:launch.quote_token_address,
                    token_id:token_id,
                    owner:launch.owner,
                    asset:launch.asset,
                });
                
            } else {
                // TODO 
                // Increase liquidity of this pool.
            }

        }

        fn _get_asset_price_average_converted(self:@ContractState, key:felt252) -> u256 {
            let oracle_address=self.pragma_oracle_address.read();
            // TODO assert pragma oracle 
            assert!(!oracle_address.is_zero(), "oracle undefined");
            let oracle_dispatcher = IPragmaABIDispatcher{contract_address : oracle_address};
            let asset=DataType::SpotEntry(key);
            let output : PragmaPricesResponse= oracle_dispatcher.get_data(asset, AggregationMode::Mean(()));

            // TODO fix conversion u128 to u256
            let price_128:u128= output.price;
            let decimals: u128 = output.decimals.into();
            let multiplier: u128 = pow(10, decimals);
            // let price:u256= price_128*multiplier;
            let price_mul= (price_128*multiplier);
            let price:u256=price_mul.into();
            // let price:u256=price_128.into();
            price
        }

        fn _get_asset_price_average_pragma(self: @ContractState, key:felt252 ) ->  PragmaPricesResponse {

            let oracle_address=self.pragma_oracle_address.read();
            // TODO assert pragma oracle 
            assert!(!oracle_address.is_zero(), "oracle undefined");
            let oracle_dispatcher = IPragmaABIDispatcher{contract_address : oracle_address};

            let asset=DataType::SpotEntry(key);
            let output : PragmaPricesResponse= oracle_dispatcher.get_data(asset, AggregationMode::Mean(()));
            return output;
        }

        fn _get_asset_price_average(self: @ContractState, key:felt252 ) ->  u128 {

            let oracle_address=self.pragma_oracle_address.read();
            // TODO assert pragma oracle 
            assert!(!oracle_address.is_zero(), "oracle undefined");
            let oracle_dispatcher = IPragmaABIDispatcher{contract_address : oracle_address};

            let asset=DataType::SpotEntry(key);
            let output : PragmaPricesResponse= oracle_dispatcher.get_data(asset, AggregationMode::Mean(()));
            return output.price;
        }

        fn _get_asset_price_median(self: @ContractState, asset_id: felt252) -> u128 {
            // Retrieve the oracle dispatcher
            let oracle_address=self.pragma_oracle_address.read();

            let oracle_dispatcher = IPragmaABIDispatcher {
                contract_address: oracle_address
            };

            // Call the Oracle contract, for a spot entry
            let output: PragmaPricesResponse = oracle_dispatcher
                .get_data_median(DataType::SpotEntry(asset_id));

            return output.price;
        }

        fn _get_asset_price_median_converted(self: @ContractState, asset_id: felt252) -> u256 {
            // Retrieve the oracle dispatcher
            let oracle_address=self.pragma_oracle_address.read();

            let oracle_dispatcher = IPragmaABIDispatcher {
                contract_address: oracle_address
            };

            // Call the Oracle contract, for a spot entry
            let output: PragmaPricesResponse = oracle_dispatcher
                .get_data_median(DataType::SpotEntry(asset_id));
            // TODO fix conversion u128 to u256

            let price_128:u128= output.price;
            let decimals: u128 = output.decimals.into();
            let multiplier: u128 = pow(10, decimals);
            let price:u256= (price_128*multiplier).into();
            return price;
        }


    }

    #[abi(embed_v0)]
    impl LaunchpadImpl of super::ILaunchpad<ContractState> {

        // ADMIN
        fn set_oracle_base_asset(ref self:ContractState, asset_address:ContractAddress, is_oracle:bool)  {
            self.accesscontrol.assert_only_role(ADMIN_ROLE);
            self.is_assets_base_oracle.write(asset_address, is_oracle);
            self.emit(EventBaseOracleSet{ asset:asset_address, is_oracle:is_oracle});

        }

        // Jediwswap factory address
        fn set_address_jediswap_factory_v2(ref self:ContractState, address_jediswap_factory_v2:ContractAddress) {
            self.accesscontrol.assert_only_role(ADMIN_ROLE);
            // self.ownable.assert_only_owner();
            self.address_jediswap_factory_v2.write(address_jediswap_factory_v2);
            self.emit(SetJediwapV2Factory{ address_jediswap_factory_v2:address_jediswap_factory_v2});
        }

        fn set_address_jediswap_nft_router_v2(ref self:ContractState, address_jediswap_nft_router_v2:ContractAddress) {
            self.accesscontrol.assert_only_role(ADMIN_ROLE);
            self.address_jediswap_nft_router_v2.write(address_jediswap_nft_router_v2);
            self.emit(SetJediwapNFTRouterV2{ address_jediswap_nft_router_v2:address_jediswap_nft_router_v2});

        }

        // Pragma oracle address
        fn set_pragma_address(ref self:ContractState, pragma_oracle_address:ContractAddress) {
            self.accesscontrol.assert_only_role(ADMIN_ROLE);
            self.pragma_oracle_address.write(pragma_oracle_address);

            // own_pragma_oracle_address
            // self.own_pragma_oracle_address.write(pragma_oracle_address);
            self.emit(PragmaOracleAddressSet{ pragma_oracle_address:pragma_oracle_address});
        }

        // Token to paid when create launch
        fn set_address_token_to_pay_launch(ref self: ContractState, address_token_to_pay_launch:ContractAddress) {
            self.accesscontrol.assert_only_role(ADMIN_ROLE);
            self.address_token_to_pay_launch.write(address_token_to_pay_launch);
            self.emit(SetAddressTokenToPayLaunch{ address_token_to_pay_launch:address_token_to_pay_launch});
        }

        // Set paid dollar launch 
        // Need to have a token for paid it
        fn set_is_paid_dollar_launch(ref self:ContractState, is_paid_dollar_launch:bool) {
            self.accesscontrol.assert_only_role(ADMIN_ROLE);
            self.is_paid_dollar_launch.write(is_paid_dollar_launch);
            self.emit(SetIsPaidDollarLaunch{ is_paid_dollar_launch:is_paid_dollar_launch});
        }

        fn set_amount_paid_dollar_launch(ref self:ContractState, amount_paid_dollar_launch:u256) {
            self.accesscontrol.assert_only_role(ADMIN_ROLE);
            self.amount_paid_dollar_launch.write(amount_paid_dollar_launch);
           
        }

        fn set_token_selector(ref self:ContractState, address:ContractAddress, selector:felt252) {
            self.accesscontrol.assert_only_role(ADMIN_ROLE);
            self.tokens_selectors.write(address, selector);
            self.market_felt_by_asset.write(address, selector);
        }


        fn set_params_fees(
            ref self:ContractState, 
            is_paid_dollar_launch:bool,
            address_token_to_pay:ContractAddress, 
            amount_paid_dollar_launch:u256,
            selector:felt252
        ) {
            self.set_is_paid_dollar_launch(is_paid_dollar_launch);
            self.set_address_token_to_pay_launch(address_token_to_pay);
            self.set_amount_paid_dollar_launch(amount_paid_dollar_launch);
            self.set_token_selector(address_token_to_pay, selector);
        }

        // CREATOR POOL
        // OWNER OF LAUNCHPAD
        // TODO WIP
        // Finish assert for soft_cap & hard_cap 
        // Check liquidity price, receive is coherent 
        fn create_launch(ref self: ContractState,
            asset:ContractAddress,
            quote_token_address:ContractAddress,
            total_amount:u256,
            token_received_per_one_base:u256,
            start_date:u64,
            end_date:u64,
            soft_cap:u256,
            hard_cap:u256,
            min_deposit_by_user:u256,
            max_deposit_by_user:u256,
            // is_liquidity:bool // TODO add params 
            // liquidity_percent:u8 //at least 50%

        ) -> u64 {

            // TODO check date
            let timestamp=get_block_timestamp();
            assert!(timestamp<start_date, "time < start_date");
            assert!(timestamp<end_date, "time < end_date");
            assert!(start_date<end_date, "start > end");

            // TODO Different tokens
            assert!(asset != quote_token_address, "same token");

            // TODO Check soft_cap & token liquidity
            let contract_address=get_contract_address();
            let sender=get_caller_address();

            let current_id= self.next_launch_id.read();
            let next_id= current_id+1;

            // TODO Check cap 
            assert!(soft_cap<= hard_cap, "soft below hard_cap");

            // TODO verify total_amount and compare with token_per_one base with soft_cap and hard cap.
            // Calculate
            // assert!(total_amount>=token_received_per_one_base*hard_cap, "CAP NO TOKEN QTY")


            let amounts:AmountLaunch = AmountLaunch {
                deposited:total_amount,
                withdrawn:0,
                refunded:0,
                total_token_to_be_claimed:total_amount,
                remain_token_to_be_claimed:total_amount,
            };

            // Add paid dollar by token set
            // TODO paid dollar by token dollar
            if self.is_paid_dollar_launch.read() {

                let token_address= self.address_token_to_pay_launch.read();
                let amount_token_to_pay=self.get_amount_token_to_pay_launch();
                IERC20Dispatcher{contract_address:token_address}.transfer_from(sender, contract_address, amount_token_to_pay);

            }

            let launch:Launch= Launch {
                launch_id:current_id,
                total_amount:total_amount,
                remain_balance:total_amount,
                start_date:start_date,
                end_date:end_date,
                owner:sender,
                asset:asset,
                broker:sender,
                quote_token_address:quote_token_address,
                soft_cap:soft_cap,
                hard_cap:hard_cap,
                is_canceled:false,
                min_deposit_by_user:min_deposit_by_user,
                max_deposit_by_user:max_deposit_by_user,
                token_received_per_one_base:token_received_per_one_base,
                amounts,
                is_refundable:true,
                is_base_asset_oracle:false,
                token_per_dollar:0

            };
     
            // SEND TOKEN
            IERC20Dispatcher { contract_address: asset }.transfer_from(sender, contract_address, total_amount);

            self.launchs.write(current_id, launch);
            self.next_launch_id.write(next_id);
            self.emit(LaunchCreated { id:current_id, owner: sender, launch:launch.clone()});
            next_id
        }


        // TODO 
    
        fn create_launch_base_oracle(ref self: ContractState,
            asset:ContractAddress,
            quote_token_address:ContractAddress,
            total_amount:u256,
            start_date:u64,
            end_date:u64,
            soft_cap:u256,
            hard_cap:u256,
            min_deposit_by_user:u256,
            max_deposit_by_user:u256,
            token_per_dollar:u256
        ) -> u64 {

            // Verify base token 
            assert!(self.is_assets_base_oracle.read(asset) == true, "not oracle token");
            // TODO check date
            let timestamp=get_block_timestamp();
            assert!(timestamp<start_date, "time < start_date");
            assert!(timestamp<end_date, "end_date too early");
            assert!(start_date<end_date, "start > end");

            // TODO : Tokens check 
            assert!(asset != quote_token_address, "same token");

            let contract_address=get_contract_address();
            let sender=get_caller_address();

            let current_id= self.next_launch_id.read();
            let next_id= current_id+1;

            // TODO Check cap 
            assert!(soft_cap<= hard_cap, "soft below hard_cap");

            let amounts:AmountLaunch = AmountLaunch {
                deposited:total_amount,
                withdrawn:0,
                refunded:0,
                total_token_to_be_claimed:total_amount,
                remain_token_to_be_claimed:total_amount,
            };

            // Add paid dollar by token set
            // TODO paid dollar by token dollar
            if self.is_paid_dollar_launch.read() {

                let token_address= self.address_token_to_pay_launch.read();
                let amount_token_to_pay=self.get_amount_token_to_pay_launch();
                IERC20Dispatcher{contract_address:token_address}.transfer_from(sender, contract_address, amount_token_to_pay);

            }

            let launch:Launch= Launch {
                launch_id:current_id,
                total_amount:total_amount,
                remain_balance:total_amount,
                start_date:start_date,
                end_date:end_date,
                token_received_per_one_base:0,
                owner:sender,
                asset:asset,
                broker:sender,
                quote_token_address:quote_token_address,
                soft_cap:soft_cap,
                hard_cap:hard_cap,
                is_canceled:false,
                min_deposit_by_user:min_deposit_by_user,
                max_deposit_by_user:max_deposit_by_user,
                amounts,
                is_refundable:true,
                is_base_asset_oracle:true,
                token_per_dollar:token_per_dollar

            };
     
            // SEND TOKEN
            IERC20Dispatcher { contract_address: asset }.transfer_from(sender, contract_address, total_amount);

            self.launchs.write(current_id, launch);
            self.next_launch_id.write(next_id);
            self.emit(LaunchCreated { id:current_id, owner: sender, launch:launch.clone()});
            next_id
        }

        // Owner cancel launch and receive their tokens back
        fn cancel_launch(ref self:ContractState,
            launch_id:u64
        )-> u64 {

            let contract_address=get_contract_address();
            let sender=get_caller_address();
            let mut launch= self.launchs.read(launch_id);

            // Verify owner 
            let owner = launch.owner;
            assert!(sender == owner, "not owner");
            assert!(!launch.is_canceled, "already cancel");

            // Check timestamp
            let timestamp=get_block_timestamp();
            assert!(timestamp<launch.end_date, "time < end_date");

            // Token back to owner
            IERC20Dispatcher{contract_address:launch.asset}.transfer(owner, launch.total_amount);

            // Update
            launch.is_canceled=true;
            self.launchs.write(launch_id, launch);

            launch_id
        }

        // TODO add multi exchanges, fees and more 
        // Launch liquidity 
        // Send to V2 Jediswap swap 
        fn launch_liquidity(ref self:ContractState, launch_id:u64) -> u64 {

            let contract_address=get_contract_address();
            let sender=get_caller_address();
            let mut launch= self.launchs.read(launch_id);

            // Verify owner 
            let owner = launch.owner;
            assert!(sender == owner, "not owner");
            assert!(!launch.is_canceled, "already cancel");

            // Check timestamp
            let timestamp=get_block_timestamp();
            assert!(timestamp<launch.end_date, "time < end_date");

            LaunchpadInternalImpl::_add_liquidity(ref self, launch);

            launch_id


        }

        // TODO Finish
        // REFUND OWNER
        fn refund_launch(
            ref self:ContractState,
            launch_id:u64
        )-> u64 {

            let mut launch= self.launchs.read(launch_id);
            let sender=get_caller_address();
            let owner= launch.owner;

            assert!(sender == owner, "not owner");
            let contract_address=get_contract_address();
            let timestamp= get_block_timestamp();

            assert!(timestamp<launch.end_date, "time < end_date");

            // Update
            IERC20Dispatcher { contract_address: launch.asset}.transfer(sender, launch.total_amount );
            launch.is_canceled=true;
            self.launchs.write(launch_id, launch);


            launch_id
        }

        // USERS call
        fn refund_deposit_amount(
            ref self:ContractState,
            launch_id:u64
        
        )  {

            let mut launch = self.launchs.read(launch_id);
            let timestamp=get_block_timestamp();
            let sender= get_caller_address();
            let contract_address=get_contract_address();
            assert!(timestamp<launch.end_date,"time < end_date");

            let mut amount_deposit_by_user = self.deposit_user_by_launch.read((sender, launch_id));

            if amount_deposit_by_user.deposited> 0 {

                let refund= amount_deposit_by_user.deposited;
                let remain_token_to_be_claimed= amount_deposit_by_user.remain_token_to_be_claimed;

                amount_deposit_by_user.deposited=0;
                amount_deposit_by_user.refunded=refund;

                amount_deposit_by_user.remain_token_to_be_claimed=0;
                amount_deposit_by_user.total_token_to_be_claimed=0;
                amount_deposit_by_user.is_canceled=true;

                self.deposit_user_by_launch.write((sender, launch_id), amount_deposit_by_user);

                // TODO readd remain balance
                launch.amounts.deposited-=refund;
                launch.remain_balance+=remain_token_to_be_claimed;

                IERC20Dispatcher { contract_address: launch.quote_token_address}.transfer( sender, refund );

                self.launchs.write(launch_id, launch);

                self.emit(RefundBuyToken { asset_refund: launch.asset, amount_refund:refund});

            }


        }

        // TODO verify and check 
        fn buy_token(
            ref self:ContractState,
            launch_id:u64,
            token_amount_base:u256
        )-> u64 {

            let sender = get_caller_address();
            let contract = get_contract_address();

            let mut launch = self.launchs.read(launch_id);
            // Check date 
            let timestamp=get_block_timestamp();
            assert!(timestamp<launch.end_date, "time < end_date");

            // Check is cancel 
            assert!(!launch.is_canceled, "launch cancel");


            // Verify amount 
            assert!(token_amount_base>0, "increase token base");

            assert!(token_amount_base>=launch.min_deposit_by_user, "amount below min_deposit");

            // Add amount users
            let mut amount_deposit = self.deposit_user_by_launch.read((sender, launch_id));
            let quote_token_address= launch.quote_token_address;

            // TODO check hard_cap and soft_cap
            // hard_cap
            // soft_cap
            assert!(launch.amounts.deposited+token_amount_base<=launch.hard_cap, "hard_cap reach");


            // TODO oracle calculation ETH
            // Check amount
            let mut amount_to_receive:u256= token_amount_base*launch.token_received_per_one_base;

            // TODO User already deposit 
            // Check if amount already exist : create or increase 

            if amount_deposit.deposited > 0 { 
                    // Calculate token redeemable if oracle or not
                    amount_deposit.deposited+=token_amount_base;

                    if !launch.is_base_asset_oracle {
                        amount_to_receive=token_amount_base*launch.token_received_per_one_base +  amount_deposit.total_token_to_be_claimed;
                        let amount_to_claim:u256 = token_amount_base*launch.token_received_per_one_base + amount_deposit.remain_token_to_be_claimed;

                        // TODO uncomment and fix remain balance check and softcap check
                        // assert!(amount_to_receive <= launch.remain_balance, "no token to sell");
                        // assert!( launch.remain_balance >= amount_to_receive, "no token to sell");
                      
                        amount_deposit.total_token_to_be_claimed =amount_to_receive;
                        amount_deposit.remain_token_to_be_claimed =amount_to_claim;
                        amount_deposit.redeemable += amount_to_receive;
                        self.deposit_user_by_launch.write((sender, launch_id), amount_deposit);
                        
                    } else {

                        // TODO better verification for oracle
                        // TODO token usd 
                        
                        let selector_of_token=self.market_felt_by_asset.read(launch.quote_token_address);
                        assert!(selector_of_token == 0_felt252, "token oracle undefined");
                        // let price = get_asset_price_average(selector_of_token);
                        let price_128 = LaunchpadInternalImpl::_get_asset_price_average(@self, selector_of_token);
                        let price:u256=price_128.into();
                        let dollar_price_position = price*token_amount_base;
                        let token_to_receive =launch.token_per_dollar*dollar_price_position;
                        amount_to_receive=token_to_receive;

                        // TODO uncomment and fix remain balance check and softcap check
                        // assert!(amount_to_receive<=launch.remain_balance, "> remain_balance");

                        amount_deposit.total_token_to_be_claimed+=amount_to_receive;
                        amount_deposit.remain_token_to_be_claimed+=amount_to_receive;
                        amount_deposit.redeemable+=amount_to_receive;
                        self.deposit_user_by_launch.write((sender, launch_id), amount_deposit);

                    }

            }
            else {
                    // TODO 
                    // add oracle or simple data to receive depends on amount 
                    if !launch.is_base_asset_oracle {

                        // TODO uncomment and fix remain balance check and softcap check
                        // assert!(amount_to_receive<=launch.remain_balance, "no token to sell");
                        // assert!( launch.remain_balance >= amount_to_receive, "no token to sell");

                        let deposited_amount:DepositByUser= DepositByUser {
                            asset:launch.asset,
                            quote_token_address:launch.quote_token_address,
                            total_amount:token_amount_base,
                            launch_id:launch_id,
                            owner:sender,
                            deposited:token_amount_base,
                            withdraw_amount:0,
                            withdrawn:0,
                            redeemable:amount_to_receive,
                            refunded:0,
                            is_canceled:false,
                            remain_token_to_be_claimed:amount_to_receive,
                            total_token_to_be_claimed:amount_to_receive,
                        };

                        self.deposit_user_by_launch.write((sender, launch_id), deposited_amount);

                    } else {
                        // TODO add oracle or simple data to receive depends on amount 

                        // Oracle calculation
                        // Per dollar calculation with quote_token_address
                        let selector_of_token=self.market_felt_by_asset.read(launch.quote_token_address);
                        assert!(selector_of_token == 0_felt252, "token oracle undefined");
                        let price_u128 = LaunchpadInternalImpl::_get_asset_price_average(@self, selector_of_token);
                        let price:u256=price_u128.into();
                        let dollar_price_position= price*token_amount_base;
                        amount_to_receive=dollar_price_position*launch.token_per_dollar;
                        // TODO uncomment and fix remain balance check and softcap check
                        // assert!(amount_to_receive<=launch.remain_balance, "no token to sell");

                        let deposited_amount_oracle:DepositByUser= DepositByUser {
                            asset:launch.asset,
                            quote_token_address:launch.quote_token_address,
                            total_amount:token_amount_base,
                            launch_id:launch_id,
                            owner:sender,
                            deposited:token_amount_base,
                            withdraw_amount:0,
                            withdrawn:0,
                            redeemable:amount_to_receive,
                            refunded:0,
                            is_canceled:false,
                            remain_token_to_be_claimed:amount_to_receive,
                            total_token_to_be_claimed:amount_to_receive,
                        };
                        self.deposit_user_by_launch.write((sender, launch_id), deposited_amount_oracle);

                    }
                   
            }

            //  TODO TODO_URGENT fix
            // Fix Substract amount remain in sale 
            // launch.remain_balance-=amount_to_receive; // TODO remain balance check above 
            launch.amounts.deposited+=token_amount_base;
            self.launchs.write(launch_id, launch);

            // Send token
            IERC20Dispatcher {contract_address:quote_token_address}.transfer_from(sender, contract, token_amount_base);

            self.emit(EventDepositSend {id:launch_id, owner: sender, deposit:amount_deposit.clone()});
            launch_id
        }
        

        // TODO finish withdraw and test
        fn withdraw_token(ref self:ContractState,
            launch_id:u64
        )-> u64 {

            let sender = get_caller_address();
            let launch=self.launchs.read(launch_id);
            let contract= get_contract_address();
            // Check timestamp
            let timestamp=get_block_timestamp();
            assert!(timestamp>launch.end_date, "launch not finish");

            // Check is cancel 
            assert!(!launch.is_canceled, "launch cancel");
            
            // TODO
            // Verify softcap ok
            // assert!(launch.amounts.deposited>=launch.soft_cap, "soft_cap not reach");

            let mut amount_deposit = self.deposit_user_by_launch.read((sender, launch_id));
            assert!(amount_deposit.deposited>0, "no buy");
            assert!(amount_deposit.remain_token_to_be_claimed>0, "no remain balance");
            // Decrease amount
            // TODO
            // Check oracle launch or not 
            // Send erc20
            if !launch.is_base_asset_oracle {
                // Send amount by claim 
                let amount_to_send=amount_deposit.remain_token_to_be_claimed;

                IERC20Dispatcher{contract_address:launch.asset}.transfer(amount_deposit.owner, amount_to_send );
                amount_deposit.remain_token_to_be_claimed=0;
                self.deposit_user_by_launch.write((sender, launch_id), amount_deposit);

            } else {
                // TODO check Pragma
                // TODO : Oracle 
                // Calculate price in dollar
                let amount_to_send=amount_deposit.remain_token_to_be_claimed;
                IERC20Dispatcher{contract_address:launch.quote_token_address}.transfer(amount_deposit.owner, amount_to_send );
                amount_deposit.remain_token_to_be_claimed=0;
                self.deposit_user_by_launch.write((sender, launch_id), amount_deposit);

            }

            launch_id
        }


        /// Views read functions 
        // VIEW 
        fn get_launch_by_id(self:@ContractState, launch_id:u64) -> Launch {

            self.launchs.read(launch_id)
        }

        fn get_is_dollar_paid_launch(self:@ContractState) -> bool {
            self.is_paid_dollar_launch.read()
        }

        fn get_address_token_to_pay_launch(self:@ContractState) -> ContractAddress {
            self.address_token_to_pay_launch.read()
        }

        fn get_amount_paid_dollar_launch(self:@ContractState) -> u256 {
            self.amount_paid_dollar_launch.read()
        }

        fn get_price_token_selector(self:@ContractState, selector:felt252) -> u256 {
            let price_128 = LaunchpadInternalImpl::_get_asset_price_average(self, selector);
            let price:u256=price_128.into();
            price
        }

        fn get_asset_price_median_selector(self:@ContractState, selector:felt252) -> u256 {
            let price = LaunchpadInternalImpl::_get_asset_price_median_converted(self, selector);
            price
        }
     
        fn get_amount_token_to_pay_launch(self:@ContractState
        // , token_address:ContractAddress
        ) -> u256 {
            let token_address= self.address_token_to_pay_launch.read();
            let selector_of_token=self.market_felt_by_asset.read(token_address);
            // let price_128 = LaunchpadInternalImpl::_get_asset_price_average(self, selector_of_token);
            let output = LaunchpadInternalImpl::_get_asset_price_average_pragma(self, selector_of_token);
            let price_128:u128 = output.price;
            // TODO fix conversion u128 to u256
            let decimals: u128 = output.decimals.into();
            let multiplier: u128 = pow(10, decimals);
            // let price:u256= price_128*multiplier;
            let price:u256= (price_128*multiplier).into();
            // let price:u256=price_128.into();
            let dollar_to_pay=self.amount_paid_dollar_launch.read();
            let token_amount_to_pay=dollar_to_pay/price;
            token_amount_to_pay
        }

        // TODO OLD CONVERSION USE FIX ABOVE
        //    fn get_amount_token_to_pay_launch(self:@ContractState
        // // , token_address:ContractAddress
        // ) -> u256 {
        //     let token_address= self.address_token_to_pay_launch.read();
        //     let selector_of_token=self.market_felt_by_asset.read(token_address);
        //     let price_128 = LaunchpadInternalImpl::_get_asset_price_average(self, selector_of_token);
        //     let price:u256= (price_128*multiplier).into();
        //     // let price:u256=price_128.into();
        //     let dollar_to_pay=self.amount_paid_dollar_launch.read();
        //     let token_amount_to_pay=dollar_to_pay/price;
        //     token_amount_to_pay
        // }


        fn get_amount_token_to_pay_launch_median(self:@ContractState
        // , token_address:ContractAddress
        ) -> u256 {
            let token_address= self.address_token_to_pay_launch.read();
            let selector_of_token=self.market_felt_by_asset.read(token_address);
            // let price_128 = LaunchpadInternalImpl::_get_asset_price_median(self, selector_of_token);
              let output = LaunchpadInternalImpl::_get_asset_price_average_pragma(self, selector_of_token);

            let price_128:u128 = output.price;
              // TODO fix conversion u128 to u256
            let decimals: u128 = output.decimals.into();
            let multiplier: u128 = pow(10, decimals);
            let price:u256= (price_128*multiplier).into();
            // let price:u256=price_convert.into();
            let dollar_to_pay=self.amount_paid_dollar_launch.read();
            let token_amount_to_pay=dollar_to_pay/price;
            token_amount_to_pay
        }
        // VIEW get all launchs
        // TODO add indexer and fix loop
        fn get_all_launchs(self:@ContractState) -> Span<Launch> {

            let max_launch_id=self.next_launch_id.read();
            let mut launchs:Array<Launch> = ArrayTrait::new();
            let mut i=1;
            loop {

                if i>= max_launch_id {
                    break launchs.span();
                }

                let launch = self.launchs.read(i);
                launchs.append(launch);
                i+=1;
            }
        }

        fn get_launchs_by_owner(self:@ContractState, owner:ContractAddress) -> Span<Launch> {

            let max_launch_id=self.next_launch_id.read();
            let mut launchs:Array<Launch> = ArrayTrait::new();
            let mut i=1;
            loop {

                if i>= max_launch_id {
                    break launchs.span();
                }

                let launch = self.launchs.read(i);
                if launch.owner == owner {
                    launchs.append(launch);
                }
                i+=1;
            }
        }

        // VIEW 
        // TODO add indexer and fix big loop
        fn get_deposit_by_users(self:@ContractState, address:ContractAddress) -> Span<DepositByUser> {
            let max_launch_id=self.next_launch_id.read();

            let mut deposits:Array<DepositByUser> = ArrayTrait::new();
            // let deposit_user_by_launch=self.deposit_user_by_launch.read((address,0));
            let mut i = 1;
            loop {

                if i>= max_launch_id {
                    break deposits.span();
                }

                let deposit = self.deposit_user_by_launch.read((address, i));
                deposits.append(deposit);
                i+=1;
            }
        }



    }

}
