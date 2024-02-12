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
mod test_oracle {
    use pragma_lib::types::{DataType, AggregationMode, PragmaPricesResponse};
    use pragma_lib::abi::{
        IPragmaABIDispatcher, IPragmaABIDispatcherTrait, ISummaryStatsABIDispatcher,
        ISummaryStatsABIDispatcherTrait
    };
    const KEY :felt252 = 18669995996566340; // felt252 conversion of "BTC/USD", can write const KEY : felt252 = 'BTC/USD'
    const OKX: felt252 = 'OKX'; // felt252 conversion of "OKX"
    const BINANCE: felt252 = 'BINANCE'; // felt252 conversion of "BINANCE"


    use array::ArrayTrait;
    use result::ResultTrait;
    use debug::PrintTrait;

    use snforge_std::{
            declare, ContractClassTrait, start_prank, stop_prank, RevertedTransaction, CheatTarget,
    TxInfoMock

     };
    use starknet::{
        ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const,
        ClassHash,
        ContractAddressIntoFelt252
        
    };

    fn get_asset_price_median(oracle_address: ContractAddress, asset : DataType) -> u128  { 
        let oracle_dispatcher = IPragmaABIDispatcher{contract_address : oracle_address};
        let output : PragmaPricesResponse= oracle_dispatcher.get_data(asset, AggregationMode::Median(()));

        return output.price;
    }

    fn get_asset_price_average(oracle_address: ContractAddress, asset : DataType) -> u128  { 
        let oracle_dispatcher = IPragmaABIDispatcher{contract_address : oracle_address};
        let output : PragmaPricesResponse= oracle_dispatcher.get_data(asset, AggregationMode::Mean(()));

        return output.price;
    }

    fn get_asset_price_average_sources(oracle_address: ContractAddress, asset : DataType, sources : Span<felt252>) -> u128  { 
        let oracle_dispatcher = IPragmaABIDispatcher{contract_address : oracle_address};
        let output : PragmaPricesResponse= oracle_dispatcher.get_data_for_sources(asset, AggregationMode::Mean(()), sources);

        return output.price;
    }
    
    #[test]
    fn test_oracle_functions()  {

        let oracle_address : ContractAddress = contract_address_const::<0x06df335982dddce41008e4c03f2546fa27276567b5274c7d0c1262f3c2b5d167>();
        // let oracle_address:ContractAddress = contract_address_const::<0x2a85bd616f912537c50a49a4076db02c00b29b2cdc8a197ce92ed1837fa875b>(); // Mainet
        // let oracle_address:ContractAddress = contract_address_const::<0x36031daa264c24520b11d93af622c848b2499b66b41d611bac95e13cfca131a>(); // SEPOLIA

        let expiration_timestamp = 1691395615; //in seconds
        let price_future = get_asset_price_median(oracle_address, DataType::FutureEntry((KEY,expiration_timestamp )));
        println!("price_future {}", price_future);

        let price_average = get_asset_price_average(oracle_address, DataType::SpotEntry(KEY));
        println!("price_average {}", price_average);


    }

    // fn deploy_contract()  {
    //     let contract = declare('OraclePragma');
    //     // Alternatively we could use `deploy_syscall` here
    //     let pragma_address:ContractAddress= contract_address_const::<0x36031daa264c24520b11d93af622c848b2499b66b41d611bac95e13cfca131a>();
    //     let oracle_address : ContractAddress = contract_address_const::<0x06df335982dddce41008e4c03f2546fa27276567b5274c7d0c1262f3c2b5d167>();
       
    // }


}