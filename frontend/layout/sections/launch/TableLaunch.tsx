import {
  Box,
  Text,
  Table,
  Thead,
  Tr,
  Th,
  Td,
  Tbody,
  Button,
} from "@chakra-ui/react";
import { LaunchInterface, LaunchCardView } from "../../../types";
import { feltToAddress } from "../../../utils/starknet";
import { useAccount } from "@starknet-react/core";

import { formatDateTime, timeAgo } from "../../../utils/format";
import { MdCancel } from "react-icons/md";
import { LaunchInteractions } from "./LaunchInteractions";
import { IFilterLaunch } from "./LaunchViewContainer";

interface IStreamCard {
  launchs?: LaunchInterface[];
  viewType?: LaunchCardView;
  filterLaunch?:IFilterLaunch
}

/** @TODO get component view ui with call claim reward for recipient visibile */
export const TableLaunchpad = ({ viewType, launchs, filterLaunch}: IStreamCard) => {
  const account = useAccount().account;
  return (
    <Box overflowX={"auto"}>
      
      <Table overflow={"auto"} overflowX={"auto"}>
        <>
          <Thead>
            <Tr>
              <Th>Token address</Th>
              <Th>Actions</Th>
              <Th>Quote address</Th>
              <Th>Amount deposit</Th>

              <Th>Date</Th>
              <Th>Status</Th>
              <Th>Withdraw</Th>
              <Th>Owner</Th>

            </Tr>
          </Thead>
          <Tbody>
            {launchs?.length > 0 &&
              launchs.map((l, i) => {

                const sender = feltToAddress(BigInt(l?.owner));
                const asset = feltToAddress(BigInt(l?.asset));
                const quote_address = l?.quote_token_address ? feltToAddress(BigInt(l?.quote_token_address)) : "0x";
                let total_amount = l?.amounts?.deposited;
                let total_withdraw = l?.amounts?.withdrawn;
                // console.log("l", l);
                const startDateBn = Number(l.start_date.toString());
                const startDate = new Date(startDateBn);
                const endDateBn = Number(l.end_date.toString());
                const endDate = new Date(endDateBn);

                return (
                  <Tr key={i}
                    // height={{ base: "100%" }}
                    justifyContent={"end"}
                    alignContent={"end"}
                    alignItems={"end"}

                  >
                    <Td>
                      {asset?.slice(0, 10)} ...
                      {asset?.slice(asset?.length - 10, asset?.length)}{" "}
                    </Td>
                    <Box
                      gap={{ base: "1em" }}
                    >
                      <Td
                        minW={{ base: "150px", md: "200px" }}
                        w={"100%"}>
                        <LaunchInteractions launch={l}></LaunchInteractions>
                      </Td>
                    </Box>
                    <Td>
                    {quote_address?.slice(0, 10)} ...
                      {quote_address?.slice(quote_address?.length - 10, quote_address?.length)}{" "}</Td>
                    <Td>{Number(total_amount?.toString()) / 10 ** 18}</Td>

                    <Td
                      // minW={{ base: "175px" }}
                      display={"grid"}
                      gap={{ base: "0.5em" }}
                    >
                      <Text>
                        Start: {formatDateTime(startDate)}
                      </Text>
                      <Text>
                        End: {formatDateTime(endDate)}
                      </Text>
                    </Td>
                    <Td>{l.is_canceled && <Text >Cancel: <MdCancel></MdCancel>
                    </Text>}

                      {!l.is_canceled &&

                        <Text> {endDate.getTime() > new Date().getTime() ?
                          `Claimable in : ${timeAgo(endDate)}`
                          :
                          `Can be claim in : ${timeAgo(endDate)}`
                        }
                        </Text>}
                    </Td>
                    <Td><Text> Withdraw: {Number(total_withdraw?.toString()) / 10 ** 18}</Text>
                    <Text>Remain: {Number(l.remain_balance)/ 10**18}</Text>
                    </Td>

                    <Td>
                      {sender?.slice(0, 10)} ...
                      {sender?.slice(sender?.length - 10, sender?.length)}{" "}
                    </Td>
                  </Tr>
                );
                // }
              })}
          </Tbody>

        </>

      </Table>
    </Box>
  );
};
