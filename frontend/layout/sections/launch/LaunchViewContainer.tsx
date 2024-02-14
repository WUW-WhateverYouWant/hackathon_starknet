import {
  Tabs,
  TabList,
  TabPanels,
  Tab,
  TabPanel,
  Text,
  Card,
  Box,
  Button,
} from "@chakra-ui/react";
import { useAccount } from "@starknet-react/core";
import { useEffect, useState } from "react";
import { LaunchInterface, LaunchCardView, DepositByUser } from "../../../types";
// import { get_streams_by_sender } from "../../hooks/lockup/get_streams_by_sender";
import {
  CONTRACT_DEPLOYED_STARKNET,
  DEFAULT_NETWORK,
} from "../../../constants/address";
// import { get_streams_by_recipient } from "../../hooks/lockup/get_streams_by_recipient";
import { LaunchCard } from "./LaunchCard";
import { BiCard, BiTable } from "react-icons/bi";
import { BsCardChecklist, BsCardList } from "react-icons/bs";
import { TableLaunchpad } from "./TableLaunch";
import { get_launchs_by_owner } from "../../../hooks/launch/get_launchs_by_owner";
import { get_all_launchs } from "../../../hooks/launch/get_all_launchs";
import { get_deposit_by_users } from "../../../hooks/launch/get_deposit_by_users";

enum EnumStreamSelector {
  SENDER = "SENDER",
  RECIPIENT = "RECIPIENT",
}

enum ViewType {
  TABS = "TABS",
  CARDS = "CARDS",
}
/** @TODO getters Cairo contracts, Indexer */
export const LaunchViewContainer = () => {
  const account = useAccount().account;
  const [launchs, setLaunchs] = useState<LaunchInterface[]>([]);
  const [isLoadOneTime, setIsLoadOneTime] = useState<boolean>(false);
  const [depositsByUser, setDepositsUser] = useState<DepositByUser[]>([]);

  const [launchsCreated, setLaunchCreated] = useState<LaunchInterface[]>([]);
  const [selectView, setSelectView] = useState<EnumStreamSelector>(
    EnumStreamSelector.SENDER
  );
  const [viewType, setViewType] = useState<ViewType>(ViewType.TABS);
  // console.log("launchs state Send", launchs);

  useEffect(() => {
    const getAllLaunchs = async () => {


      const launchs = await get_all_launchs();
      console.log("all_launchs",launchs)
      setLaunchs(launchs)
    };

    const getLaunchsByOwner = async () => {
  

      const launchsByOwner = await get_launchs_by_owner(account?.address);

      setLaunchCreated(launchsByOwner)
      setIsLoadOneTime(true)
    };

    const getDepositByOwner = async () => {

      const deposits = await get_deposit_by_users(account?.address);

      setDepositsUser(deposits)
    };

    if(
      true
      // launchs && 
      // launchs?.length == 0 
      // && !isLoadOneTime
      // && 
      // account?.address
      )  {
      getAllLaunchs();

    }
    if (
      account?.address
      // &&  selectView == EnumStreamSelector.SENDER
    ) {
      getLaunchsByOwner();
      getDepositByOwner();
    }
   
  }, [account?.address, account, isLoadOneTime]);

  return (
    <>
      <Box
        display={"flex"}
        gap="1em"
        py={{ base: "1em" }}
        textAlign={"right"}
        justifyContent={"right"}
      >
        <Button onClick={() => setViewType(ViewType.TABS)}>
          Tabs <BiTable></BiTable>
        </Button>
        <Button onClick={() => setViewType(ViewType.CARDS)}>
          Card <BsCardChecklist></BsCardChecklist>
        </Button>
      </Box>

      <Tabs
        minH={{ base: "250px", md: "350px" }}
        variant="enclosed"
        // variant={""}
        alignItems={"center"}
        gap={{ sm: "1em" }}
      >
        <TabList>
          <Tab
            onClick={() => setSelectView(EnumStreamSelector.RECIPIENT)}
            _selected={{ color: "brand.primary" }}
          >
            All launchs
          </Tab>

          <Tab
            onClick={() => setSelectView(EnumStreamSelector.SENDER)}
            _selected={{ color: "brand.primary" }}
          >
            Launch created
          </Tab>
        </TabList>

        <TabPanels>
          <TabPanel>
            <RecipientLaunchComponent
              launchsReceivedProps={launchs}
              setLaunchReceivedProps={setLaunchs}
              setViewType={setViewType}
              viewType={viewType}
            ></RecipientLaunchComponent>
          </TabPanel>

          <TabPanel>
            <RecipientLaunchComponent
              launchsReceivedProps={launchsCreated}
              setLaunchReceivedProps={setLaunchCreated}
              setViewType={setViewType}
              viewType={viewType}
            ></RecipientLaunchComponent>
          </TabPanel>
          {/* <TabPanel>
            <SenderLaunchComponent
              launchSend={streamsSend}
              setStreamsSend={setStreamsSend}
              setViewType={setViewType}
              viewType={viewType}
            />
          </TabPanel> */}
        </TabPanels>
      </Tabs>
    </>
  );
};

interface IRecipientLaunchComponent {
  launchsReceivedProps: LaunchInterface[];
  setLaunchReceivedProps: (lockups: LaunchInterface[]) => void;
  viewType?: ViewType;
  setViewType: (viewType: ViewType) => void;
}

const RecipientLaunchComponent = ({
  launchsReceivedProps,
  setLaunchReceivedProps,
  viewType,
  setViewType,
}: IRecipientLaunchComponent) => {
  const account = useAccount();
  console.log("launchsReceivedProps", launchsReceivedProps);
  return (
    <Box>
      <Text>Check the launch you can receive here.</Text>
      <Text>Total: {launchsReceivedProps?.length}</Text>
      {viewType == ViewType.CARDS && (
        <Box
          // display={"grid"}
          // gap={{ base: "0.5em" }}

          display={"grid"}
          gridTemplateColumns={{
            base: "repeat(1,1fr)",
            md: "repeat(2,1fr)",
          }}
          gap={{ base: "0.5em" }}
        >
          {launchsReceivedProps?.length > 0 &&
            launchsReceivedProps.map((l, i) => {
              // if (!s?.was_canceled) {
              return (
                <LaunchCard
                  launch={l}
                  key={i}
                  viewType={LaunchCardView.RECIPIENT_VIEW}
                />
              );
              // }
            })}
        </Box>
      )}

      {viewType == ViewType.TABS && (
        <TableLaunchpad
          launchs={launchsReceivedProps}
          viewType={LaunchCardView.RECIPIENT_VIEW}
        ></TableLaunchpad>
      )}
    </Box>
  );
};

interface ISenderLaunchComponent {
  launchsCreated: LaunchInterface[];
  setLaunchCreated: (lockups: LaunchInterface[]) => void;
  viewType?: ViewType;
  setViewType: (viewType: ViewType) => void;
}
const SenderLaunchComponent = ({
  launchsCreated,
  setLaunchCreated,
  viewType,
  setViewType,
}: ISenderLaunchComponent) => {
  const account = useAccount();

  return (
    <Box>
      <Text>Find here your stream</Text>
      <Text>Total: {launchsCreated?.length}</Text>

      {viewType == ViewType.CARDS && (
        <Box
          display={"grid"}
          gridTemplateColumns={{
            base: "repeat(1,1fr)",
            md: "repeat(2,1fr)",
          }}
          gap={{ base: "0.5em" }}
        >
          {launchsCreated?.length > 0 &&
            launchsCreated.map((s, i) => {
              console.log("s", s);

              if (!s?.is_canceled) {
                return (
                  <LaunchCard
                    launch={s}
                    key={i}
                    viewType={LaunchCardView.SENDER_VIEW}
                  />
                );
              }
            })}
        </Box>
      )}

      {viewType == ViewType.TABS && (
        <TableLaunchpad
          launchs={launchsCreated}
          viewType={LaunchCardView.SENDER_VIEW}
        ></TableLaunchpad>
      )}
    </Box>
  );
};

/** @TODO add search stream components. Spec to be defined. */
const SearchStreamComponent = () => {
  return (
    <Box>
      <Text>Coming soon</Text>
    </Box>
  );
};
