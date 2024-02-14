import type { NextPage } from "next";
import {
  Box,
  Image,
  Tab,
  TabList,
  TabPanel,
  TabPanels,
  Tabs,
  Text,
  useColorModeValue,
  useDisclosure,
} from "@chakra-ui/react";
import HeaderSEO from "../components/HeaderSEO";
import { CONFIG_WEBSITE } from "../constants";
import ConnectModal from "../components/modal/login";
import { ButtonLink } from "../components/button";
import AccountView from "../components/starknet/AccountView";
import { LaunchViewContainer } from "../layout/sections/launch/LaunchViewContainer";

const Home: NextPage = ({}) => {
  const color = useColorModeValue("gray.900", "gray.300");
  const bg = useColorModeValue("gray.700", "gray.500");
  const {
    isOpen,
    onOpen: onOpenConnectModal,
    onClose: onCloseConnectModal,
  } = useDisclosure();
  return (
    <>
      <HeaderSEO></HeaderSEO>

      <Box
        height={"100%"}
        width={"100%"}
        minH={{ sm: "70vh" }}
        overflow={"hidden"}
        alignContent={"center"}
        justifyItems={"center"}
        justifyContent={"center"}
        alignItems={"center"}
        textAlign={"center"}
      >
        <Box display={{ lg: "flex" }} justifyContent={"space-between"}>
          <Box
            textAlign={{ base: "left", md: "center" }}
            p={{ base: "1em" }}
            minH={{ sm: "70vh" }}
            minW={{ lg: "950px" }}
            px={{ base: "1em" }}
            color={color}
          >
            <Box textAlign={"left"} py={{ base: "0.5em" }}>
              <Image src="/assets/starknet_logo.svg"></Image>
              <Text
                fontFamily={"PressStart2P"}
                fontSize={{ base: "19px", md: "23px", lg: "27px" }}
              >
                {CONFIG_WEBSITE.title}✨
              </Text>

              <Text
                fontFamily={"PressStart2P"}
                fontSize={{ base: "17px", md: "19px", lg: "23px" }}
              >
                Build whatever
              </Text>

              <Box
                // display={{ md: "flex" }}
                gap="1em"
              >
                <AccountView></AccountView>
                <Box width={{ base: "100%" }} py={{ base: "0.5em" }}>
                  {/* <ConnectModal
                    modalOpen={isOpen}
                    onClose={onCloseConnectModal}
                    onOpen={onOpenConnectModal}
                    restButton={{
                      // width: { base: "150%" },
                      width: { base: "150px", md: "220px" },

                      // width: { base: "150px" },
                    }}
                  /> */}
                  <ButtonLink
                    restButton={{
                      width: { base: "150px", md: "220px" },
                    }}
                    href="/create"
                    title="Create whatever"
                  ></ButtonLink>
                </Box>
              </Box>
            </Box>

            <Tabs>
              <TabList>
                <Tab>Launchpad</Tab>
                <Tab>Whatever</Tab>
              </TabList>
              <TabPanels>
                <TabPanel>
                  <LaunchViewContainer></LaunchViewContainer>
                </TabPanel>
                <TabPanel>
                  <LaunchViewContainer></LaunchViewContainer>
                </TabPanel>
              </TabPanels>
            </Tabs>
          </Box>
        </Box>
      </Box>
    </>
  );
};
export default Home;
