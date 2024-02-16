import {  Card, } from "@chakra-ui/react";
import { LaunchInterface, LaunchCardView, DepositByUser } from "../../../../types";
import { Uint256, cairo, } from "starknet";
import { feltToAddress} from "../../../../utils/starknet";
import { useAccount } from "@starknet-react/core";

import { useEffect, useState } from "react";

import { LaunchComponent } from "../LaunchComponent";
import { DepositComponent } from "./DepositComponent";

interface IDepositCard {
  deposit?: DepositByUser;
  viewType?: LaunchCardView;
}

/** @TODO get component view ui with call claim reward for recipient visibile */
export const DepositCard = ({ deposit, viewType, }: IDepositCard) => {

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
        <DepositComponent deposit={deposit} ></DepositComponent>
      </Card>
    </>
  );
};
