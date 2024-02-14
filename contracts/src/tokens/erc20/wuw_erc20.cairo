use starknet::ContractAddress;


#[starknet::contract]
mod WUWToken {
    use openzeppelin::token::erc20::ERC20Component;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::access::accesscontrol::interface::IAccessControl;
    use openzeppelin::access::accesscontrol::AccessControlComponent;

    const MINTER_ROLE: felt252 = selector!("MINTER_ROLE");
    const ADMIN_ROLE: felt252 = selector!("ADMIN_ROLE");
    const MAKER_ROLE: felt252 = selector!("MAKER_ROLE");
    use starknet::ContractAddress;

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    // Access control 
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    #[abi(embed_v0)]
    impl AccessControlImpl =
        AccessControlComponent::AccessControlImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;


    // Ownable
    
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    #[abi(embed_v0)]
    impl OwnableCamelOnlyImpl =
        OwnableComponent::OwnableCamelOnlyImpl<ContractState>;
    impl InternalImplOwnable = OwnableComponent::InternalImpl<ContractState>;

    // ERC20
    #[abi(embed_v0)]
    impl ERC20Impl = ERC20Component::ERC20Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC20MetadataImpl = ERC20Component::ERC20MetadataImpl<ContractState>;

    #[abi(embed_v0)]
    impl ERC20CamelOnlyImpl = ERC20Component::ERC20CamelOnlyImpl<ContractState>;

    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;


    // #[abi(embed_v0)]
    // impl SafeAllowanceCamelImpl =
    //     ERC20Component::SafeAllowanceCamelImpl<ContractState>;
    // impl InternalImpl = ERC20Component::InternalImpl<ContractState>;
    // #[abi(embed_v0)]
    // impl SafeAllowanceImpl = ERC20Component::SafeAllowanceImpl<ContractState>;


    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,

        #[substorage(v0)]
        ownable: OwnableComponent::Storage,

        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
      
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,

        #[flat]
        OwnableEvent: OwnableComponent::Event,

        #[flat]
        AccessControlEvent: AccessControlComponent::Event,

    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: felt252,
        symbol: felt252,
        owner: ContractAddress,
        initial_supply:u256
    ) {
        self.ownable.initializer(owner);
        self.erc20.initializer(name, symbol);
        self.erc20._mint(owner, initial_supply);


        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(ADMIN_ROLE, owner);
        self.accesscontrol._grant_role(MINTER_ROLE, owner);
        self.accesscontrol._grant_role(OWNER_ROLE, owner);


    }

    // TODO check owner 
    #[external(v0)]
    fn mint(
        ref self: ContractState,
        recipient: ContractAddress,
        amount: u256
    ) {
        self.accesscontrol.assert_only_role(MINTER_ROLE);

        self.erc20._mint(recipient, amount);
    }

}