
import { TxCallInterface, } from "../../types";
import LaunchpadAbi from "../../constants/abi/launchpad_wuw.contract_class.json";
import {
  Account,
  AccountInterface,
  CallData,
  Contract,
  RpcProvider,

} from "starknet";
import { UseAccountResult } from "@starknet-react/core";

import {
  CONTRACT_DEPLOYED_STARKNET,
  DEFAULT_NETWORK,
  LAUNCHPAD_TESTNET_ADDRESS
} from "../../constants/address";

export async function refund_deposit_amount(
  account: AccountInterface,
  launch_id: number,
): Promise<TxCallInterface>{
  try {
    const provider = new RpcProvider({nodeUrl:DEFAULT_NETWORK})
    const launchpadContract = new Contract(
      LaunchpadAbi.abi,
      LAUNCHPAD_TESTNET_ADDRESS,
      provider
    );

    const calldataCreateWithDuration = CallData.compile({
      launch_id: launch_id,
    });


    let success = await account.execute([
      {
        contractAddress: launchpadContract.address,
        entrypoint: "refund_deposit_amount",
        calldata: calldataCreateWithDuration,
      },
    ],
    undefined,
    
    );
    console.log(
      "✅ refund_deposit_amount invoked at :",
      success?.transaction_hash
    );


    return {
      // tx: tx,
      hash:success?.transaction_hash,
      isSuccess: true,
      message: "200",
    };
  } catch (e) {
    console.log("Error refund_deposit_amount", e);
    
    return {
      tx: undefined,
      isSuccess: false,
      message: e,
    };
  }
}