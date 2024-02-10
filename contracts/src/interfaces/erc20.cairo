use starknet::{
        ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const,
        ClassHash,
        ContractAddressIntoFelt252
};


#[starknet::interface]
trait IERC20<TState> {
    // ************************************
    // * Ownership
    // ************************************
    fn owner(self: @TState) -> ContractAddress;
    fn transfer_ownership(ref self: TState, new_owner: ContractAddress);
    fn renounce_ownership(ref self: TState);

    // ************************************
    // * Metadata
    // ************************************
    fn name(self: @TState) -> felt252;
    fn symbol(self: @TState) -> felt252;
    fn decimals(self: @TState) -> u8;

    // ************************************
    // * snake_case
    // ************************************
    fn total_supply(self: @TState) -> u256;
    fn balance_of(self: @TState, account: ContractAddress) -> u256;
    fn allowance(self: @TState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
    fn approve(ref self: TState, spender: ContractAddress, amount: u256) -> bool;
    fn mint(ref self: TState, recipient: ContractAddress, amount: u256) -> bool;


}
