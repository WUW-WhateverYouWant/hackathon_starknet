import { useToast } from "@chakra-ui/react";
import {
  CONTRACT_DEPLOYED_STARKNET,
  DEFAULT_NETWORK,
  LAUNCHPAD_TESTNET_ADDRESS
} from "../../constants/address";
import { CreateRangeProps, LaunchInterface, TxCallInterface, } from "../../types";
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



export async function get_launch_by_id(
  id: number,
): Promise<LaunchInterface | undefined> {
  try {

    console.log('id', id)
    const provider = new RpcProvider({ nodeUrl: DEFAULT_NETWORK })
    // const provider = new RpcProvider();
    const launchpadContract = new Contract(
      LaunchpadAbi.abi,
      LAUNCHPAD_TESTNET_ADDRESS,
      provider
    );

    const launch = await launchpadContract.get_launch_by_id(id);
    // console.log("launch", launch)
    return launch

  } catch (e) {
    console.log("Error get_launch_by_id", e);

    return undefined;
  }
}