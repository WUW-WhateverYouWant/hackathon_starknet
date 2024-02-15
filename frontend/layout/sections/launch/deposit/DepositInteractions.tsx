import { Box, Text, Button, CardFooter, Input } from "@chakra-ui/react";
import { LaunchCardView, DepositByUser } from "../../../../types";
import {
  Uint256,
  cairo,
} from "starknet";
import { feltToAddress, feltToString } from "../../../../utils/starknet";
import { useAccount } from "@starknet-react/core";
import { useEffect, useState } from "react";

import { buy_token } from "../../../../hooks/launch/buy_token";
import { cancel_launch } from "../../../../hooks/launch/cancel_launch";
import { withdraw_token } from "../../../../hooks/launch/withdraw_token";
import { refund_deposit_amount } from "../../../../hooks/launch/refund_deposit_amount";

interface ILaunchPageView {
  deposit?: DepositByUser;
  viewType?: LaunchCardView;
  id?: number;
}

/** @TODO get component view ui with call claim reward for recipient visibile */
export const DepositInteractions = ({ deposit, viewType, id }: ILaunchPageView) => {
  const account = useAccount().account;
  const address = account?.address;

  const [withdrawTo, setWithdrawTo] = useState<string | undefined>(address);
  const [amountToBuy, setAmountToBuy] = useState<Uint256 | undefined>(
    cairo.uint256(0)
    // 0
  );
  useEffect(() => {
    const updateWithdrawTo = () => {
      if (!withdrawTo && address) {
        setWithdrawTo(address);
      }
    };
    updateWithdrawTo();
  }, [address]);

  const owner = feltToAddress(BigInt(deposit?.owner?.toString()));
  return (
    <>
      <Box
        textAlign={"left"}
        maxW={{ base: "100%" }}
        p={{ base: "1.5em", md: "1.5em" }}
        rounded={"1em"}
        overflow={"hidden"}
        // justifyContent={"space-between"}
        height={"100%"}
      >

        <Box
          gap="1em"
          justifyContent={"start"}
          // justifyContent={"space-around"}
          justifyItems={"left"}
          justifySelf={"self-start"}
          display={{ md: "grid" }}
        >
          {amountToBuy && Number(amountToBuy) > 0 && (
            <Text>Amount to buy: {Number(amountToBuy)}</Text>
          )}
          <Input
            py={{ base: "0.5em" }}
            type="number"
            my={{ base: "0.25em", md: "0.5em" }}
            maxW={"fit-content"}
            minW={{ base: "100px", md: "150px" }}
            onChange={(e) => {
              let str = String(Number(e?.target?.value) * 10 ** 18);
              setAmountToBuy(cairo.uint256(parseInt(str)));
              // setAmountToBuy(Number(e.target.value));
            }}
            placeholder="Amount to buy"
          ></Input>

          <Button
            // bg="transparent"
            width={"100%"}
            my={{ base: "0.25em" }}
            onClick={() =>
              buy_token(
                account,
                deposit?.launch_id ?? id,
                // cairo.uint256(BigInt(amountToBuy.toString())),
                amountToBuy,
                feltToAddress(BigInt(deposit?.asset))
              )
            }
          >
            Buy token
          </Button>

          <Button
            width={"100%"}
            // bg="transparent"
            // my={{ base: "0.15em" }}
            onClick={() => withdraw_token(account, deposit?.launch_id ?? id)}
          >Withdraw</Button>
          <Button
            // bg="transparent"
            onClick={() => refund_deposit_amount(account, deposit?.launch_id ?? id)}
          >
            Refund
          </Button>
        </Box>

        <Box display={"grid"} justifyContent={"start"}>
      
        </Box>
      </Box>
    </>
  );
};
