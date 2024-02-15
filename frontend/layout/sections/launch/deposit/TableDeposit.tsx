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
import { LaunchCardView, DepositByUser } from "../../../../types";
import { feltToAddress } from "../../../../utils/starknet";
import { useAccount } from "@starknet-react/core";
import { MdCancel } from "react-icons/md";
import { DepositInteractions } from "./DepositInteractions";

interface ITableDepositByUser {
  deposits?: DepositByUser[];
  viewType?: LaunchCardView;
}

/** @TODO get component view ui with call claim reward for recipient visibile */
export const TableDeposit = ({ viewType, deposits }: ITableDepositByUser) => {
  const account = useAccount().account;
  return (
    <Box overflowX={"auto"}>
      <Table overflow={"auto"} overflowX={"auto"}>
        <>
          <Thead>
            <Tr>
              <Th>Token address</Th>
              <Th>To claim</Th>
              <Th>Quote address</Th>
              <Th>Status</Th>
              <Th>Actions</Th>
              <Th>Amount deposit</Th>
              <Th>Datas</Th>
            </Tr>
          </Thead>
          <Tbody>
            {deposits?.length > 0 &&
              deposits.map((deposit, i) => {

                if(!deposit?.asset && Number(deposit?.deposited) > 0 ) {
                  return;
                }
                const asset = deposit?.asset && feltToAddress(BigInt(deposit?.asset));
                const quote_address = deposit?.quote_token_address ? feltToAddress(BigInt(deposit?.quote_token_address)) : "0x";
                let total_amount = deposit?.deposited;
                let remain_token_to_be_claimed = deposit?.remain_token_to_be_claimed;
                let total_token_to_be_claimed = deposit?.total_token_to_be_claimed;
                let total_withdraw = deposit?.withdrawn;
                console.log("deposit", deposit);
                return (
                  <Tr key={i}
                    justifyContent={"end"}
                    alignContent={"end"}
                    alignItems={"end"}
                  >
                    <Td>
                      {asset.length > 0 && <Text>
                        {asset.length > 0 && asset?.slice(0, 10)} ...
                        {asset?.slice(asset?.length - 10, asset?.length)}{" "}
                      </Text>}

                    </Td>
                    <Box
                      gap={{ base: "1em" }}
                    >
                      <Td
                        minW={{ base: "150px", md: "200px" }}
                        w={"100%"}>
                        <DepositInteractions deposit={deposit}></DepositInteractions>
                      </Td>
                    </Box>
                    <Td>{quote_address}</Td>

                    <Td>

                      <Text> Total to be claim: {Number(total_withdraw?.toString()) / 10 ** 18}</Text>
                      <Text>Deposited {Number(total_amount.toString()) / 10 ** 18}</Text>

                      <Text>To claim: {Number(total_token_to_be_claimed?.toString())}</Text>
                    </Td>

                    <Td>{deposit.is_canceled && <Text >Cancel: <MdCancel></MdCancel>
                    </Text>}

                    </Td>
                  </Tr>
                );
              })}
          </Tbody>

        </>

      </Table>
    </Box>
  );
};
