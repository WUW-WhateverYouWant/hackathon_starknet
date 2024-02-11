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

export async function buy_token(
  account: AccountInterface,
  launch_id: number,
  token_amount_base: Uint256,
  asset:string
): Promise<TxCallInterface>{
  try {

    console.log("buy_token")
    console.log("account", account?.address)
    console.log("launch_id",launch_id)
    console.log("token_amount_base",token_amount_base)
    console.log("asset",asset)
    const provider = new RpcProvider({nodeUrl:constants.NetworkName.SN_GOERLI})
    const launchpadContract = new Contract(
      LaunchpadAbi.abi,
      LAUNCHPAD_TESTNET_ADDRESS,
      provider
    );
    const erc20Contract = new Contract(ERC20WUW.abi, asset, provider);
    // Calldata for CREATE_LAUNCH_BASE_TOKEN_ORACLE
    console.log("Calldata compile")

    const calldataCreateWithDuration = CallData.compile({
      launch_id: launch_id,
      token_amount_base: token_amount_base,
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
          amount: token_amount_base,
        }),
      },
      {
        contractAddress: launchpadContract.address,
        entrypoint: "buy_token",
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
      "✅ buy_token invoked at :",
      success?.transaction_hash
    );


    return {
      // tx: tx,
      hash:success?.transaction_hash,
      isSuccess: true,
      message: "200",
    };
  } catch (e) {
    console.log("Error buy_token", e);
    
    return {
      tx: undefined,
      isSuccess: false,
      message: e,
    };
  }
}