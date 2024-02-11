
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
    fn buy_token(ref self:TContractState,launch_id:u64, token_amount_base:u256)-> u64;
    fn withdraw_token(ref self:TContractState,launch_id:u64)-> u64;
    fn cancel_launch(ref self:TContractState,launch_id:u64)-> u64;
    fn set_oracle_base_asset(ref self:TContractState,asset_address:ContractAddress, is_oracle:bool);
   
    // TODO add getters before indexer 
    fn get_launch_by_id(self: @TContractState, launch_id:u64) -> Launch;
    fn get_all_launchs(self: @TContractState)-> Span<Launch>;
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
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,

        #[flat]
        SRC5Event: SRC5Component::Event,
    }

    #[storage]
    struct Storage {
        launchs:LegacyMap::<u64, Launch>,
        depositByUserLaunch: LegacyMap::<(ContractAddress, u64), DepositByUser>,
        tokensBlacklistedForBuy:LegacyMap::<ContractAddress, bool>,
        tokensBoosted:LegacyMap::<ContractAddress, bool>,
        is_assets_base_oracle:LegacyMap::<ContractAddress, bool>,
        
        tokensLaunchIds:LegacyMap::<ContractAddress, u64>,
        next_launch_id:u64,

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

        /// Views read functions 
        // VIEW 
        fn get_launch_by_id(self:@ContractState, launch_id:u64) -> Launch {

            self.launchs.read(launch_id)
        }

        // VIEW get all launchs
        // TODO add indexer
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

        // VIEW 
        // TODO add indexer
        // fn get_deposit_by_users(self:@ContractState, launch_id:u64) -> Launch {

        //     self.launchs.read(launch_id)
        // }


        // CREATOR POOL
        // OWNER OF LAUNCHPAD


        // LAUNCH OWNER
        fn refund_launch(
            ref self:ContractState,
            launch_id:u64
        )-> u64 {

            launch_id
        }

        fn create_launch(ref self: ContractState,
            asset:ContractAddress,
            base_asset_token_address:ContractAddress,
            total_amount:u256,
            token_received_per_one_base:u256,
            start_date:u64,
            end_date:u64,
            soft_cap:u256,
            max_deposit_by_user:u256,

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

            // Update
            launch.is_canceled=true;
            self.launchs.write(launch_id, launch);


            launch_id
        }


        // USERS call

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

            // Check amount
            assert!(token_amount_base<=launch.remain_balance);
            // Add amount users

            // Check if amount already exist : create or increase 

            let mut amountDeposit = self.depositByUserLaunch.read((sender, launch_id));
            let base_asset_token_address= amountDeposit.base_asset_token_address;
            IERC20Dispatcher {contract_address:base_asset_token_address}.transfer_from(sender, contract, token_amount_base);

            // TODO oracle calculation ETH
            let token_amount=1;
            let amount_to_receive:u256= token_amount_base*launch.token_received_per_one_base;
            // TODO User already deposit 
            if amountDeposit.deposited > 0{ 
                    // Calculate token redeemable if oracle or not
                    amountDeposit.deposited+=token_amount_base;

                    if !launch.is_base_asset_oracle {

                        let amount_to_receive:u256=token_amount_base*launch.token_received_per_one_base +  amountDeposit.total_token_to_be_claimed;
                        let amount_to_claim:u256=  token_amount_base*launch.token_received_per_one_base + amountDeposit.remain_token_to_be_claimed;
                        amountDeposit.total_token_to_be_claimed=amount_to_receive;
                        amountDeposit.remain_token_to_be_claimed=amount_to_claim;
                        self.depositByUserLaunch.write((sender, launch_id), amountDeposit);
                        
                    } else {

                        // TODO better verification for oracle
                        // TODO token usd 

                        let amount_to_receive:u256=token_amount_base*launch.token_received_per_one_base +  amountDeposit.total_token_to_be_claimed;
                        let amount_to_claim:u256=  token_amount_base*launch.token_received_per_one_base + amountDeposit.remain_token_to_be_claimed;
                        amountDeposit.total_token_to_be_claimed=amount_to_receive;
                        amountDeposit.remain_token_to_be_claimed=amount_to_claim;
                        self.depositByUserLaunch.write((sender, launch_id), amountDeposit);

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

                        self.depositByUserLaunch.write((sender, launch_id), amountDeposit);
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
                        self.depositByUserLaunch.write((sender, launch_id), amountDeposit);


                    }
                   
            }

            //  TODO
            // Substract amount remain in sale 
            // launch.remain_balance-=token_amount;
            // launch.amounts.deposited+=token_amount;
            self.launchs.write(launch_id, launch);
            self.emit(EventDepositSend {id:launch_id, owner: sender, deposit:amountDeposit.clone()});
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
            
            // Verify softcap ok
            assert!(launch.amounts.deposited>=launch.soft_cap, "soft_cap not reach");

            let mut amountDeposit = self.depositByUserLaunch.read((sender, launch_id));
            assert!(amountDeposit.deposited>0, "no buy");
            assert!(amountDeposit.remain_token_to_be_claimed>0, "no remain balance");
            // Decrease amount
            // TODO
            // Check oracle launch or not 
            // Send erc20
            if !launch.is_base_asset_oracle {
                // Send amount by claim 
                let amount_to_send=amountDeposit.remain_token_to_be_claimed;

                IERC20Dispatcher{contract_address:launch.base_asset_token_address}.transfer_from(contract, amountDeposit.owner, amount_to_send );
                amountDeposit.remain_token_to_be_claimed=0;
                self.depositByUserLaunch.write((sender, launch_id), amountDeposit);

            } else {
                // Oracle 
                // Calculate price in dollar

            }

            launch_id
        }


    }

}
