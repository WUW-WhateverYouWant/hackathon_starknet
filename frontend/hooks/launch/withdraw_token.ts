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

export async function withdraw_token(
  account: AccountInterface,
  launch_id: number,
): Promise<TxCallInterface>{
  try {

    console.log("withdraw_token")
    console.log("account", account?.address)
    console.log("launch_id",launch_id)
 
    const provider = new RpcProvider({nodeUrl:constants.NetworkName.SN_GOERLI})
    const launchpadContract = new Contract(
      LaunchpadAbi.abi,
      LAUNCHPAD_TESTNET_ADDRESS,
      provider
    );
    console.log("Calldata compile")

    const calldataCreateWithDuration = CallData.compile({
      launch_id: launch_id,
    });

    console.log("Execute multicall")

    let success = await account.execute([
      {
        contractAddress: launchpadContract.address,
        entrypoint: "withdraw_token",
        calldata: calldataCreateWithDuration,
      },
    ],
    undefined,

    
    );
    console.log(
      "✅ withdraw_token invoked at :",
      success?.transaction_hash
    );


    return {
      // tx: tx,
      hash:success?.transaction_hash,
      isSuccess: true,
      message: "200",
    };
  } catch (e) {
    console.log("Error withdraw_token", e);
    
    return {
      tx: undefined,
      isSuccess: false,
      message: e,
    };
  }
}