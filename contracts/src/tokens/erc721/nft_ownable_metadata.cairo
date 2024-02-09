#[starknet::contract]
mod NftOwnableMetadata {
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::ERC721Component;
    use openzeppelin::access::ownable::OwnableComponent;
    use starknet::ContractAddress;

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    // Ownable
    
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    #[abi(embed_v0)]
    impl OwnableCamelOnlyImpl =
        OwnableComponent::OwnableCamelOnlyImpl<ContractState>;
    impl InternalImplOwnable = OwnableComponent::InternalImpl<ContractState>;

    // ERC721
    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataImpl = ERC721Component::ERC721MetadataImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721CamelOnly = ERC721Component::ERC721CamelOnlyImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataCamelOnly =
        ERC721Component::ERC721MetadataCamelOnlyImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    // SRC5
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,

        base_uri:felt252
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        symbol:felt252,
        name:felt252,
        base_uri:felt252
    ) {
        let token_id = 1;

        self.erc721.initializer(name, symbol);
        self.ownable.initializer(owner);
        self.base_uri.write(base_uri);

    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {

        fn set_base_uri(
            ref self:ContractState,
            new_base_uri:felt252
        ) {
            // Only owner allowed
            self.ownable.assert_only_owner();
            self.base_uri.write(new_base_uri);
        }

        
        fn set_token_uri(
            ref self:ContractState,
            token_id:u256,
            new_token_uri:felt252
        ) {
            // Only owner allowed
            self.ownable.assert_only_owner();
            self.erc721._set_token_uri(token_id, new_token_uri);
        }

        fn _mint_with_uri(
            ref self: ContractState,
            recipient: ContractAddress,
            token_id: u256,
            token_uri: felt252
        ) {
            // Only owner allowed
            self.ownable.assert_only_owner();

            // Initialize the ERC721 storage
            self.erc721._mint(recipient, token_id);
            // Mint the NFT to recipient and set the token's URI
            self.erc721._set_token_uri(token_id, token_uri);
        }
    }
}