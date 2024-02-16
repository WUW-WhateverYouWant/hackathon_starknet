import { constants } from "starknet";

export const CHAIN_IDS = {
  GOERLI: "0x534e5f474f45524c49",
  SEPOLIA: "0x534e5f5345504f4c4941",

}

export const CHAINS_NAMES = {
  GOERLI: "Starknet Goerli Testnet",
  SEPOLIA: "Starknet Goerli Testnet",
}


// export const DEFAULT_NETWORK = CHAIN_IDS.SEPOLIA
export const DEFAULT_NETWORK="SN_SEPOLIA"
export const CONTRACT_DEPLOYED_STARKNET: ChainAddressesName = {

  ["SN_SEPOLIA"]: {
    ethAddress: "0x049D36570D4e46f48e99674bd3fcc84644DdD6b96F7C741B1562B82f9e004dC7",
    // launchFactory:"0x26b39d7ad15064aeae5bb934932915bc222dfe12826b540014a4bc7b7c6badb",
    // launchFactory:"0x22454d38f6b207e639a4f55fbd1c289ba173208e847dd8e76a9713882b4a439",
    launchFactory:"0x2fcb38df0913bec4ff66d3b71d709a288e349ec05a581dcdcb6382469e0a40c",
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
