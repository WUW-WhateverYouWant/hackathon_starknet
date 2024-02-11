use starknet::{
        ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const,
        ClassHash,
        ContractAddressIntoFelt252
};


#[starknet::interface]
trait IJediswapV1<TState> {

    // ************************************
    // * snake_case
    // ************************************

}


#[starknet::interface]
trait IJediswapFactoryV2<TState> {

    // ************************************
    // * snake_case
    // ************************************

    // Views 
    fn get_pool(ref:@TState, token_a:ContractAddress, token_b:ContractAddress, fee:u32)-> ContractAddress;
    fn fee_amount_tick_spacing(ref:@TState, fee:u32) -> u32;
    fn get_fee_protocol(ref:@TState)-> u8;

    // Write 
    fn create_pool(ref self:TState, token_a:ContractAddress, token_b:ContractAddress, fee:u32) -> ContractAddress;

}

#[starknet::interface]
trait IJediswapRouterV2<TState> {

    // ************************************
    // * snake_case
    // ************************************

}

#[starknet::interface]
trait IJediswapNFTRouterV2<TState> {

    // ************************************
    // * snake_case
    // ************************************

    // Write 
    fn mint(ref self:TState, token_id:u256, token_b:ContractAddress, fee:u32)-> (u256, u128, u256, u256);
    fn create_and_initialize_pool(ref self:TState, token0:u256, token1:ContractAddress, fee:u32, sqrt_price_X96:u256)-> ContractAddress;

    // Views
    fn get_position(ref:@TState, token_id:u256, token_b:ContractAddress, fee:u32)-> ContractAddress;


}



