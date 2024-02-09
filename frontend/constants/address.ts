import { constants } from "starknet";

export const CHAIN_IDS ={
  GOERLI:"0x534e5f474f45524c49",

}

export const CHAINS_NAMES= {
  GOERLI:"Starknet Goerli Testnet"
}

export const DEFAULT_NETWORK= constants.NetworkName.SN_GOERLI
interface ContractAddressByChain {
  ethAddress?:string;
  erc721Factory?: string;
  erc20Factory?: string;
  lockupLinearFactory?:string;
  launchFactory?:string;
  saleFactory?:string;
  marketplaceNft?:string;
}

interface ChainAddressesName {
  [chainId: string | number]: ContractAddressByChain;
}

export const CONTRACT_DEPLOYED_STARKNET: ChainAddressesName = {
  1: {},
  [constants.NetworkName.SN_GOERLI]: {
    ethAddress:"0x049D36570D4e46f48e99674bd3fcc84644DdD6b96F7C741B1562B82f9e004dC7",
    launchFactory:"0x049D36570D4e46f48e99674bd3fcc84644DdD6b96F7C741B1562B82f9e004dC7",
    saleFactory:"0x049D36570D4e46f48e99674bd3fcc84644DdD6b96F7C741B1562B82f9e004dC7",
    marketplaceNft:"0x049D36570D4e46f48e99674bd3fcc84644DdD6b96F7C741B1562B82f9e004dC7",

  },
  [constants.NetworkName.SN_MAIN]: {


  },

};

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
