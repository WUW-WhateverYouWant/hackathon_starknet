import { Box, Card, Text, Button, CardFooter, Input } from "@chakra-ui/react";
import { LaunchInterface, LaunchCardView } from "../../../types";
import {
  Uint256,
  cairo,
  shortString,
  stark,
  uint256,
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
  const [amount, setAmount] = useState<number|undefined>(0)
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
            let str_pow = String(Number(e?.target?.value) * 10 ** 18);
            // let str = String(Number(e?.target?.value));
            let str = String(Number(e?.target?.value) * 10 ** 18);


            let total_amount: Uint256 = amountToBuy;
            // let total_amount_nb=str;
            let total_amount_nb = Number(e.target.value);
            if (Number.isInteger(total_amount_nb)) {
              // total_amount = cairo.uint256(BigInt(str));
              total_amount = cairo.uint256(parseInt(str));

            } else if (!Number.isInteger(total_amount_nb)) {
              // total_amount=total_amount_nb
              total_amount = uint256.bnToUint256(parseInt(str));
            }
            setAmountToBuy(total_amount)
            setAmount(total_amount_nb)


            // // let str = String(Number(e?.target?.value));
            // let total_amount:Uint256=cairo.uint256(0);
            // let total_amount_nb=str;
            // if (Number.isInteger(total_amount_nb)) {
            //   total_amount = cairo.uint256(total_amount_nb);
            // } else if (!Number.isInteger(total_amount_nb)) {
            //   // total_amount=total_amount_nb
            //   total_amount = uint256.bnToUint256(BigInt(total_amount_nb));
            // }

            // // setAmountToBuy(cairo.uint256(str));
            // setAmountToBuy(total_amount);

            // setAmountToBuy(cairo.uint256(BigInt(str)));
            // setAmountToBuy(Number(e.target.value));
          }}
          placeholder="Amount to buy"
        ></Input>
        <Box
          gap="1em"
          justifyContent={"start"}
          // justifyContent={"space-around"}
          justifyItems={"left"}
          justifySelf={"self-start"}
          // display={{ md: "grid" }}
          display={"flex"}
          gridTemplateColumns={{ md: "repeat(3,1fr)" }}
        >


          <Button
            // bg="transparent"
            width={"100%"}
            my={{ base: "0.25em" }}

            onClick={() => {

              let decimals = 18;

              // try {
              //   decimals == (await erc20Contract.decimals());
              // } catch (e) {
              // } finally {
              // }
              const total_amount_nb = amount * 10 ** Number(decimals);
              // const total_amount_nb = amount;

              // const total_amount_nb = amount;

              let total_amount;

              if (Number.isInteger(total_amount_nb)) {
                total_amount = cairo.uint256(total_amount_nb);
              } else if (!Number.isInteger(total_amount_nb)) {
                // total_amount=total_amount_nb
                total_amount = uint256.bnToUint256(parseInt(total_amount_nb.toString()));
              }

              buy_token(
                account,
                launch?.launch_id ?? id,
                // cairo.uint256(BigInt(amountToBuy.toString())),
                total_amount,
                // amountToBuy,
                feltToAddress(BigInt(launch?.quote_token_address ?? launch?.base_asset_token_address))
              )
            }


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

        {owner == address && (
          <Box display={"grid"}
            // justifyContent={"start"}
            my={{ base: "0.25em" }}
          >
            <Button
              // bg="transparent"
              width={'100%'}
              onClick={() => cancel_launch(account, launch?.launch_id ?? id)}
            >
              Cancel
            </Button>
          </Box>
        )}

      </Box>
    </>
  );
};
