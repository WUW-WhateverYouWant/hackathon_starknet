
use starknet::{
    ContractAddress
};

#[starknet::interface]
trait ILaunchpad<TContractState> {
    fn create_launch(ref self:TContractState,asset:ContractAddress, token_buy:ContractAddress, total_amount:u256, start_date:u64, end_date:u64, soft_cap:u256, max_deposit_by_user:u256)-> u64;
    fn refund_launch(ref self:TContractState,launch_id:u64)-> u64;
    fn buy_token(ref self:TContractState,launch_id:u64, token_amount:u256)-> u64;
    fn withdraw_token(ref self:TContractState,launch_id:u64)-> u64;
}

#[starknet::contract]
mod Launchpad {
    use openzeppelin::token::erc20::ERC20Component;
    use openzeppelin::introspection::src5::SRC5Component;
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
    use debug::PrintTrait;
    use zeroable::Zeroable;

    #[derive( Drop, Copy, starknet::Store, Serde )]
    struct Launch {
        asset:ContractAddress,
        owner: ContractAddress,
        broker: ContractAddress,

        // price_per_base:u256,

        total_amount: u256,
        start_date: u64,
        end_date: u64,
        remain_balance: u256,

        token_buy:ContractAddress,
        base_token:ContractAddress,
        is_canceled:bool,
        is_refundable:bool,
        soft_cap:u256,
        // hard_cap:u256,
        max_deposit_by_user:u256,
        
        amounts:AmountLaunch,
        // balance: felt252,
    }

  #[derive( Drop, Copy, starknet::Store, Serde )]
    struct DepositByUser {
        launch_id:u64,
        owner: ContractAddress,
        base_token:ContractAddress,
        total_amount: u256,
        /// The initial amount deposited in the stream, net of fees.
        deposited: u256,
        /// The cumulative amount withdrawn from the stream.
        withdrawn: u256,
        redeemable:u256,
        /// The amount refunded to the sender. Unless the stream was canceled, this is always zero.
        refunded: u256,
        withdraw_amount:u256,
        is_canceled:bool,
    }

    #[derive(Drop, Copy, starknet::Store, Serde, PartialEq)]
    struct AmountLaunch {
        /// The initial amount deposited in the stream, net of fees.
        deposited: u256,
        /// The cumulative amount withdrawn from the stream.
        withdrawn: u256,
        /// The amount refunded to the sender. Unless the stream was canceled, this is always zero.
        refunded: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct LaunchCreated {
        // #[key]
        id:u64,

        launch:Launch,
        owner:ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct EventDepositSend {
        // #[key]
        id:u64,
        deposit:DepositByUser,
        owner:ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        LaunchCreated: LaunchCreated,
        EventDepositSend: EventDepositSend
        // #[flat]
    }

    #[storage]
    struct Storage {
        launchs:LegacyMap::<u64, Launch>,
        tokensBlacklistedForBuy:LegacyMap::<ContractAddress, bool>,
        depositByUserByLaunch:LegacyMap::<u64, DepositByUser>,
        tokensLaunchIds:LegacyMap::<ContractAddress, u64>,
        amountByUser:LegacyMap::<u64, u64>,
        depositByUserLaunch: LegacyMap::<(ContractAddress, u64), DepositByUser>,
        // mapUsers: LegacyMap::<ContractAddress, LegacyMap::<u64, DepositByUser>>
        allowances: LegacyMap::<(ContractAddress, ContractAddress), u256>,

        amountDepositInLaunchByUser:LegacyMap::<u64, u64>,
        depositUserByLaunch:LegacyMap::<(u64, usize), DepositByUser>,
        // depositByLaunch:LegacyMap::<ContractAddress, DepositByUser>,
        //   allowances: LegacyMap::<(ContractAddress, ContractAddress), u256>
        test:LegacyMap::<(ContractAddress, usize), felt252>,
        next_launch_id:u64,
    }
 
    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: felt252,
        symbol: felt252,
        fixed_supply: u256,
        recipient: ContractAddress
    ) {

        self.next_launch_id.write(0);
    }

    #[abi(embed_v0)]
    impl LaunchpadImpl of super::ILaunchpad<ContractState> {
     

        fn refund_launch(
            ref self:ContractState,
            launch_id:u64
        )-> u64 {
            launch_id
        }

        fn withdraw_token(ref self:ContractState,
            launch_id:u64
        )-> u64 {
            launch_id
        }

        fn create_launch(ref self: ContractState,
            asset:ContractAddress,
            token_buy:ContractAddress,
            total_amount:u256,
            start_date:u64,
            end_date:u64,
            soft_cap:u256,
            max_deposit_by_user:u256,

        ) -> u64 {

            // TODO check date
            let timestamp=get_block_timestamp();
            assert!(timestamp>start_date);
            assert!(timestamp<end_date);

            let contract_address=get_contract_address();
            let sender=get_caller_address();

            let current_id= self.next_launch_id.read();
            let next_id= current_id+1;

            let amounts:AmountLaunch = AmountLaunch {
                deposited:total_amount,
                withdrawn:0,
                refunded:0
            };

            let launch:Launch= Launch {
                total_amount:total_amount,
                remain_balance:total_amount,
                start_date:start_date,
                end_date:end_date,
                owner:sender,
                asset:asset,
                broker:sender,
                token_buy:token_buy,
                base_token:token_buy,
                soft_cap:soft_cap,
                is_canceled:false,
                max_deposit_by_user:max_deposit_by_user,
                amounts,
                is_refundable:true

            };
     
            // SEND TOKEN
            IERC20Dispatcher { contract_address: asset }.transfer_from(sender, contract_address, total_amount);

            self.launchs.write(current_id, launch);
            self.next_launch_id.write(next_id);
            self.emit(LaunchCreated { id:current_id, owner: sender, launch:launch.clone()});
            next_id
        }

        // TODO verify and check 
        fn buy_token(
            ref self:ContractState,
            launch_id:u64,
            token_amount:u256
        )-> u64 {

            let sender = get_caller_address();
            let contract = get_contract_address();

            let mut launch = self.launchs.read(launch_id);
            // Check date 
            let timestamp=get_block_timestamp();
            assert!(timestamp<launch.end_date);

            // Check amount
            assert!(token_amount<=launch.remain_balance);
            // Add amount users

            // TODO 
            // Check if amount already exist : create or increase 

            let mut amountDeposit = self.depositByUserLaunch.read((sender, launch_id));
            // let amountDeposit = self.depositByUserLaunch.read((sender, launch_id));
            let base_token= amountDeposit.base_token;
            IERC20Dispatcher {contract_address:base_token}.transfer_from(sender, contract, token_amount);

            if amountDeposit.deposited > 0{ 
                    println!("increase amount deposit");

                    let amount= amountDeposit.deposited+token_amount;
                    amountDeposit.deposited=amount;

                    // amountDeposit.deposited=token_amount;

                    self.depositByUserLaunch.write((sender, launch_id), amountDeposit);
            }
            else {
                    let depositedAmount:DepositByUser= DepositByUser {
                        base_token:launch.base_token,
                        total_amount:token_amount,
                        launch_id:launch_id,
                        owner:sender,
                        deposited:token_amount,
                        withdraw_amount:0,
                        withdrawn:0,
                        redeemable:0,
                        refunded:0,
                        is_canceled:false,

                    };

                    self.depositByUserLaunch.write((sender, launch_id), amountDeposit);
            }
               
            // match amountDeposit {
            //     Option::Some(x) => {
            //         println!("increase amount deposit");

            //         let amount= amountDeposit.deposited+token_amount;
            //         amountDeposit.deposited=amount;

            //         // amountDeposit.deposited=token_amount;

            //         self.depositByUserLaunch.write((sender, launch_id), amountDeposit);
                    
            //     },
            //     Option::None => {

            //         let depositedAmount:DepositByUser= DepositByUser {
            //             base_token:launch.base_token,
            //             total_amount:token_amount,
            //             launch_id:launch_id,
            //             owner:sender,
            //             deposited:token_amount,
            //             withdraw_amount:0,
            //             withdrawn:0,
            //             redeemable:0,
            //             refunded:0,
            //             is_canceled:false,

            //         };

            //         self.depositByUserLaunch.write((sender, launch_id), amountDeposit);
                    
            //     },
            // }

            // Substract amount remain in sale 
            launch.remain_balance-=token_amount;
            self.launchs.write(launch_id, launch);
            self.emit(EventDepositSend {id:launch_id, owner: sender, deposit:amountDeposit.clone()});
            launch_id
        }

    }

}
