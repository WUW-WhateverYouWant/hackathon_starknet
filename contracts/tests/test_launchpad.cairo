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
// use snforge_std::{
//     ContractClass, ContractClassTrait, CheatTarget, declare, start_prank, stop_prank, TxInfoMock,
//     start_warp, stop_warp
// };
// use starknet::ContractAddress;
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
    // use wuw_contracts::launchpad::*;
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

// Deploys a simple instance of the memcoin to test ERC20 basic entrypoints.
fn deploy_standalone_memecoin() -> (IERC20Dispatcher, ContractAddress) {
    // Deploy the locker associated with the memecoin.

    // Deploy the memecoin with the default parameters.
    let contract = declare('UnruggableMemecoin');
    let mut calldata = array![OWNER().into(), NAME().into(), SYMBOL().into(),];
    Serde::serialize(@DEFAULT_INITIAL_SUPPLY(), ref calldata);
    Serde::serialize(@INITIAL_HOLDERS(), ref calldata);
    Serde::serialize(@INITIAL_HOLDERS_AMOUNTS(), ref calldata);
    let contract_address = contract.deploy(@calldata).expect('failed to deploy memecoin');
    let memecoin = IERC20Dispatcher { contract_address };

    // Set the transaction_hash to an arbitrary value - used to test the
    // multicall buy prevention feature.
    // let mut tx_info: TxInfoMock = Default::default();
    // tx_info.transaction_hash = Option::Some(1234);
    // snforge_std::start_spoof(CheatTarget::One(memecoin.contract_address), tx_info);

    (memecoin, contract_address)
}


  use wuw_contracts::interfaces::erc20::{
        IERC20,
        IERC20Dispatcher,
        IERC20DispatcherTrait
    };

    fn deploy_setup_erc20(
        name: felt252, symbol: felt252, initial_supply: u256, recipient: ContractAddress
    )  {
        let token_contract = declare('ERC20');
        let mut calldata = array![name, symbol];
        Serde::serialize(@initial_supply, ref calldata);
        Serde::serialize(@recipient, ref calldata);
        let token_addr = token_contract.deploy(@calldata).unwrap();
        // let token_dispatcher = ERC20ABI { contract_address: token_addr };
        // (token_dispatcher, token_addr)
    }

    // fn deploy_contract() {
    fn deploy_contract()  {
        let contract = declare('Launchpad');
        // Alternatively we could use `deploy_syscall` here

        let sender=get_caller_address();
        let name:felt252='TEST_NAME';
        let symbol:felt252='TEST_SYMBOL';
        // let supply:felt252="100";
        let sender_felt=ContractAddressIntoFelt252::into(sender);
        let mut contract_args= array![name,symbol, 100, sender_felt ];
        Serde::serialize(@sender_felt, ref contract_args);
        // Create a Dispatcher object that will allow interacting with the deployed contract
        let contract_address = contract.deploy(@contract_args);
        // contract
    }

     #[test]
    fn deploy() {
        // First declare and deploy a contract
        deploy_contract();
    }


    // #[test]
    // fn test_token_mint() {

    //         let token_contract = declare('ERC20Mintable');
    //         let sender=get_caller_address();
    //         let name:felt252='TEST_NAME';
    //         let symbol:felt252='TEST_SYMBOL';
    //         let sender_felt=ContractAddressIntoFelt252::into(sender);
    //         let initial_supply:felt252=100;
    //         let mint=100;
       
    //         let mut calldata = array![name, symbol, sender_felt];
    //         // Serde::serialize(@sender_felt, ref calldata);

    //         // let token_addr = token_contract.deploy(@calldata);
    //         // let token_addr = token_contract.deploy(@calldata).unwrap();
    //         let token_addr = token_contract.deploy(@calldata).expect('failed to deploy erc20');
    //         // let token_addr = token_contract.deploy(@calldata);

    //         // let token= ERC20ABI { contract_address: token_addr };
    //         // let token= ERC20ABIDispatcher { contract_address: token_addr.into() };
    //         let token= ERC20ABIDispatcher { contract_address: token_addr };


    //         let token=IERC20Dispatcher {contract_address:token_addr};
    //         // let token=IUnruggableMemecoin {contract_address:token_addr};.
    //         let balance= token.balanceOf(sender);
    //         // token.transfer_from(sender, sender, mint);
    //         // token.transfer(sender, sender, mint);
    //         // token.transfer_from(sender, sender, mint);
    //         // let token = DualCaseERC20 { contract_address: token_addr };
    //         // token.transfer_from(sender, sender, mint);
    //         // ERC20ABI { contract_address: token_addr }.transfer(to, amount.into());
    //         // ERC20MintableDispatcher { contract_address: token_addr }.transfer(to, amount.into());


    // }

}