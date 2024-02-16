import { useToast } from "@chakra-ui/react";
import {
  CONTRACT_DEPLOYED_STARKNET,
  DEFAULT_NETWORK,
  LAUNCHPAD_TESTNET_ADDRESS
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
import { feltToAddress } from "../../utils/starknet";


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
  hard_cap: Uint256,
  min_deposit_by_user: Uint256,
  max_deposit_by_user: Uint256,
): Promise<TxCallInterface> {
  try {

    console.log("total_amount", total_amount)
    console.log("asset", asset)
    console.log("cancelable", cancelable)
    console.log("transferable", transferable)

    const provider = new RpcProvider({nodeUrl:DEFAULT_NETWORK})
    // const provider = new RpcProvider()

    const launchpadContract = new Contract(
      LaunchpadAbi.abi,
      LAUNCHPAD_TESTNET_ADDRESS,
      provider
    );
    const erc20Contract = new Contract(ERC20WUW.abi, asset, provider);
    // Calldata for CREATE_LAUNCH_BASE_TOKEN_ORACLE
    console.log("Calldata compile")

    const calldataCreateWithDuration = CallData.compile({
      asset: asset,
      // base_asset_token_address: base_asset_token_address,
      quote_token_address: base_asset_token_address,
      total_amount: total_amount,
      token_received_per_one_base: token_received_per_one_base,
      start_date: start_date,
      end_date: end_date,
      soft_cap: soft_cap,
      hard_cap:hard_cap,
      min_deposit_by_user:min_deposit_by_user,
      max_deposit_by_user: max_deposit_by_user,
    });

    console.log("Execute multicall")

    // const is_oracle = await launchpadContract.get_is_dollar_paid_launch();
    // console.log("is_oracle", is_oracle)
    const is_paid_dollar = await launchpadContract.get_is_dollar_paid_launch();
    console.log("is_paid_dollar", is_paid_dollar)
    if (is_paid_dollar) {

      let asset_paid = await launchpadContract.get_address_token_to_pay_launch();
      asset_paid= feltToAddress(BigInt(asset_paid))
      console.log("asset_paid",asset_paid)
      const erc20PaidContract = new Contract(ERC20WUW.abi, asset_paid, provider);
      let amount_paid_fees = await launchpadContract.get_amount_token_to_pay_launch();
      console.log("amount_paid_fees",amount_paid_fees)

      if(amount_paid_fees>0 ) {
        
      }

      let success = await account.execute([
        {
          contractAddress: erc20PaidContract.address,
          entrypoint: "approve",
          calldata: CallData.compile({
            recipient: launchpadContract.address,
            // amount: cairo.uint256(amount_paid_fees),
            amount:amount_paid_fees
          }),
        },
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
          entrypoint: "create_launch",
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
        hash: success?.transaction_hash,
        isSuccess: true,
        message: "200",
      };


    } else {

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
          entrypoint: "create_launch",
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
        hash: success?.transaction_hash,
        isSuccess: true,
        message: "200",
      };


    }



  } catch (e) {
    console.log("Error create_launch", e);

    return {
      tx: undefined,
      isSuccess: false,
      message: e,
    };
  }
}