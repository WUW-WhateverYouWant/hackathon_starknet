import { Box, Text, Button, CardFooter, Input } from "@chakra-ui/react";
import { LaunchCardView, DepositByUser } from "../../../../types";
import {
  Uint256,
  cairo,

} from "starknet";
import { feltToAddress, feltToString } from "../../../../utils/starknet";
import { useAccount } from "@starknet-react/core";
import { useEffect, useState } from "react";
import { formatDateTime, formatRelativeTime } from "../../../../utils/format";
import { BiCheck, BiCheckShield } from "react-icons/bi";
import {
  ExternalStylizedButtonLink,
} from "../../../../components/button/NavItem";
import { CONFIG_WEBSITE } from "../../../../constants";
import { LaunchInteractions } from "../LaunchInteractions";

interface IDepositComponentPageView {
  deposit?: DepositByUser;
  viewType?: LaunchCardView;
  id?: number;
}

/** @TODO get component view ui with call claim reward for recipient visibile */
export const LaunchComponent = ({ deposit, viewType, id }: IDepositComponentPageView) => {
  const startDateBn = Number(deposit.start_date.toString());
  const startDate = new Date(startDateBn);

  const endDateBn = Number(deposit.end_date.toString());
  const endDate = new Date(endDateBn);
  const account = useAccount().account;
  const address = account?.address;

  const [withdrawTo, setWithdrawTo] = useState<string | undefined>(address);
  const [amountToBuy, setAmountToBuy] = useState<Uint256  | undefined>(
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
  function timeAgo(date: Date): string {
    const now = new Date();
    const diffInSeconds = Math.floor((now.getTime() - date.getTime()) / 1000);

    if (diffInSeconds < 60) {
      return `${diffInSeconds} seconds ago`;
    } else if (diffInSeconds < 3600) {
      const minutes = Math.floor(diffInSeconds / 60);
      return `${minutes} minute${minutes > 1 ? "s" : ""} ago`;
    } else if (diffInSeconds < 86400) {
      const hours = Math.floor(diffInSeconds / 3600);
      return `${hours} hour${hours > 1 ? "s" : ""} ago`;
    } else {
      const days = Math.floor(diffInSeconds / 86400);
      return `${days} day${days > 1 ? "s" : ""} ago`;
    }
  }
  let total_amount = deposit?.amounts?.deposited;
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
        <Text>Asset: {feltToAddress(BigInt(deposit.asset.toString()))}</Text>
        <Box 
        display={{ md: "flex" }}
        >
          <Box>
            <Text>Start Date: {formatDateTime(startDate)}</Text>
            <Text>End Date: {timeAgo(endDate)}</Text>
            <Text>End Date: {formatDateTime(endDate)}</Text>
          </Box>

          <Box>
            {deposit?.is_canceled && (
              <Box display={"flex"} gap="1em" alignItems={"baseline"}>
                Cancel <BiCheck color="red"></BiCheck>
              </Box>
            )}

            {deposit?.is_depleted && (
              <Box display={"flex"} gap="1em" alignItems={"baseline"}>
                Depleted <BiCheckShield></BiCheckShield>
              </Box>
            )}

            {deposit?.amounts?.withdrawn && (
              <Box display={"flex"} gap="1em" alignItems={"baseline"}>
                Withdraw <BiCheck></BiCheck>
                <Box>{deposit?.amounts?.withdrawn.toString()}</Box>
              </Box>
            )}
          </Box>
        </Box>

        {/* {deposit?.id && (
          <Box>
            deposit id:{" "}
            {shortString.decodeShortString(deposit?.deposit_id.toString())}
          </Box>
        )} */}

        <Box>
          <ExternalStylizedButtonLink
            // pb={{ base: "0.5em" }}
            textOverflow={"no"}
            maxW={{ md: "170px" }}
            href={`${CONFIG_WEBSITE.page.goerli_voyager_explorer}/contract/${owner}`}
          >
            {/* <Text>{senderAddress}</Text> */}
            <Text>Owner explorer</Text>
          </ExternalStylizedButtonLink>
        </Box>

        <Box>
          <Text>Amount: {Number(total_amount) / 10 ** 18}</Text>

          <Box display={{ base: "flex" }} gap={{ base: "0.5em" }}>
            {deposit?.amounts?.refunded && (
              <Text>
                Refunded {Number(deposit.amounts?.refunded) / 10 ** 18}
              </Text>
            )}
            {deposit?.amounts?.withdrawn && (
              <Text>
                Withdraw {Number(deposit.amounts?.withdrawn) / 10 ** 18}
              </Text>
            )}
          </Box>
        </Box>

        <LaunchInteractions deposit={deposit} id={id}></LaunchInteractions>

   
      </Box>
    </>
  );
};
