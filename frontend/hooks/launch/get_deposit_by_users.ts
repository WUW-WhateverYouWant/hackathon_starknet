import { useToast } from "@chakra-ui/react";
import {
  CONTRACT_DEPLOYED_STARKNET,
  DEFAULT_NETWORK,
} from "../../constants/address";
import { CreateRangeProps, DepositByUser, LaunchInterface, TxCallInterface, } from "../../types";
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

export async function get_deposit_by_users(
  owner:string
): Promise<DepositByUser[]|undefined> {
  try {

    console.log('get_deposit_by_users : ', owner)
    const provider = new RpcProvider({ nodeUrl: constants.NetworkName.SN_GOERLI })
    const launchpadContract = new Contract(
      LaunchpadAbi.abi,
      LAUNCHPAD_TESTNET_ADDRESS,
      provider
    );

    const depositsByUser = await launchpadContract.get_deposit_by_users(owner);
    return depositsByUser

  } catch (e) {
    console.log("Error depositsByUser", e);

    return undefined;
  }
}