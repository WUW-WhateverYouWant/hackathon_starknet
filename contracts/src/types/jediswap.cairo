use starknet::{
    ContractAddress
};

#[derive( Drop, Copy, starknet::Store, Serde )]
struct MintParams {
    token0:ContractAddress,
    token1:ContractAddress,
    fee: u32,
    tick_lower:i32,
    tick_upper:i32,
    amount0_desired:u256,
    amount1_desired:u256,
    amount0_min:u256,
    amount1_min:u256,
    recipient:ContractAddress,
    deadline: u64,
   
}
