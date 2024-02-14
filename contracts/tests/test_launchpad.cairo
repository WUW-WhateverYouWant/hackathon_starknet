use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const,
    ClassHash,
    get_block_timestamp,
    ContractAddressIntoFelt252
    
};

use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, RevertedTransaction, CheatTarget,
    TxInfoMock,
    start_warp, stop_warp,
};

use core::traits::TryInto;
use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use wuw_contracts::interfaces::erc20::{
    IERC20Dispatcher, IERC20DispatcherTrait
};

#[cfg(test)]
mod test_launchpad {
    

    fn FACTORY_ADDRESS() -> ContractAddress {
        'factory_address'.try_into().unwrap()
    }

    const DEFAULT_MIN_LOCKTIME: u64 = 15_721_200; // 6 months
    const DEFAULT_LOCK_AMOUNT: u256 = 100;

    fn LOCK_POSITION_ADDRESS() -> ContractAddress {
        'lock_position_address'.try_into().unwrap()
    }


    // Constants
    fn OWNER() -> ContractAddress {
        'owner'.try_into().unwrap()
    }

    fn RECIPIENT() -> ContractAddress {
        'recipient'.try_into().unwrap()
    }

    fn SPENDER() -> ContractAddress {
        'spender'.try_into().unwrap()
    }

    fn ALICE() -> ContractAddress {
        'alice'.try_into().unwrap()
    }

    fn BOB() -> ContractAddress {
        'bob'.try_into().unwrap()
    }

    fn NAME() -> felt252 {
        'name'.try_into().unwrap()
    }

    fn SYMBOL() -> felt252 {
        'symbol'.try_into().unwrap()
    }

    fn INITIAL_HOLDER_1() -> ContractAddress {
        'initial_holder_1'.try_into().unwrap()
    }

    fn INITIAL_HOLDER_2() -> ContractAddress {
        'initial_holder_2'.try_into().unwrap()
    }

    fn INITIAL_HOLDERS() -> Span<ContractAddress> {
        array![INITIAL_HOLDER_1(), INITIAL_HOLDER_2()].span()
    }

    // Hold 5% of the supply each - reaching 10% of the supply, the maximum allowed
    fn INITIAL_HOLDERS_AMOUNTS() -> Span<u256> {
        array![1_050_000 , 1_050_000].span()
        // array![1_050_000 * pow_256(10, 18), 1_050_000 * pow_256(10, 18)].span()
    }

    fn DEPLOYER() -> ContractAddress {
        'deployer'.try_into().unwrap()
    }

    fn SALT() -> felt252 {
        'salty'.try_into().unwrap()
    }

    fn DEFAULT_INITIAL_SUPPLY() -> u256 {
        21_000_000 
        // 21_000_000 * pow_256(10, 18)
    }

    fn LOCK_MANAGER_ADDRESS() -> ContractAddress {
        'lock_manager'.try_into().unwrap()
    }

    fn UNLOCK_TIME() -> u64 {
        starknet::get_block_timestamp() + DEFAULT_MIN_LOCKTIME
    }

    const ETH_DECIMALS: u8 = 18;
    const TRANSFER_RESTRICTION_DELAY: u64 = 1000;
    const MAX_PERCENTAGE_BUY_LAUNCH: u16 = 200; // 2%

    use wuw_contracts::tokens::erc20::erc20_mintable:: {
        ERC20Mintable
    };
       use openzeppelin::token::erc20::dual20::{
         DualCaseERC20,
    };
    use wuw_contracts::launchpad::launchpad::{
        Launchpad,
        ILaunchpad,
        ILaunchpadDispatcher,
        ILaunchpadDispatcherTrait
    };

    use array::ArrayTrait;
    use result::ResultTrait;
    use snforge_std::{
            declare, ContractClassTrait, start_prank, stop_prank, RevertedTransaction, CheatTarget,
    TxInfoMock

     };
    use starknet::{
        ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const,
        ClassHash,
        get_block_timestamp,
        ContractAddressIntoFelt252
        
    };
    use debug::PrintTrait;
    // Math
    fn pow_256(self: u256, mut exponent: u8) -> u256 {
        if self.is_zero() {
            return 0;
        }
        let mut result = 1;
        let mut base = self;

        loop {
            if exponent & 1 == 1 {
                result = result * base;
            }

            exponent = exponent / 2;
            if exponent == 0 {
                break result;
            }

            base = base * base;
        }
    }

    use wuw_contracts::interfaces::erc20::{
            IERC20,
            IERC20Dispatcher,
            IERC20DispatcherTrait
    };

    fn deploy_setup_erc20(
        // name: felt252, symbol: felt252, initial_supply: u256, recipient: ContractAddress
    ) -> ContractAddress {
        let token_contract = declare('ERC20Mintable');
        let sender=get_caller_address();
        let name:felt252='TEST_NAME';
        let symbol:felt252='TEST_SYMBOL';
        let sender_felt=ContractAddressIntoFelt252::into(OWNER());
        let initial_supply:felt252=100;

        let mut contract_args = array![name, symbol, sender_felt, initial_supply];
        // Serde::serialize(@sender_felt, ref contract_args);
        Serde::serialize(@initial_supply, ref contract_args);

        let token_addr = token_contract.deploy(@contract_args).unwrap();
        let erc20=IERC20Dispatcher {contract_address:token_addr};
        token_addr
    }


    fn deploy_launchpad(
        sender: ContractAddress
    ) -> ContractAddress {
        let token_contract = declare('Launchpad');
        let sender_felt=ContractAddressIntoFelt252::into(sender);
        let mut calldata = array![sender_felt];

        // let mut calldata = array![sender_felt];
        // Serde::serialize(@sender_felt, ref calldata);
        let token_addr = token_contract.deploy(@calldata).unwrap();
        token_addr
    }

    fn deploy_contract()  {
    }

    #[test]
    fn deploy() {
        // First declare and deploy a contract
        let sender=get_caller_address();
        let address= deploy_launchpad(sender);
    }


    #[test]
    fn test_launchpad_all() {
        // First declare and deploy a contract
        let deployer=get_caller_address();
        let sender=OWNER();
        let sender_felt=ContractAddressIntoFelt252::into(OWNER());
        let launchpad_address= deploy_launchpad(sender);

        // start_prank(CheatTarget::One(launchpad_address), OWNER());

        let erc20_address=deploy_setup_erc20();
        // let erc20_base=deploy_setup_erc20();

        let erc20= IERC20Dispatcher{contract_address:erc20_address};
        let mut total_amount:u256 = 1;

        erc20.approve(launchpad_address, total_amount);
        let launchpad = ILaunchpadDispatcher{contract_address:launchpad_address};
        let base_asset_token_address:ContractAddress=erc20_address;
        // let start_date:u64=get_block_timestamp()+1000;

        let start_date:u64 = 1_707_851_123_736+5000;
        let end_date:u64 =start_date+10000;
        // let end_date:u64 =start_date+10_000;
        // let start_date:u64 = 1000;
        // let end_date:u64 =5000;

        println!("start_date {}", start_date);
        println!("end_date {}", end_date);
        let token_received_per_one_base:u256 =1;
        let soft_cap:u256 =1;
        let max_deposit_by_user:u256 = 1;
        total_amount = 10;


        println!("create_launch");
        // println!("erc20_address {}",erc20_address);
        // println!("base_asset_token_address {}",base_asset_token_address);
        // println!("total_amount {}",total_amount);
        // println!("token_received_per_one_base {}",token_received_per_one_base);
        // println!("soft_cap {}",soft_cap);
        // println!("max_deposit_by_user {}",max_deposit_by_user);
        start_prank(CheatTarget::One(launchpad_address), OWNER());
       start_warp(CheatTarget::One(launchpad_address), 100);

        let launch_id= launchpad.create_launch(
            erc20_address.into(),
            base_asset_token_address.into(),
            total_amount,
            token_received_per_one_base,
            start_date,
            end_date,
            soft_cap,
            max_deposit_by_user

        );

        let launch = launchpad.get_launch_by_id(launch_id);

        println!("launch {}", launch.remain_balance);

        assert!(launch.total_amount== total_amount, "not_total_amount");

        println!("approve before buy token");

        erc20.approve(launchpad_address,total_amount);
        println!("try buy token");

        let buy_position = launchpad.buy_token(
            launch_id,
            total_amount,
        );
        
    }

}