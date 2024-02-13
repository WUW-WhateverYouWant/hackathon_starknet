import { useToast } from "@chakra-ui/react";

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

import {
  CONTRACT_DEPLOYED_STARKNET,
  DEFAULT_NETWORK,
  LAUNCHPAD_TESTNET_ADDRESS
} from "../../constants/address";

export async function cancel_launch(
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
        entrypoint: "cancel_launch",
        calldata: calldataCreateWithDuration,
      },
    ],
    undefined,
    
    );
    console.log(
      "✅ cancel_launch invoked at :",
      success?.transaction_hash
    );


    return {
      // tx: tx,
      hash:success?.transaction_hash,
      isSuccess: true,
      message: "200",
    };
  } catch (e) {
    console.log("Error cancel_launch", e);
    
    return {
      tx: undefined,
      isSuccess: false,
      message: e,
    };
  }
}