import React from "react";
import { IconType } from "react-icons";
import { GetTransactionReceiptResponse, Uint256 } from "starknet";

/** UI interface */

export enum TypeCreationLaunch {
  CREATE_LAUNCH="CREATE_LAUNCH",
  CREATE_LAUNCH_BASE_TOKEN_ORACLE="CREATE_LAUNCH_BASE_TOKEN_ORACLE",
}
export enum LaunchCardView  {
  SENDER_VIEW="SENDER_VIEW",
  RECIPIENT_VIEW="RECIPIENT_VIEW"
  }

export interface TxCallInterface {
  tx?: GetTransactionReceiptResponse;
  isSuccess?: boolean;
  message?: string;
  hash?: string
}
export interface LinkItemProps {
  name: string;
  title?: string;
  icon: IconType;
  href: string;
  target?: string;
  isExternal?: boolean;
  isSubmenu?: boolean;
  linksSubmenu?: LinkItemProps[];
}

export interface CreateLaunch extends LaunchDurationProps {
  sender: string;
  total_amount: number;
  // total_amount: Uint256,
  asset: string;

  quote_token_address?: string,
  base_asset_token_address: string,
  token_received_per_one_base: Uint256,
  cancelable: boolean,
  transferable: boolean,
  start_date: number,
  end_date: number,
  soft_cap: Uint256,
  hard_cap: Uint256,
  min_deposit_by_user:Uint256,
  max_deposit_by_user:Uint256

  // range: Range;
  // broker: Broker;


}


export interface LaunchDurationProps {
  total_amount: number;
  asset: string;
  cancelable: boolean;
  transferable: boolean;
  duration_cliff: number;
  duration_total: number;
  broker_account: string;
  broker_fee: Uint256;
  broker_fee_nb: number;
}


export interface CreateRangeProps {
  sender: string;
  recipient: string;
  total_amount: number;
  asset: string;
  cancelable: boolean;
  range: Range;
  broker: Broker;

}

/** Contract interface */
export interface LaunchInterface {
  launch_id?: number;
  quote_token_address?:string;
  base_asset_token_address?:string;
  owner: string;
  recipient: string;
  total_amount: number;
  asset: string;
  cancelable: boolean;
  is_depleted: boolean;
  is_canceled: boolean;
  transferable: boolean;
  duration_cliff: number;
  duration_total;
  start_date?: number;
  end_date?: number;
  soft_cap?:number;
  hard_cap?:Uint256,

  token_per_dollar?:number;
  token_received_per_one_base?:number;
  remain_balance?:number;
  max_deposit_by_user?:number;
  min_deposit_by_user?:number,

  // start_time?: number;
  // end_time?: number;
  range: Range;
  broker: Broker;
  amounts?: LockupAmounts
  amountsBySender?: Map<string,LockupAmounts>
}


/** Contract interface */
export interface DepositByUser {
  launch_id?: number;
  asset?:string;
  owner: string;
  quote_token_address?: string;
  deposited?: number;
  redeemable: string;
  withdrawn:Uint256;
  withdraw_amount: Uint256;
  refunded: Uint256;
  is_canceled?: boolean;
  remain_token_to_be_claimed: Uint256;
  total_token_to_be_claimed: Uint256;
}

export interface LockupAmounts {
  deposited: number;
  withdrawn: number;
  refunded: number;
}

export interface Range {
  start: number; //u64
  cliff: number; //u64
  end: number; //u64
}

export interface Broker {
  account: string;
  fee: number; // u128

}

