mod pragma_oracle {
    
use pragma_lib::abi::{IPragmaABIDispatcher, IPragmaABIDispatcherTrait};
use pragma_lib::types::{AggregationMode, DataType, PragmaPricesResponse};
use starknet::ContractAddress;
use starknet::contract_address::contract_address_const;


const KEY :felt252 = 18669995996566340; // felt252 conversion of "BTC/USD", can also write const KEY : felt252 = 'BTC/USD';

fn get_asset_price_median(oracle_address: ContractAddress, asset : DataType) -> u128  { 
    let oracle_dispatcher = IPragmaABIDispatcher{contract_address : oracle_address};
    let output : PragmaPricesResponse= oracle_dispatcher.get_data(asset, AggregationMode::Median(()));
    return output.price;
}


fn get_asset_price_average(oracle_address: ContractAddress, asset : DataType, sources : Span<felt252>) -> u128  { 
    let oracle_dispatcher = IPragmaABIDispatcher{contract_address : oracle_address};
    let output : PragmaPricesResponse= oracle_dispatcher.get_data_for_sources(asset, AggregationMode::Mean(()), sources);

    return output.price;
}


//USAGE

let oracle_address : ContractAddress = contract_address_const::<0x06df335982dddce41008e4c03f2546fa27276567b5274c7d0c1262f3c2b5d167>();
let price = get_asset_price_median(oracle_address, DataType::SpotEntry(KEY));
}