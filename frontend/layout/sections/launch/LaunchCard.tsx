import { Box, Card, Text, Button, CardFooter, Input } from "@chakra-ui/react";
import { LaunchInterface, LaunchCardView } from "../../../types";
import { Uint256, cairo, shortString, stark, validateAndParseAddress } from "starknet";
import { feltToAddress, feltToString } from "../../../utils/starknet";
import { useAccount } from "@starknet-react/core";
import {
  CONTRACT_DEPLOYED_STARKNET,
  DEFAULT_NETWORK,
} from "../../../constants/address";
import { useEffect, useState } from "react";
import { formatDateTime, formatRelativeTime } from "../../../utils/format";
import { BiCheck, BiCheckShield } from "react-icons/bi";
import {
  ExternalStylizedButtonLink,
  ExternalTransparentButtonLink,
} from "../../../components/button/NavItem";
import { CONFIG_WEBSITE } from "../../../constants";
import { buy_token } from "../../../hooks/launch/buy_token";

interface IStreamCard {
  launch?: LaunchInterface;
  viewType?: LaunchCardView;
}

/** @TODO get component view ui with call claim reward for recipient visibile */
export const LaunchCard = ({ launch, viewType }: IStreamCard) => {
  const startDateBn = Number(launch.start_date.toString());
  const startDate = new Date(startDateBn);

  const endDateBn = Number(launch.end_date.toString());
  const endDate = new Date(endDateBn);
  const account = useAccount().account;
  const address = account?.address;

  const [withdrawTo, setWithdrawTo] = useState<string | undefined>(address);
  const [amountToBuy, setAmountToBuy] = useState<Uint256 | undefined>(cairo.uint256(0));
  useEffect(() => {
    const updateWithdrawTo = () => {
      if (!withdrawTo && address) {
        setWithdrawTo(address);
      }
    };
    updateWithdrawTo();
  }, [address]);

  const owner = feltToAddress(BigInt(launch?.owner?.toString()));
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
  return (
    <>
      <Card
        textAlign={"left"}
        // borderRadius={{ base: "1em" }}
        // borderRadius={"5em"}
        maxW={{ base: "100%" }}
        minH={{ base: "150px" }}
        py={{ base: "0.5em" }}
        p={{ base: "1.5em", md: "1.5em" }}
        w={{ base: "100%", md: "330px", lg: "450px" }}
        maxWidth={{ lg: "750px" }}
        rounded={"1em"}
        // mx={[5, 5]}
        overflow={"hidden"}
        justifyContent={"space-between"}
        border={"1px"}
        height={"100%"}
      >
        {/* <Text>Start Date: {startDate?.toString()}</Text> */}
        <Text>Start Date: {formatDateTime(startDate)}</Text>
        <Text>End Date: {timeAgo(endDate)}</Text>
        <Text>End Date: {formatDateTime(endDate)}</Text>

        {launch?.was_canceled && (
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

        {/* {launch?.id && (
          <Box>
            launch id:{" "}
            {shortString.decodeShortString(launch?.launch_id.toString())}
          </Box>
        )} */}

        <Text>Asset: {feltToAddress(BigInt(launch.asset.toString()))}</Text>

        <ExternalStylizedButtonLink
          pb={{ base: "0.5em" }}
          textOverflow={"no"}
          href={`${CONFIG_WEBSITE.page.goerli_voyager_explorer}/contract/${owner}`}
        >
          {/* <Text>{senderAddress}</Text> */}
          <Text>Owner explorer</Text>
        </ExternalStylizedButtonLink>

        <Box>
          <Text>Amount: {Number(total_amount) / 10 ** 18}</Text>

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

        <CardFooter textAlign={"left"}>
          <Box>
            {owner != address && withdrawTo && !launch.was_canceled && (
              <Box>

               
              <Input
                py={{ base: "0.5em" }}
                type="number"
                my={{ base: "0.25em", md: "0.5em" }}
                onChange={(e) => {
                  setAmountToBuy( cairo.uint256(parseInt(e?.target?.value)))
                  // setAmountToBuy( parseInt(e?.target?.value))
                    // broker_fee_nb: Number(e?.target?.value),
                    // broker: {
                    //   ...form.broker,
                    //   fee: Number(e.target.value),
                    // },
                  
                }}
                placeholder="Max deposit per user"
              ></Input>


                <Button
                onClick={() =>
                  buy_token(
                    account,
                    launch?.launch_id,
                    amountToBuy,
                    launch?.asset
                  )
                }
                >
                  Buy token 
                  
                  
                </Button>
              </Box>
            )}
          </Box>
          {owner == address && (
            <Box>
              <Button
              // onClick={() =>
              //   cancellaunch(
              //     account,
              //     CONTRACT_DEPLOYED_STARKNET[DEFAULT_NETWORK]
              //       .lockupLinearFactory,
              //     launch?.launch_id
              //   )
              // }
              >
                Cancel
              </Button>
            </Box>
          )}

          {owner != address && withdrawTo && !launch.was_canceled && (
            <Box>
              <Button
              // onClick={() =>
              //   withdraw_max(
              //     account,
              //     CONTRACT_DEPLOYED_STARKNET[DEFAULT_NETWORK]
              //       .lockupLinearFactory,
              //     launch?.launch_id,
              //     withdrawTo
              //   )
              // }
              >
                Withdraw max
              </Button>
            </Box>
          )}
        </CardFooter>
      </Card>
    </>
  );
};
