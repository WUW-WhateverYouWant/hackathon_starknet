use starknet::{
    ContractAddress
    
};

#[derive( Drop, Copy, starknet::Store, Serde )]
struct Launch {
    launch_id:u64,
    asset:ContractAddress,
    owner: ContractAddress,
    broker: ContractAddress,
    base_asset_token_address:ContractAddress,

    // price_per_base:u256,

    total_amount: u256,
    start_date: u64,
    end_date: u64,
    remain_balance: u256,
    token_received_per_one_base:u256,
    is_canceled:bool,
    is_refundable:bool,
    soft_cap:u256,
    // hard_cap:u256,
    max_deposit_by_user:u256,
    is_base_asset_oracle:bool,

    // 0 if not oracle 
    //  otherwise price listing per dollar
    token_per_dollar:u256, 
    
    amounts:AmountLaunch,
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

    /// Calculate token depends on:
    /// token_received_per_one_base or token_per_dollar

    remain_token_to_be_claimed:u256,
    total_token_to_be_claimed:u256,
}




#[derive( Drop, Copy, starknet::Store, Serde )]
struct DepositByUser {
    launch_id:u64,
    owner: ContractAddress,
    base_asset_token_address:ContractAddress,
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
    /// Calculate token depends on:
    /// token_received_per_one_base or token_per_dollar
    remain_token_to_be_claimed:u256,
    total_token_to_be_claimed:u256,
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

#[derive(Drop, starknet::Event)]
struct EventBaseOracleSet {
    asset:ContractAddress,
    is_oracle:bool,
}
