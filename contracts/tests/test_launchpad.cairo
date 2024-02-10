use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const,
    ClassHash,
    ContractAddressIntoFelt252
    
};

use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, RevertedTransaction, CheatTarget,
    TxInfoMock
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
        Launchpad
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

  

    // fn deploy_contract() {
    fn deploy_contract()  {
        let contract = declare('Launchpad');
        // Alternatively we could use `deploy_syscall` here

        let sender=get_caller_address();
        let name:felt252='TEST_NAME';
        let symbol:felt252='TEST_SYMBOL';
        let sender_felt=ContractAddressIntoFelt252::into(sender);
        let mut contract_args= array![name,symbol, 100, sender_felt ];
        Serde::serialize(@sender_felt, ref contract_args);
       
    }

     #[test]
    fn deploy() {
        // First declare and deploy a contract
        deploy_contract();
    }

    
    // #[test]
    // fn test_launchpad_all() {
    //     let sender = snforge_std::test_address();
    //     let name:felt252='TEST_NAME';
    //     let symbol:felt252='TEST_SYMBOL';
    //     let sender_felt=ContractAddressIntoFelt252::into(sender);
    //     let token_contract = declare('ERC20Mintable');
    //     let mut calldata = array![name, symbol, sender_felt];
    //     let token_addr = token_contract.deploy(@calldata).unwrap();
    //     let erc20= IERC20Dispatcher{contract_address:token_addr};
    //     // erc20.balance_of(sender);
    //     assert!(erc20.owner()== sender, "no same owner");
    //     // Change the caller address to 123 when calling the contract at the `contract_address` address
    //     // start_prank(CheatTarget::One(token_addr), sender);
    //     println!("Try mint");
    //     // let mint_amount:u256=10_000*10*18;
    //         // let mint_amount:u256=10_000_000*pow_256(10,18);
    //         let mint_amount:u256=10_000*pow_256(10,18);
    //     // erc20.mint(sender, mint_amount);
    //     let recipient = snforge_std::test_address();
    //     erc20.mint(recipient, mint_amount );
    // }


}