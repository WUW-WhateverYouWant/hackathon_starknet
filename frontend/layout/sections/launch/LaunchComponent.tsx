import { Box, Card, Text, Button, CardFooter, Input, Progress } from "@chakra-ui/react";
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
import { LaunchInteractions } from "./LaunchInteractions";

interface ILaunchPageView {
  launch?: LaunchInterface;
  viewType?: LaunchCardView;
  id?: number;
}

/** @TODO get component view ui with call claim reward for recipient visibile */
export const LaunchComponent = ({ launch, viewType, id }: ILaunchPageView) => {
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
  const asset = feltToAddress(BigInt(launch?.asset?.toString()));
  const quote_token_address = feltToAddress(BigInt(launch?.quote_token_address?.toString()));
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
  let total_amount = launch?.amounts?.deposited;
  const progress = (Number(launch?.amounts?.deposited) / Number(launch?.hard_cap)) * 100;
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
        <Box>
          <Box>
            <Progress colorScheme={progress >= 100 ? 'green' : 'orange'} size="sm" value={progress} />
            <Text>
              Progress: {progress} %
            </Text>
            <Box

              display={{ base: "flex" }}
              justifyItems={"start"}
              alignContent={"start"}
              justifyContent={"space-around"}
            >
              <Text>Soft cap: {Number(launch.soft_cap) / 10 ** 18}</Text>
              <Text>Hardcap: {Number(launch.hard_cap) / 10 ** 18}</Text>

            </Box>

          </Box>
        </Box>


        <Box>
          {/* <Text wordBreak={"break-all"}>Asset: {feltToAddress(BigInt(launch.asset.toString()))}</Text> */}
          <Text wordBreak={"break-all"}>Asset address:</Text>

          <ExternalStylizedButtonLink
            // pb={{ base: "0.5em" }}
            textOverflow={"no"}
            // maxW={{ md: "170px" }}
            href={`${CONFIG_WEBSITE.page.sepolia_voyager_explorer}/contract/${asset}`}
          >
            {/* <Text>{senderAddress}</Text> */}
            <Text wordBreak={"break-all"}>  {asset?.slice(0, 10)} ...
              {asset?.slice(asset?.length - 10, asset?.length)}{" "}</Text>

          </ExternalStylizedButtonLink>
        </Box>




        <Box
          display={{ md: "flex" }}
        >
          <Box>
            <Text>Start Date: {formatDateTime(startDate)}</Text>
            <Text>End Date: {timeAgo(endDate)}</Text>
            <Text>End Date: {formatDateTime(endDate)}</Text>
          </Box>

          <Box>
            {launch?.is_canceled && (
              <Box display={"flex"} gap="1em" alignItems={"baseline"}>
                Cancel <BiCheck color="red"></BiCheck>
              </Box>
            )}

            {launch?.is_depleted && (
              <Box display={"flex"} gap="1em" alignItems={"baseline"}>
                Depleted <BiCheckShield></BiCheckShield>
              </Box>
            )}

            {launch?.amounts?.withdrawn && (
              <Box display={"flex"} gap="1em" alignItems={"baseline"}>
                Withdraw <BiCheck></BiCheck>
                <Box>{launch?.amounts?.withdrawn.toString()}</Box>
              </Box>
            )}
          </Box>
        </Box>

        {/* {launch?.id && (
          <Box>
            launch id:{" "}
            {shortString.decodeShortString(launch?.launch_id.toString())}
          </Box>
        )} */}

        <Box>
          <ExternalStylizedButtonLink
            // pb={{ base: "0.5em" }}
            textOverflow={"no"}
            maxW={{ md: "170px" }}
            href={`${CONFIG_WEBSITE.page.sepolia_voyager_explorer}/contract/${owner}`}
          >
            {/* <Text>{senderAddress}</Text> */}
            <Text>Owner explorer</Text>
          </ExternalStylizedButtonLink>
        </Box>

        <Text>Amount to sell: {Number(total_amount) / 10 ** 18}</Text>


        <Box>
          {/* <Text>Quote: {quote_token_address}</Text> */}
          <Text>Quote token: </Text>

          <ExternalStylizedButtonLink
            textOverflow={"no"}
            href={`${CONFIG_WEBSITE.page.sepolia_voyager_explorer}/contract/${quote_token_address}`}
          >
            {/* <Text>{senderAddress}</Text> */}
            <Text>{quote_token_address?.slice(0, 10)} ...
              {quote_token_address?.slice(quote_token_address?.length - 10, quote_token_address?.length)}{" "}</Text>
          </ExternalStylizedButtonLink>
        </Box>


        {launch?.amounts?.deposited && (
          <Text>
            Deposited: {Number(launch.amounts?.deposited) / 10 ** 18}
          </Text>
        )}

        <Box>

          <Box display={{ base: "flex" }} gap={{ base: "0.5em" }}>

            {launch?.amounts?.refunded && (
              <Text>
                Refunded {Number(launch.amounts?.refunded) / 10 ** 18}
              </Text>
            )}
            {launch?.amounts?.withdrawn && (
              <Text>
                Withdraw {Number(launch.amounts?.withdrawn) / 10 ** 18}
              </Text>
            )}
          </Box>
        </Box>

        <LaunchInteractions launch={launch} id={id}></LaunchInteractions>


      </Box>
    </>
  );
};
