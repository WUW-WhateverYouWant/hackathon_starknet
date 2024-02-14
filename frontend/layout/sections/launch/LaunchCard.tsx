import {  Card, } from "@chakra-ui/react";
import { LaunchInterface, LaunchCardView } from "../../../types";
import { Uint256, cairo, } from "starknet";
import { feltToAddress} from "../../../utils/starknet";
import { useAccount } from "@starknet-react/core";

import { useEffect, useState } from "react";

import { LaunchComponent } from "./LaunchComponent";

interface IStreamCard {
  launch?: LaunchInterface;
  viewType?: LaunchCardView;
}

/** @TODO get component view ui with call claim reward for recipient visibile */
export const LaunchCard = ({ launch, viewType, }: IStreamCard) => {
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
        <LaunchComponent launch={launch} ></LaunchComponent>
      </Card>
    </>
  );
};
