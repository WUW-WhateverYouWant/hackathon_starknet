
use starknet::ContractAddress;
use pragma_lib::abi::{
    ISummaryStatsABIDispatcher, ISummaryStatsABIDispatcherTrait
};
use pragma_lib::types::{AggregationMode, DataType};

// const SUMMARY_STATS_ADDRESS : ContractAddress  = 0x00000000000000000000;

// fn comupute_twap(data_type : DataType, aggregation_mode : AggregationMode) -> u128 {
//     let start_tick = 1691315416;
//     let end_tick = 1691415416;
//     let num_samples = 200;
//     let summary_dispatcher = ISummaryStatsABIDispatcher { contract_address: SUMMARY_STATS_ADDRESS}
//     let (twap, decimals) = summary_dispatcher.calculate_twap(
//         data_type,
//         aggregation_mode,
//         time,
//         start_time,
//     );
//     return twap; // will return the volatility multiplied by 10^decimals
// }

// //USAGE

// let pair_id : felt252 = "ETH/USD";
// let expiration_timestamp = 1691515416;

// //SPOT
// let twap = compute_twap(DataType::Spot(pair_id), AggregationMode::Median(()));
// //FUTURES
// let twap = compute_twap(DataType::Future((pair_id, expiration_timestamp)), AggregationMode::Median(()));
