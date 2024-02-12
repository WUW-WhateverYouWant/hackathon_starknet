

#[cfg(test)]
mod test_erc20 {
 
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
use starknet::testing;

    use snforge_std::{
        declare, ContractClassTrait, start_prank, stop_prank, RevertedTransaction, CheatTarget,
        TxInfoMock
    };

    use wuw_contracts::tokens::erc20::erc20_mintable:: {
        ERC20Mintable
    };
    use array::ArrayTrait;
    use result::ResultTrait;
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
    #[available_gas(2000000)]
    fn call_utils() {

        let sender=get_caller_address();
        let name:felt252='TESTOR';
        let symbol:felt252='TESTOR STARK SYMBOL';
        let mint:u256=100;
        let initial_supply:felt252=100;

        let address:ContractAddress= deploy_setup_erc20(name, symbol, mint, sender);

        start_prank(CheatTarget::One(address), OWNER());

        // assert!(erc20.balance_of(sender)== 0, "balance not 0");
        // println!("check owner");
        // assert!(erc20.owner()== OWNER(), "no same owner");

       
    }


    #[test]
    fn call_deploy() {
        // First declare and deploy a contract
        let contract = declare('ERC20Mintable');
        // Alternatively we could use `deploy_syscall` here
        let sender=get_caller_address();
        let name:felt252='TESTOR';
        let symbol:felt252='TESTOR STARK SYMBOL';
        let mint:u256=100;
        let initial_supply:felt252=100;

        let sender_felt=ContractAddressIntoFelt252::into(sender);
        let mut contract_args= array![name,symbol, sender_felt , initial_supply];
        Serde::serialize(@initial_supply, ref contract_args);
        // Serde::serialize(@recipient , ref contract_args);

        let contract_address = contract.deploy(@contract_args);
    }

    #[test]
    #[available_gas(2000000)]
    fn call_init_erc20() {

            let token_contract = declare('ERC20Mintable');
            let sender=get_caller_address();
            let name:felt252='TEST_NAME';
            let symbol:felt252='TEST_SYMBOL';
            let sender_felt=ContractAddressIntoFelt252::into(OWNER());
            let initial_supply:felt252=100;

            let mut contract_args = array![name, symbol, sender_felt, initial_supply];
             Serde::serialize(@initial_supply, ref contract_args);
        // Serde::serialize(@recipient , ref contract_args);

            let token_addr = token_contract.deploy(@contract_args).unwrap();
            let erc20=IERC20Dispatcher {contract_address:token_addr};
            assert!(erc20.balance_of(sender)== 0, "balance not 0");
            println!("check owner");
            assert!(erc20.owner()== OWNER(), "no same owner");
            start_prank(CheatTarget::One(token_addr), OWNER());
    }

    fn OWNER() -> ContractAddress {
    contract_address_const::<'OWNER'>()
}

    #[test]
    #[available_gas(2000000)]
    fn test_token_mint() {

            let token_contract = declare('ERC20Mintable');
            let sender=get_caller_address();
            let recipient = snforge_std::test_address();

            let name:felt252='TEST_NAME';
            let symbol:felt252='TEST_SYMBOL';
            let sender_felt=ContractAddressIntoFelt252::into(OWNER());
            let initial_supply:felt252=100;

            let mut calldata = array![name, symbol, sender_felt, initial_supply];
            Serde::serialize(@initial_supply, ref calldata);

            let token_addr = token_contract.deploy(@calldata).unwrap();
            let erc20=IERC20Dispatcher {contract_address:token_addr};
            assert!(erc20.balance_of(sender)== 0, "balance not 0");
            println!("check owner");
            assert!(erc20.owner()== OWNER(), "no same owner");
            // Change the caller address to OWNER when calling the contract at the `contract_address` address
            start_prank(CheatTarget::One(token_addr), OWNER());
            let mint_amount:u256=1000*pow_256(10,18);
            let holder_3:ContractAddress=contract_address_const::<'holder'>();
            println!("Try mint");
            // TODO Fix issue in TEST
            // erc20.mint(OWNER(), mint_amount );
            // assert!(erc20.balance_of(OWNER())== mint, "balance eq 0");

    }

}