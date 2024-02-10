import { useToast } from "@chakra-ui/react";
import {
  CONTRACT_DEPLOYED_STARKNET,
  DEFAULT_NETWORK,
} from "../../constants/address";
import { CreateRangeProps, TxCallInterface, } from "../../types";
import { ADDRESS_LENGTH } from "../../constants";
import LaunchpadAbi from "../../constants/abi/launchpad_wuw.contract_class.json";
import ERC20WUW from "../../constants/abi/wuw_contracts_ERC20Mintable.contract_class.json";
import {
  Account,
  AccountInterface,
  BigNumberish,
  CallData,
  Contract,
  GetTransactionReceiptResponse,
  Provider,
  ProviderInterface,
  RpcProvider,
  Uint256,
  cairo,
  constants,
  stark,
} from "starknet";
import { UseAccountResult } from "@starknet-react/core";

const LAUNCHPAD_TESTNET_ADDRESS =
  CONTRACT_DEPLOYED_STARKNET[constants.NetworkName.SN_GOERLI]
    .launchFactory;

export async function create_launch(
  account: AccountInterface,
  asset: string,
  base_asset_token_address: string,
  total_amount: Uint256,
  token_received_per_one_base: Uint256,
  cancelable: boolean,
  transferable: boolean,
  start_date: number,
  end_date: number,
  soft_cap: Uint256,
  max_deposit_by_user: Uint256
): Promise<TxCallInterface>{
  try {

    console.log("total_amount", total_amount)
    console.log("asset", asset)
    console.log("cancelable", cancelable)
    console.log("transferable", transferable)
  
    const provider = new RpcProvider({nodeUrl:constants.NetworkName.SN_GOERLI})
    const launchpadContract = new Contract(
      LaunchpadAbi.abi,
      LAUNCHPAD_TESTNET_ADDRESS,
      provider
    );
    const erc20Contract = new Contract(ERC20WUW.abi, asset, provider);
    // Calldata for Create_with_duration
    console.log("Calldata compile")

    const calldataCreateWithDuration = CallData.compile({
      asset: asset,
      total_amount: total_amount,
      token_received_per_one_base: token_received_per_one_base,
      base_asset_token_address: base_asset_token_address,
      cancelable: cancelable,
      transferable: transferable,
      start_date: start_date,
      end_date: end_date,
      soft_cap:soft_cap,
      max_deposit_by_user: max_deposit_by_user,
    });

    console.log("Execute multicall")

    // const nonce= await account.getNonce()
    // console.log("nonce",nonce)

    let success = await account.execute([
      {
        contractAddress: erc20Contract.address,
        entrypoint: "approve",
        calldata: CallData.compile({
          recipient: launchpadContract.address,
          amount: total_amount,
        }),
      },
      {
        contractAddress: launchpadContract.address,
        entrypoint: "create_with_range",
        calldata: calldataCreateWithDuration,
      },
    ],
    undefined,
    //  [ERC20WUW.abi, LaunchpadAbi],
    //   {
    //   nonce:nonce
    // }
    
    );
    console.log(
      "✅ create_launch invoked at :",
      success?.transaction_hash
    );


    return {
      // tx: tx,
      hash:success?.transaction_hash,
      isSuccess: true,
      message: "200",
    };
  } catch (e) {
    console.log("Error create_launch", e);
    
    return {
      tx: undefined,
      isSuccess: false,
      message: e,
    };
  }
}