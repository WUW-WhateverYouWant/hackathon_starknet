import {
  Box,
  Button,
  Input,
  useToast,
  Text,
  useColorModeValue,
  FormLabel,
  Checkbox,
} from "@chakra-ui/react";
import { useAccount, useNetwork } from "@starknet-react/core";
import { useEffect, useState } from "react";
import { CreateLaunch, TypeCreationLaunch } from "../../../types";
import e from "cors";

import { ADDRESS_LENGTH, CONFIG_WEBSITE } from "../../../constants";
import {
  DEFAULT_NETWORK,
  CONTRACT_DEPLOYED_STARKNET,
  CHAINS_NAMES,
} from "../../../constants/address";

import ERC20 from "../../../constants/abi/wuw_contracts_ERC20Mintable.contract_class.json";
import {
  Contract,
  Uint,
  Uint256,
  stark,
  uint256,
  BigNumberish,
  cairo,
  TransactionStatus,
} from "starknet";
import { ExternalStylizedButtonLink } from "../../button/NavItem";
import { VoyagerExplorerImage } from "../../view/VoyagerExplorerImage";
import { create_launch } from "../../../hooks/launch/create_launch";

interface ICreateSaleForm { }

const CreateLaunchForm = ({ }: ICreateSaleForm) => {
  const toast = useToast();
  const accountStarknet = useAccount();
  const network = useNetwork();
  const chainId = network.chain.id;
  const networkName = network.chain.name;

  const account = accountStarknet?.account;
  const address = accountStarknet?.account?.address;
  const [txHash, setTxHash] = useState<string | undefined>();
  const [isDisabled, setIsDisabled] = useState<boolean>(true);
  const [typeLaunchCreation, setTypeLaunchCreation] = useState<
    TypeCreationLaunch | undefined
  >(TypeCreationLaunch.CREATE_LAUNCH);
  const [recipient, setRecipient] = useState<boolean>(true);
  const [typeCreation, setTypeCreation] = useState<boolean>(true);
  const [form, setForm] = useState<CreateLaunch | undefined>({
    sender: account?.address,
    total_amount: undefined,
    asset: undefined,
    cancelable: true,
    transferable: true,
    token_received_per_one_base: undefined,
    base_asset_token_address: undefined,
    start_date: undefined,
    end_date: undefined,
    // range: {
    //   start: undefined,
    //   cliff: undefined,
    //   end: undefined,
    // },
    // broker: {
    //   account: undefined,
    //   fee: undefined,
    // },
    duration_cliff: undefined,
    duration_total: undefined,
    broker_account: account?.address,
    broker_fee: undefined,
    broker_fee_nb: undefined,
    max_deposit_by_user: undefined,
    soft_cap: undefined,
  });
  useEffect(() => {
    if (address && account) {
      setIsDisabled(false);
      setForm({ ...form, sender: address });
    }
  }, [accountStarknet, account, address]);

  /** @TODO refacto */
  const prepareHandleCreateLaunch = async (
    typeOfCreation: TypeCreationLaunch
  ) => {
    try {
      const CONTRACT_ADDRESS = CONTRACT_DEPLOYED_STARKNET[DEFAULT_NETWORK];

      if (!CONTRACT_ADDRESS.saleFactory?.toString()) {
        toast({
          title: `Contract for Sale is not deployed in ${DEFAULT_NETWORK}.`,
          isClosable: true,
          duration: 1500,
        });
        return;
      }

      /** Check value before send tx */

      if (!address) {
        toast({
          title: "Connect your account",
          status: "warning",
          isClosable: true,
          duration: 1000,
        });
        return;
      }

      if (!form?.sender) {
        toast({
          status: "warning",
          isClosable: true,
          duration: 1000,
        });
        return {
          isSuccess: false,
          message: "Connect your account",
        };
      }

      if (!form?.total_amount) {
        toast({
          title: "Provide Total amount to lockup",
          status: "warning",
          isClosable: true,
          duration: 1000,
        });
        return;
      }

      /** Address verification */

      if (!form?.asset?.length) {
        toast({
          title: "Asset not provided",
          status: "warning",
          isClosable: true,
        });
        return;
      }

      /***@TODO use starknet check utils isAddress */
      if (form?.asset?.length < ADDRESS_LENGTH) {
        toast({
          title: "Asset is not address size. Please verify your ERC20 address",
          status: "warning",
          isClosable: true,
        });
        return;
      }
      /***@TODO use starknet check utils isAddress */
      console.log(
        "form?.recipient?.length",
        form?.base_asset_token_address?.length
      );
      if (
        form?.base_asset_token_address?.length != ADDRESS_LENGTH &&
        !cairo.isTypeContractAddress(form?.base_asset_token_address)
        // !cairo.isTypeContractAddress(form?.recipient)
      ) {
        toast({
          title:
            "Base asset is not address size. Please verify your base address",
          status: "warning",
          isClosable: true,
        });
        return;
      }

      console.log(
        "form?.recipient?.length",
        form?.base_asset_token_address?.length
      );
      if (
        form?.asset?.length != ADDRESS_LENGTH &&
        !cairo.isTypeContractAddress(form?.asset)
        // !cairo.isTypeContractAddress(form?.recipient)
      ) {
        toast({
          title:
            "Token to launch is not address size. Please verify your launch  address",
          status: "warning",
          isClosable: true,
        });
        return;
      }

      const erc20Contract = new Contract(ERC20.abi, form?.asset, account);

      let decimals = 18;

      try {
        decimals == (await erc20Contract.decimals());
      } catch (e) {
      } finally {
      }
      const total_amount_nb = form?.total_amount * 10 ** Number(decimals);
      let total_amount;

      if (Number.isInteger(total_amount_nb)) {
        total_amount = cairo.uint256(total_amount_nb);
      } else if (!Number.isInteger(total_amount_nb)) {
        // total_amount=total_amount_nb
        total_amount = uint256.bnToUint256(BigInt(total_amount_nb));
      }
      // Call function. Last check input
      if (
        typeOfCreation == TypeCreationLaunch.CREATE_LAUNCH_BASE_TOKEN_ORACLE
      ) {
        if (!form?.start_date) {
          toast({
            title: "Please provide Start date",
            status: "warning",
          });
          return;
        }

        if (form?.start_date < new Date().getTime()) {
          toast({
            title: "Start date is too late. Provide future date",
            status: "warning",
          });
          return;
        }

        if (!form?.end_date) {
          toast({
            title: "Please provide End date",
            status: "warning",
          });
          return;
        }
        if (form?.end_date < new Date().getTime()) {
          toast({
            title: "End date is too late. Provide future date",
            status: "warning",
          });
          return;
        }

        if (!cairo.isTypeContractAddress(form?.base_asset_token_address)) {
          toast({
            title: "Please provide a valid Address for your broker account",
            status: "warning",
          });
          return;
        }

        if (!account?.address) {
          toast({
            title: "Duration total need to be superior too duration_cliff",
            status: "error",
          });
          return;
        }

        const { isSuccess, message, hash } = await create_launch(
          accountStarknet?.account,
          form?.asset, // Asset
          form?.base_asset_token_address, //Base address liquidity
          total_amount, // Total amount
          form?.token_received_per_one_base,
          form?.cancelable, // Asset
          form?.transferable, // Transferable
          parseInt(form?.start_date.toString()),
          parseInt(form?.end_date.toString()),
          form?.soft_cap,
          form?.max_deposit_by_user
          // form?.broker_fee_nb
        );
        if (hash) {
          setTxHash(hash)
          const tx = await account.waitForTransaction(hash);
          toast({
            title: 'Tx send. Please wait for confirmation',
            description: `${CONFIG_WEBSITE.page.goerli_voyager_explorer}/tx/${hash}`,
            status: "info",
            isClosable: true

          })
          if (tx?.status) {
            toast({
              title: 'Tx confirmed',
              description: `${CONFIG_WEBSITE.page.goerli_voyager_explorer}/tx/${hash}`,

              // description: `Hash: ${hash}`
            })
          }
        }
        console.log("message", message);
      } else {
        if (!form?.start_date) {
          toast({
            title: "Provide Start date",
            status: "warning",
          });
          return;
        }
        if (form?.start_date < new Date().getTime()) {
          toast({
            title: "Start date is too late. Provide future date",
            status: "warning",
          });
          return;
        }

        if (!form?.end_date) {
          toast({
            title: "Please provide End date",
            status: "warning",
          });
          return;
        }

        if (form?.end_date < new Date().getTime()) {
          toast({
            title: "Start date is too late. Provide future date",
            status: "warning",
          });
          return;
        }

        if (!form?.base_asset_token_address) {
          toast({
            title: "Base asset token address",
            status: "warning",
          });
          return;
        }

        console.log("form", form)

        const { isSuccess, message, hash } = await create_launch(
          accountStarknet?.account,
          form?.asset, // Asset
          form?.base_asset_token_address, //Base address liquidity
          total_amount, // Total amount
          form?.token_received_per_one_base,
          form?.cancelable, // Asset
          form?.transferable, // Transferable
          parseInt(form?.start_date.toString()),
          parseInt(form?.end_date.toString()),
          form?.soft_cap,
          form?.max_deposit_by_user
        );

        if (hash) {
          setTxHash(hash)
          toast({
            title: 'Tx send. Please wait for confirmation',
            description: `${CONFIG_WEBSITE.page.goerli_voyager_explorer}/tx/${hash}`,
            status: "info",
            isClosable: true

          })
          const tx = await account.waitForTransaction(hash);
          if (tx?.status == TransactionStatus.ACCEPTED_ON_L2) {

            toast({
              title: 'Tx confirmed',
              description: `${CONFIG_WEBSITE.page.goerli_voyager_explorer}/tx/${hash}`,
            })
          }
        }
      }
    } catch (e) {
      console.log("prepareCreateLaunch", e);
    }
  };

  return (
    <Box
      width={{ base: "100%" }}
      py={{ base: "1em", md: "2em" }}
      px={{ base: "1em" }}
    >
      <Text fontFamily={"PressStart2P"} fontSize={{ base: "19px", md: "21px" }}>
        Start creating your Launch
      </Text>

      <Text>Select the type of Launch you want to create</Text>
      <Box
        py={{ base: "0.25em" }}
        justifyContent={"center"}
        display={"flex"}
        gap={{ base: "1em" }}
      >
        <Button
          onClick={() =>
            setTypeLaunchCreation(TypeCreationLaunch.CREATE_LAUNCH)
          }
        >
          Create launch
        </Button>

        <Button
          onClick={() =>
            setTypeLaunchCreation(
              TypeCreationLaunch.CREATE_LAUNCH_BASE_TOKEN_ORACLE
            )
          }
        >
          Launch base token oracle
        </Button>
      </Box>

      {txHash && (
        <Box py={{ base: "1em" }}>
          <ExternalStylizedButtonLink
            href={`${CHAINS_NAMES.GOERLI == networkName.toString()
              ? CONFIG_WEBSITE.page.goerli_voyager_explorer
              : CONFIG_WEBSITE.page.voyager_explorer
              }/tx/${txHash}`}
          >
            <VoyagerExplorerImage></VoyagerExplorerImage>
          </ExternalStylizedButtonLink>
        </Box>
      )}

      <Box
        py={{ base: "0.25em", md: "1em" }}
        display={{ md: "flex" }}
        height={"100%"}
        justifyContent={"space-around"}
        gap={{ base: "0.5em", md: "1em" }}
        alignContent={"baseline"}
        alignSelf={"self-end"}
        alignItems={"baseline"}
      >
        <Box height={"100%"} display={"grid"}>
          <Text textAlign={"left"} fontFamily={"PressStart2P"}>
            Basic details
          </Text>

        


          <Text textAlign={"left"}
          >
            Total amount of token to sell
          </Text>
          <Input
            my={{ base: "0.25em", md: "0.5em" }}
            py={{ base: "0.5em" }}
            type="number"
            placeholder="Total amount"
            onChange={(e) => {
              setForm({ ...form, total_amount: Number(e.target.value) });
            }}
          ></Input>

<Text textAlign={"left"}
          >
            Asset
          </Text>

          {TypeCreationLaunch.CREATE_LAUNCH == typeLaunchCreation && (
            <Input
              // my='1em'
              my={{ base: "0.25em", md: "0.5em" }}
              py={{ base: "0.5em" }}
              onChange={(e) => {
                setForm({ ...form, asset: e.target.value });
              }}
              placeholder="Asset address"
            ></Input>
          )}

          {TypeCreationLaunch.CREATE_LAUNCH_BASE_TOKEN_ORACLE == typeLaunchCreation && (
            <Input
              // my='1em'
              my={{ base: "0.25em", md: "0.5em" }}
              py={{ base: "0.5em" }}
              onChange={(e) => {
                setForm({ ...form, asset: e.target.value });
              }}
              placeholder="Asset address"
            ></Input>
          )}

          <Box height={"100%"}>
            <Box>
              <Text textAlign={"left"}>Base/Quote token asset</Text>
              <Input
                my={{ base: "0.25em", md: "0.5em" }}
                py={{ base: "0.5em" }}
                aria-valuetext={form?.base_asset_token_address}
                onChange={(e) => {
                  setForm({
                    ...form,
                    base_asset_token_address: e.target.value,
                  });
                }}
                placeholder="Base/Quote token address"
              ></Input>
            </Box>
          </Box>
        </Box>
        <Box
          // display={{ md: "flex" }}
          height={"100%"}
          gap={{ base: "0.5em" }}
          w={{ base: "100%", md: "fit-content" }}
        >
          <Text textAlign={"left"} fontFamily={"PressStart2P"}>
          Launchpad Details 
          </Text>
          <Box
            height={"100%"}
            w={{ base: "100%", md: "450px" }}
            bg={useColorModeValue("gray.900", "gray.700")}
            p={{ base: "1em" }}
            borderRadius={{ base: "5px" }}
          >


            <Text textAlign={"left"}
            >
              Soft cap
            </Text>

            <Input
              py={{ base: "0.5em" }}
              type="number"
              my={{ base: "0.25em", md: "0.5em" }}
              aria-valuetext={String(form?.soft_cap)}
              onChange={(e) => {
                let str = String(Number(e?.target?.value) * 10 ** 18);

                setForm({
                  ...form,
                  // soft_cap: cairo.uint256(parseInt(e?.target?.value)),
                  soft_cap: cairo.uint256(parseInt(str)),
                });
              }}
              placeholder="Soft cap"
            ></Input>


            <Text textAlign={"left"}
            >
              Token receive per base token
            </Text>
            <Input
              py={{ base: "0.5em" }}
              type="number"
              my={{ base: "0.25em", md: "0.5em" }}
              onChange={(e) => {
                let str = String(Number(e?.target?.value) * 10 ** 18);

                setForm({
                  ...form,
                  token_received_per_one_base: cairo.uint256(
                    parseInt(str)
                  ),
                  // broker_fee_nb: Number(e?.target?.value),
                  // broker: {
                  //   ...form.broker,
                  //   fee: Number(e.target.value),
                  // },
                });
              }}
              placeholder="Token receive per base token"
            ></Input>

            <Text textAlign={"left"}>

              Max deposit per user
            </Text>
            <Input
              py={{ base: "0.5em" }}
              type="number"
              my={{ base: "0.25em", md: "0.5em" }}
              onChange={(e) => {
                setForm({
                  ...form,
                  max_deposit_by_user: cairo.uint256(
                    parseInt(e?.target?.value)
                  ),
                  // broker_fee_nb: Number(e?.target?.value),
                  // broker: {
                  //   ...form.broker,
                  //   fee: Number(e.target.value),
                  // },
                });
              }}
              placeholder="Max deposit per user"
            ></Input>

            <Text textAlign={"left"} fontFamily={"PressStart2P"}>
              Date ⏳
            </Text>

            <Box>
              <Text
                textAlign={"left"}
                color={useColorModeValue("gray.100", "gray.300")}
              >
                Start date
              </Text>
              <Input
                justifyContent={"start"}
                w={"100%"}
                py={{ base: "0.5em" }}
                my={{ base: "0.25em", md: "0.5em" }}
                type="datetime-local"
                color={useColorModeValue("gray.100", "gray.300")}
                _placeholder={{
                  color: useColorModeValue("gray.100", "gray.300"),
                }}
                onChange={(e) => {
                  setForm({
                    ...form,
                    start_date: new Date(e.target.value).getTime(),
                  });
                }}
                placeholder="Start date"
              ></Input>

              <Text
                textAlign={"left"}
                color={useColorModeValue("gray.100", "gray.300")}
              >
                End date
              </Text>
              <Input
                py={{ base: "0.5em" }}
                type="datetime-local"
                my={{ base: "0.25em", md: "0.5em" }}
                color={useColorModeValue("gray.100", "gray.300")}
                _placeholder={{
                  color: useColorModeValue("gray.100", "gray.300"),
                }}
                onChange={(e) => {
                  setForm({
                    ...form,
                    end_date: new Date(e.target.value).getTime(),
                  });
                }}
                placeholder="End date"
              ></Input>
            </Box>

          </Box>

        </Box>
      </Box>

      <Box>

        <Box
          textAlign={"center"}
          display={{ base: "flex" }}
          gap={{ base: "0.5em" }}
        >
          {typeLaunchCreation ==
            TypeCreationLaunch.CREATE_LAUNCH_BASE_TOKEN_ORACLE ? (
            <Button
              bg={useColorModeValue("brand.primary", "brand.primary")}
              disabled={isDisabled}
              onClick={() => {
                prepareHandleCreateLaunch(
                  TypeCreationLaunch.CREATE_LAUNCH_BASE_TOKEN_ORACLE
                );
              }}
            >
              Create launch with base token
            </Button>
          ) : (
            <Button
              bg={useColorModeValue("brand.primary", "brand.primary")}
              disabled={isDisabled}
              onClick={() => {
                prepareHandleCreateLaunch(TypeCreationLaunch.CREATE_LAUNCH);
              }}
            >
              Create launch
            </Button>
          )}
        </Box>
      </Box>
    </Box>
  );
};

export default CreateLaunchForm;
