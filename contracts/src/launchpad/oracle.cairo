#[starknet::contract]
mod HelloStarknet {
    #[storage]
    struct Storage {
        balance: felt252,
    }

    #[external(v0)]
    impl HelloStarknetImpl of super::IHelloStarknet<ContractState> {
        // Increases the balance by the specified amount.
        fn increase_balance(ref self: ContractState, amount: felt252) {
            self.balance.write(self.balance.read() + amount);
        }

        // Returns the balance.

        fn get_balance(self: @ContractState) -> felt252 {
            self.balance.read()
        }
    }
}
