import {
  Box,
  Text,
  Table,
  Thead,
  Tr,
  Th,
  Td,
  Tbody,
} from "@chakra-ui/react";
import { LaunchInterface, LaunchCardView } from "../../../types";
import { feltToAddress } from "../../../utils/starknet";
import { useAccount } from "@starknet-react/core";

import { formatDateTime, timeAgo } from "../../../utils/format";
import { MdCancel } from "react-icons/md";
import { LaunchInteractions } from "./LaunchInteractions";

interface IStreamCard {
  launchs?: LaunchInterface[];
  viewType?: LaunchCardView;
}

/** @TODO get component view ui with call claim reward for recipient visibile */
export const TableLaunchpad = ({ viewType, launchs }: IStreamCard) => {
  const account = useAccount().account;
  return (
    <Box overflowX={"auto"}>
      <Table overflow={"auto"} overflowX={"auto"}>
        <>
          <Thead>
            <Tr>
              <Th>Token address</Th>

              <Th>Owner</Th>
              <Th>Actions</Th>

              <Th>Amount deposit</Th>
              <Th>Date</Th>
              <Th>Status</Th>
              <Th>Withdraw</Th>
              <Th>Quote address</Th>
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
                console.log("l", l);
                const startDateBn = Number(l.start_date.toString());
                const startDate = new Date(startDateBn);
                const endDateBn = Number(l.end_date.toString());
                const endDate = new Date(endDateBn);

                return (
                  <Tr key={i}
                    height={{ base: "100%" }}

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
                      {sender?.slice(0, 10)} ...
                      {sender?.slice(sender?.length - 10, sender?.length)}{" "}
                    </Td>
                    <Td>{Number(total_amount?.toString()) / 10 ** 18}</Td>
                    <Td
                      display={"flex"}
                    >
                      <Text>
                        Date: {formatDateTime(startDate)}
                      </Text>
                      <Text>
                        End  Date: {formatDateTime(endDate)}
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
                    <Td>{Number(total_withdraw?.toString()) / 10 ** 18}</Td>
                    <Td>{quote_address}</Td>
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
