import { Box, Card, Text, Button, CardFooter, Input } from "@chakra-ui/react";
import { LaunchInterface, LaunchCardView } from "../../../types";
import {
  Uint256,
  cairo,
  shortString,
  stark,
  validateAndParseAddress,
} from "starknet";
import { feltToAddress, feltToString } from "../../../utils/starknet";
import { useAccount } from "@starknet-react/core";
import { useEffect, useState } from "react";
import { formatDateTime, formatRelativeTime } from "../../../utils/format";
import { BiCheck, BiCheckShield } from "react-icons/bi";
import {
  ExternalStylizedButtonLink,
  ExternalTransparentButtonLink,
} from "../../../components/button/NavItem";
import { CONFIG_WEBSITE } from "../../../constants";
import { buy_token } from "../../../hooks/launch/buy_token";
import { cancel_launch } from "../../../hooks/launch/cancel_launch";
import { withdraw_token } from "../../../hooks/launch/withdraw_token";

interface ILaunchPageView {
  launch?: LaunchInterface;
  viewType?: LaunchCardView;
  id?: number;
}

/** @TODO get component view ui with call claim reward for recipient visibile */
export const LaunchInteractions = ({ launch, viewType, id }: ILaunchPageView) => {
  const startDateBn = Number(launch.start_date.toString());
  const startDate = new Date(startDateBn);

  const endDateBn = Number(launch.end_date.toString());
  const endDate = new Date(endDateBn);
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

  const owner = feltToAddress(BigInt(launch?.owner?.toString()));

  let total_amount = launch?.amounts?.deposited;
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
            onClick={() =>
              buy_token(
                account,
                launch?.launch_id ?? id,
                // cairo.uint256(BigInt(amountToBuy.toString())),
                amountToBuy,
                feltToAddress(BigInt(launch?.asset))
              )
            }
          >
            Buy token
          </Button>

          <Button
            width={"100%"}
            // bg="transparent"
            // my={{ base: "0.15em" }}
            onClick={() => withdraw_token(account, launch?.launch_id ?? id)}
          >Withdraw</Button>
        </Box>

        <Box display={"grid"} justifyContent={"start"}>
          {owner == address && (

            <Button
              bg="transparent"
              onClick={() => cancel_launch(account, launch?.launch_id ?? id)}
            >
              Cancel
            </Button>

          )}
        </Box>
      </Box>
    </>
  );
};