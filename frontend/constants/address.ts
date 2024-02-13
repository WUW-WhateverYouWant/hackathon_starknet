import { constants } from "starknet";

export const CHAIN_IDS = {
  GOERLI: "0x534e5f474f45524c49",
  SEPOLIA: "0x534e5f5345504f4c4941",

}

export const CHAINS_NAMES = {
  GOERLI: "Starknet Goerli Testnet",
  SEPOLIA: "Starknet Sepolia Testnet",
}


// export const DEFAULT_NETWORK = CHAIN_IDS.SEPOLIA
export const DEFAULT_NETWORK="SN_SEPOLIA"
export const CONTRACT_DEPLOYED_STARKNET: ChainAddressesName = {
  [CHAIN_IDS.SEPOLIA]: {
    ethAddress: "0x049D36570D4e46f48e99674bd3fcc84644DdD6b96F7C741B1562B82f9e004dC7",
    // launchFactory: "0x4b02897cc8df737f675517443c42b92f9825ca7f408e8bbb68e0c58271b2e1e",
    launchFactory:"0x349a251297b6e5841250f15bd90227f95afd1bf087fe26e71ad3f64340b84c1",
    saleFactory: "0x049D36570D4e46f48e99674bd3fcc84644DdD6b96F7C741B1562B82f9e004dC7",
    marketplaceNft: "0x049D36570D4e46f48e99674bd3fcc84644DdD6b96F7C741B1562B82f9e004dC7",
    pragmaOracle:"0x36031daa264c24520b11d93af622c848b2499b66b41d611bac95e13cfca131a"
  },
  ["SN_SEPOLIA"]: {
    ethAddress: "0x049D36570D4e46f48e99674bd3fcc84644DdD6b96F7C741B1562B82f9e004dC7",
    // launchFactory: "0x4b02897cc8df737f675517443c42b92f9825ca7f408e8bbb68e0c58271b2e1e",
    launchFactory:"0x349a251297b6e5841250f15bd90227f95afd1bf087fe26e71ad3f64340b84c1",
    saleFactory: "0x049D36570D4e46f48e99674bd3fcc84644DdD6b96F7C741B1562B82f9e004dC7",
    marketplaceNft: "0x049D36570D4e46f48e99674bd3fcc84644DdD6b96F7C741B1562B82f9e004dC7",
    pragmaOracle:"0x36031daa264c24520b11d93af622c848b2499b66b41d611bac95e13cfca131a"
  },
  [constants.NetworkName.SN_GOERLI]: {
    ethAddress: "0x049D36570D4e46f48e99674bd3fcc84644DdD6b96F7C741B1562B82f9e004dC7",
    launchFactory: "0x105a63fe5d258aed090bba92ebbb8d6323eaefde70dd8ad82d50959b1e6a4ea",
    saleFactory: "0x049D36570D4e46f48e99674bd3fcc84644DdD6b96F7C741B1562B82f9e004dC7",
    marketplaceNft: "0x049D36570D4e46f48e99674bd3fcc84644DdD6b96F7C741B1562B82f9e004dC7",

  },
  [constants.NetworkName.SN_MAIN]: {


  },

};
export const LAUNCHPAD_TESTNET_ADDRESS =
  CONTRACT_DEPLOYED_STARKNET[DEFAULT_NETWORK]
    .launchFactory;

interface ContractAddressByChain {
  ethAddress?: string;
  erc721Factory?: string;
  erc20Factory?: string;
  lockupLinearFactory?: string;
  launchFactory?: string;
  saleFactory?: string;
  marketplaceNft?: string;
  pragmaOracle?:string;
}

interface ChainAddressesName {
  [chainId: string | number]: ContractAddressByChain;
}

interface ChainAddressesTips {
  [chainId: string | number]: TokenTips[];
}

interface TokenTips {
  title?: string;
  image?: string;
  address?: string;
  value?: string;
}

export const TOKEN_TIPS: ChainAddressesTips = {

};


export const TOKENS_ADDRESS = {
  ETH:"0x049D36570D4e46f48e99674bd3fcc84644DdD6b96F7C741B1562B82f9e004dC7",
}
