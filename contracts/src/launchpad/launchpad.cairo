
use starknet::{
    ContractAddress
};

#[starknet::interface]
trait ILaunchpad<TContractState> {
    fn set(ref self: TContractState, x: u128);
    fn get(self: @TContractState) -> u128;
    fn create_launch(ref self:TContractState,asset:ContractAddress,total_amount:u256,start_date:u64,end_date:u64)-> u64;
}

#[starknet::contract]
mod Launchpad {
    use openzeppelin::token::erc20::ERC20Component;
    use openzeppelin::introspection::src5::SRC5Component;
    use core::starknet::event::EventEmitter;
    use core::result::ResultTrait;
    use starknet::{
        get_caller_address, ContractAddress, contract_address_const, get_contract_address,
        get_block_timestamp
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

    // component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    // component!(path: SRC5Component, storage: src5, event: SRC5Event);

    // #[abi(embed_v0)]
    // impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;


    #[derive( Drop, Copy, starknet::Store, Serde )]
    struct Launch {
        asset:ContractAddress,
        owner: ContractAddress,
        broker: ContractAddress,

        total_amount: u256,
        start_date: u64,
        end_date: u64,
        remain_balance: u256,
        
        amounts:AmountLaunch,
        // amountByUser:LegacyMap::<ContractAddress, AmountLaunch>
        // balance: felt252,
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

    // #[event]
    #[derive(Drop, starknet::Event)]
    struct LaunchCreated {
        // #[key]
        id:u64,

        launch:Launch,
        owner:ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        LaunchCreated: LaunchCreated
        // #[flat]
    }

    #[storage]
    struct Storage {
        launchs:LegacyMap::<u64, Launch>,
        amountByUser:LegacyMap::<u64, u64>,
        stored_data: u128,
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
        fn set(ref self: ContractState, x:u128) {
            self.stored_data.write(x);
        }
        fn get(self: @ContractState) -> u128 {
            self.stored_data.read()
        }

        fn create_launch(ref self: ContractState,
        asset:ContractAddress,
        total_amount:u256,
        start_date:u64,
        end_date:u64,
        
        ) -> u64 {

            let owner= get_caller_address();

            let next_id= self.next_launch_id.read();

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
                owner:owner,
                asset:asset,
                broker:owner,
                amounts

            };
            let contract_address=get_contract_address();
            let sender=get_caller_address();

            // SEND TOKEN
            IERC20Dispatcher { contract_address: asset }.transfer_from(sender, contract_address, total_amount);
            // IERC20Dispatcher{contract_address:asset}.transfer(contract_address, total_amount);

            self.launchs.write(next_id, launch);
            self.next_launch_id.write(next_id+1);
            self.emit(LaunchCreated { id:next_id, owner: owner, launch:launch.clone()});
            next_id
        }
    }

}
