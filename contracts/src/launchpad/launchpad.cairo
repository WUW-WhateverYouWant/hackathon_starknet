
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
        base_asset_token_address:ContractAddress, 
        total_amount:u256, 
        token_received_per_one_base:u256,
        start_date:u64, 
        end_date:u64, 
        soft_cap:u256,
        max_deposit_by_user:u256,
     
     )-> u64;


    fn create_launch_base_oracle(ref self:TContractState,
        asset:ContractAddress, 
        token_buy:ContractAddress, 
        total_amount:u256, 
        start_date:u64, 
        end_date:u64, 
        soft_cap:u256, 
        max_deposit_by_user:u256,
        token_per_dollar:u256
    )-> u64;

    fn refund_launch(ref self:TContractState,launch_id:u64)-> u64;
    fn refund_deposit_amount(ref self:TContractState, launch_id:u64);
    fn buy_token(ref self:TContractState,launch_id:u64, token_amount_base:u256)-> u64;
    fn withdraw_token(ref self:TContractState,launch_id:u64)-> u64;
    fn cancel_launch(ref self:TContractState,launch_id:u64)-> u64;

    // Admin
    fn set_oracle_base_asset(ref self:TContractState,asset_address:ContractAddress, is_oracle:bool);
    fn set_pragma_address(ref self:TContractState,pragma_oracle_address:ContractAddress);
    fn set_address_jediswap_factory_v2(ref self:TContractState, address_jediswap_factory_v2:ContractAddress);
   
    // Views
    // TODO add getters before indexer 
    fn get_launch_by_id(self: @TContractState, launch_id:u64) -> Launch;
    fn get_all_launchs(self: @TContractState)-> Span<Launch>;
    fn get_launchs_by_owner(self: @TContractState, owner:ContractAddress)-> Span<Launch>;
    fn get_deposit_by_users(self: @TContractState, address:ContractAddress)-> Span<DepositByUser>;
    // fn get_launchs(self: @TContractState) -> Span<Launch>;

}

#[starknet::contract]
mod Launchpad {
    // use super::Launch;
    use wuw_contracts::types::launch:: {
        Launch, AmountLaunch,
        DepositByUser,

        // Event 
        LaunchCreated,
        EventDepositSend,
        EventBaseOracleSet,
        RefundBuyToken,
        PragmaOracleAddressSet,
        SetJediwapV2Factory
    };



    use openzeppelin::token::erc20::ERC20Component;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::access::accesscontrol::AccessControlComponent;

    use core::starknet::event::EventEmitter;
    use core::result::ResultTrait;
    use starknet::{
        get_caller_address, ContractAddress, contract_address_const, get_contract_address,
        get_block_timestamp,
        
    };
 
    use openzeppelin::token::erc20::dual20::{
         DualCaseERC20,
    };
    use wuw_contracts::interfaces::erc20::{
      IERC20Dispatcher,
      IERC20DispatcherTrait
    };
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
        LaunchCreated: LaunchCreated,
        EventDepositSend: EventDepositSend,
        EventBaseOracleSet:EventBaseOracleSet,
        RefundBuyToken:RefundBuyToken,
        PragmaOracleAddressSet:PragmaOracleAddressSet,
        SetJediwapV2Factory:SetJediwapV2Factory,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,

        #[flat]
        SRC5Event: SRC5Component::Event,
    }

    #[storage]
    struct Storage {

        next_launch_id:u64,


        launchs:LegacyMap::<u64, Launch>,
        deposit_user_by_launch: LegacyMap::<(ContractAddress, u64), DepositByUser>,

        // Admin
        tokensBlacklistedForBuy:LegacyMap::<ContractAddress, bool>,
        tokensBoosted:LegacyMap::<ContractAddress, bool>,
        is_assets_base_oracle:LegacyMap::<ContractAddress, bool>,
        tokensLaunchIds:LegacyMap::<ContractAddress, u64>,

        // Management external contracts
        pragma_oracle_address:ContractAddress,
        own_pragma_oracle_address:ContractAddress,
        address_jediswap_factory_v2:ContractAddress,
        market_felt_by_asset:LegacyMap::<ContractAddress, felt252>,

        // Fees management
        protocol_fee_launch_creation:u8,
        base_protocol_fee_launch_creation:u8,
        amount_paid_dollar_launch:u256,
        is_paid_dollar_launch:bool,
        
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
        owner: ContractAddress
    ) {

        // let owner=get_caller_address();
        self.next_launch_id.write(0);
        self.ownable.initializer(owner);

        // AccessControl-related initialization
        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(ADMIN_ROLE, owner);
        self.accesscontrol._grant_role(OWNER_ROLE, owner);
    }


    // TODO implement internal functions and refacto
    #[generate_trait]
    impl LaunchpadInternalImpl of LaunchpadInternalTrait {

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

        // Pragma oracle address
        fn set_pragma_address(ref self:ContractState, pragma_oracle_address:ContractAddress) {
            self.accesscontrol.assert_only_role(ADMIN_ROLE);
            self.pragma_oracle_address.write(pragma_oracle_address);

            // own_pragma_oracle_address
            // self.own_pragma_oracle_address.write(pragma_oracle_address);
            self.emit(PragmaOracleAddressSet{ pragma_oracle_address:pragma_oracle_address});
        }
        /// Views read functions 
        // VIEW 
        fn get_launch_by_id(self:@ContractState, launch_id:u64) -> Launch {

            self.launchs.read(launch_id)
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
            let deposit_user_by_launch=self.deposit_user_by_launch.read((address,0));
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


        // CREATOR POOL
        // OWNER OF LAUNCHPAD

        fn create_launch(ref self: ContractState,
            asset:ContractAddress,
            base_asset_token_address:ContractAddress,
            total_amount:u256,
            token_received_per_one_base:u256,
            start_date:u64,
            end_date:u64,
            soft_cap:u256,
            max_deposit_by_user:u256,
            // is_liquidity:bool TODO add params 
            // liquidity_percent:at least 50%

        ) -> u64 {

            // TODO check date
            let timestamp=get_block_timestamp();
            assert!(timestamp<start_date);
            assert!(timestamp<end_date);
            assert!(start_date<end_date, "start > end");

            let contract_address=get_contract_address();
            let sender=get_caller_address();

            let current_id= self.next_launch_id.read();
            let next_id= current_id+1;

            let amounts:AmountLaunch = AmountLaunch {
                deposited:total_amount,
                withdrawn:0,
                refunded:0,
                total_token_to_be_claimed:total_amount,
                remain_token_to_be_claimed:total_amount,
            };

            let launch:Launch= Launch {
                launch_id:current_id,
                total_amount:total_amount,
                remain_balance:total_amount,
                start_date:start_date,
                end_date:end_date,
                owner:sender,
                asset:asset,
                broker:sender,
                base_asset_token_address:base_asset_token_address,
                soft_cap:soft_cap,
                is_canceled:false,
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

        fn create_launch_base_oracle(ref self: ContractState,
            asset:ContractAddress,
            token_buy:ContractAddress,
            total_amount:u256,
            start_date:u64,
            end_date:u64,
            soft_cap:u256,
            max_deposit_by_user:u256,
            token_per_dollar:u256


        ) -> u64 {

            // Verify base token 
            assert!(self.is_assets_base_oracle.read(asset) == true, "not base oracle token");
            // TODO check date
            let timestamp=get_block_timestamp();
            assert!(timestamp<start_date);
            assert!(timestamp<end_date, "enddate too early");
            assert!(start_date<end_date, "start > end");

            let contract_address=get_contract_address();
            let sender=get_caller_address();

            let current_id= self.next_launch_id.read();
            let next_id= current_id+1;

            let amounts:AmountLaunch = AmountLaunch {
                deposited:total_amount,
                withdrawn:0,
                refunded:0,
                total_token_to_be_claimed:total_amount,
                remain_token_to_be_claimed:total_amount,
            };

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
                base_asset_token_address:token_buy,
                soft_cap:soft_cap,
                is_canceled:false,
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
            assert!(sender == launch.owner, "not owner");

            // Check timestamp
            let timestamp=get_block_timestamp();
            assert!(timestamp<launch.end_date);


            // Token back to owner
            IERC20Dispatcher{contract_address:launch.asset}.transfer_from(contract_address, sender, launch.total_amount);

            // Update
            launch.is_canceled=true;
            self.launchs.write(launch_id, launch);

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

            assert!(timestamp<launch.end_date);

            IERC20Dispatcher { contract_address: launch.asset}.transfer_from(contract_address, sender, launch.total_amount );
            // Update
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
            assert!(timestamp<launch.end_date);

            let mut amount_deposit_by_user = self.deposit_user_by_launch.read((sender, launch_id));

            if amount_deposit_by_user.deposited> 0 {

                let refund= amount_deposit_by_user.deposited;

                IERC20Dispatcher { contract_address: launch.base_asset_token_address}.transfer_from(contract_address, sender, refund );

                amount_deposit_by_user.deposited=0;
                amount_deposit_by_user.refunded=0;

                self.deposit_user_by_launch.write((sender, launch_id), amount_deposit_by_user);
                self.emit(RefundBuyToken { asset_refund: launch.asset, amount_refund:refund})

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
            assert!(timestamp<launch.end_date);

            // Check is cancel 
            assert!(!launch.is_canceled, "launch cancel");


            // Check amount
            assert!(token_amount_base<=launch.remain_balance);
            // Add amount users

            // Check if amount already exist : create or increase 

            let mut amount_deposit = self.deposit_user_by_launch.read((sender, launch_id));
            let base_asset_token_address= amount_deposit.base_asset_token_address;
            IERC20Dispatcher {contract_address:base_asset_token_address}.transfer_from(sender, contract, token_amount_base);

            // TODO oracle calculation ETH
            let token_amount=1;
            let amount_to_receive:u256= token_amount_base*launch.token_received_per_one_base;
            // TODO User already deposit 
            if amount_deposit.deposited > 0{ 
                    // Calculate token redeemable if oracle or not
                    amount_deposit.deposited+=token_amount_base;

                    if !launch.is_base_asset_oracle {

                        let amount_to_receive:u256=token_amount_base*launch.token_received_per_one_base +  amount_deposit.total_token_to_be_claimed;
                        let amount_to_claim:u256=  token_amount_base*launch.token_received_per_one_base + amount_deposit.remain_token_to_be_claimed;
                        amount_deposit.total_token_to_be_claimed=amount_to_receive;
                        amount_deposit.remain_token_to_be_claimed=amount_to_claim;
                        self.deposit_user_by_launch.write((sender, launch_id), amount_deposit);
                        
                    } else {

                        // TODO better verification for oracle
                        // TODO token usd 

                        let amount_to_receive:u256=token_amount_base*launch.token_received_per_one_base +  amount_deposit.total_token_to_be_claimed;
                        let amount_to_claim:u256=  token_amount_base*launch.token_received_per_one_base + amount_deposit.remain_token_to_be_claimed;
                        amount_deposit.total_token_to_be_claimed=amount_to_receive;
                        amount_deposit.remain_token_to_be_claimed=amount_to_claim;
                        self.deposit_user_by_launch.write((sender, launch_id), amount_deposit);

                    }

            }
            else {
                    // TODO 
                    // add oracle or simple data to receive depends on amount 
                    if !launch.is_base_asset_oracle {

                        let amount_to_receive:u256= token_amount_base*launch.token_received_per_one_base ;
                        let depositedAmount:DepositByUser= DepositByUser {
                            base_asset_token_address:launch.base_asset_token_address,
                            total_amount:token_amount_base,
                            launch_id:launch_id,
                            owner:sender,
                            deposited:token_amount_base,
                            withdraw_amount:0,
                            withdrawn:0,
                            redeemable:0,
                            refunded:0,
                            is_canceled:false,
                            remain_token_to_be_claimed:amount_to_receive,
                            total_token_to_be_claimed:amount_to_receive,
                        };

                        self.deposit_user_by_launch.write((sender, launch_id), amount_deposit);
                    } else {
                        // TODO add oracle or simple data to receive depends on amount 

                        // Oracle calculation
                        // Per dollar calculation
                        let amount_to_receive:u256= token_amount_base*launch.token_received_per_one_base ;

                        let depositedAmount:DepositByUser= DepositByUser {
                            base_asset_token_address:launch.base_asset_token_address,
                            total_amount:token_amount_base,
                            launch_id:launch_id,
                            owner:sender,
                            deposited:token_amount_base,
                            withdraw_amount:0,
                            withdrawn:0,
                            redeemable:0,
                            refunded:0,
                            is_canceled:false,
                            remain_token_to_be_claimed:amount_to_receive,
                            total_token_to_be_claimed:amount_to_receive,
                        };
                        self.deposit_user_by_launch.write((sender, launch_id), amount_deposit);


                    }
                   
            }

            //  TODO
            // Substract amount remain in sale 
            // launch.remain_balance-=token_amount;
            // launch.amounts.deposited+=token_amount;
            self.launchs.write(launch_id, launch);
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
            
            // Verify softcap ok
            assert!(launch.amounts.deposited>=launch.soft_cap, "soft_cap not reach");

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

                IERC20Dispatcher{contract_address:launch.base_asset_token_address}.transfer_from(contract, amount_deposit.owner, amount_to_send );
                amount_deposit.remain_token_to_be_claimed=0;
                self.deposit_user_by_launch.write((sender, launch_id), amount_deposit);

            } else {
                // Oracle 
                // Calculate price in dollar

            }

            launch_id
        }


    }

}
