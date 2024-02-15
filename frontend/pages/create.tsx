import type { GetServerSideProps, NextPage, NextPageContext } from "next";
import {
  Box,
  Tabs,
  TabPanels,
  TabList,
  Tab,
  TabPanel,
} from "@chakra-ui/react";
import HeaderSEO from "../components/HeaderSEO";
import CreateLaunchForm from "../components/form/launch";

const Create: NextPage = ({}) => {
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
        py={{ base: "2em" }}
      >
        <Tabs>
          <TabList>
            <Tab>Launchpad</Tab>
          </TabList>
          <TabPanels>
            <TabPanel>
              <CreateLaunchForm />
            </TabPanel>
          </TabPanels>
        </Tabs>
      </Box>
    </>
  );
};

export default Create;
