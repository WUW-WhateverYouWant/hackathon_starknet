use starknet::testing;

use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, RevertedTransaction, CheatTarget,
    TxInfoMock
};
use starknet::{
    ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const,
    ClassHash,
    ContractAddressIntoFelt252
    
};

fn deploy_setup_erc20(
    name: felt252, symbol: felt252, initial_supply: u256, recipient: ContractAddress
) -> ContractAddress {
    let token_contract = declare('ERC20Mintable');
    let mut calldata = array![name, symbol];
    Serde::serialize(@initial_supply, ref calldata);
    Serde::serialize(@recipient, ref calldata);
    let token_addr = token_contract.deploy(@calldata).unwrap();
    // let token_dispatcher = ERC20ABI { contract_address: token_addr };
    token_addr
    // (token_dispatcher, token_addr)
}

fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}

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

