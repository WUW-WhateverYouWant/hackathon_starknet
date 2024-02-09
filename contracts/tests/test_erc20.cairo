


#[cfg(test)]
mod test_erc20 {
    use wuw_contracts::tokens::erc20::erc20_mintable:: {
        ERC20Mintable
    };
    use array::ArrayTrait;
    use result::ResultTrait;
    use snforge_std::{ declare, ContractClassTrait, start_prank, stop_prank, };
    use starknet::{
        ContractAddress, get_caller_address, Felt252TryIntoContractAddress, contract_address_const,
        ClassHash,
        ContractAddressIntoFelt252
        
    };
    use debug::PrintTrait;
    use wuw_contracts::interfaces::erc20::{
        IERC20,
        IERC20Dispatcher,
        IERC20DispatcherTrait
    };



    #[test]
    fn call_and_invoke() {
        // First declare and deploy a contract
        let contract = declare('ERC20Mintable');

        // Alternatively we could use `deploy_syscall` here

        let sender=get_caller_address();
        let name:felt252='TEST';
        let symbol:felt252='TEST';
        let sender_felt=ContractAddressIntoFelt252::into(sender.into());

        // let mut contract_args= array![name,symbol, sender ];
        let mut contract_args= array![name, symbol, sender_felt.into() ];
        // Serde::serialize(@sender_felt, ref contract_args);

        // let contract_address = contract.deploy(@contract_args).unwrap();
        let contract_address = contract.deploy(@contract_args);

        // Create a Dispatcher object that will allow interacting with the deployed contract
        // let dispatcher = ERC20Mintable { "TEST_NAME", "TEST_SYMBOL", 
        // "100",
        // contract_address };
   
    }

    #[test]
    fn call_deploy() {
        // First declare and deploy a contract
        let contract = declare('ERC20Mintable');
        // Alternatively we could use `deploy_syscall` here
        let sender=get_caller_address();
        let name:felt252='TESTOR';
        let symbol:felt252='TESTOR STARK SYMBOL';
        let sender_felt=ContractAddressIntoFelt252::into(sender);
        let mut contract_args= array![name,symbol, sender_felt ];
        let contract_address = contract.deploy(@contract_args);
    }


    #[test]
    fn test_token_mint() {

            // let deploy_memecoin=deploy_standalone_memecoin();
            let token_contract = declare('ERC20Mintable');
            let sender=get_caller_address();
            let name:felt252='TEST_NAME';
            let symbol:felt252='TEST_SYMBOL';
            let sender_felt=ContractAddressIntoFelt252::into(sender);
            let initial_supply:felt252=100;
            let mint:u256=100;
            // let initial_supply:u256=100;

            // let mut calldata = array![name.into(), symbol.into(), initial_supply.into(), sender_felt.into()];
            // let mut calldata = array![name, symbol, initial_supply, sender_felt];
            let mut calldata = array![name, symbol, sender_felt];
 
            let token_addr = token_contract.deploy(@calldata);

            let token=IERC20Dispatcher {contract_address:token_addr.unwrap()};
            // let token=IUnruggableMemecoin {contract_address:token_addr};.
            let balance= token.balance_of(sender);
         

    }

}