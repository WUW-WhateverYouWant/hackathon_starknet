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

