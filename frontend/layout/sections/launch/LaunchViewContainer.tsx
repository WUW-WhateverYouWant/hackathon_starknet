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
import { LaunchInterface, StreamCardView } from "../../../types";
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
  const [streamsSend, setStreamsSend] = useState<LaunchInterface[]>([]);

  const [streamsReceived, setStreamsReceived] = useState<LaunchInterface[]>([]);
  const [selectView, setSelectView] = useState<EnumStreamSelector>(
    EnumStreamSelector.SENDER
  );
  const [viewType, setViewType] = useState<ViewType>(ViewType.TABS);
  console.log("streams state Send", streamsSend);

  useEffect(() => {
    const getStreamsBySender = async () => {
      const contractAddress =
        CONTRACT_DEPLOYED_STARKNET[DEFAULT_NETWORK].launchFactory;
    };

    const getStreamsByRecipient = async () => {
      const contractAddress =
        CONTRACT_DEPLOYED_STARKNET[DEFAULT_NETWORK].launchFactory;
    };
    if (
      account?.address
      // &&  selectView == EnumStreamSelector.SENDER
    ) {
      getStreamsBySender();
    }
    if (
      account?.address
      //  && selectView== EnumStreamSelector.RECIPIENT
    ) {
      getStreamsByRecipient();
    }
  }, [account?.address, account]);

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
            As recipient
          </Tab>

          <Tab
            onClick={() => setSelectView(EnumStreamSelector.SENDER)}
            _selected={{ color: "brand.primary" }}
          >
            As sender
          </Tab>
        </TabList>

        <TabPanels>
          <TabPanel>
            <RecipientLaunchComponent
              streamsReceivedProps={streamsReceived}
              setStreamsReceivedProps={setStreamsReceived}
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
  streamsReceivedProps: LaunchInterface[];
  setStreamsReceivedProps: (lockups: LaunchInterface[]) => void;
  viewType?: ViewType;
  setViewType: (viewType: ViewType) => void;
}

const RecipientLaunchComponent = ({
  streamsReceivedProps,
  setStreamsReceivedProps,
  viewType,
  setViewType,
}: IRecipientLaunchComponent) => {
  const account = useAccount();
  console.log("streamsReceivedProps", streamsReceivedProps);
  return (
    <Box>
      <Text>Check the launch you can receive here.</Text>
      <Text>Total: {streamsReceivedProps?.length}</Text>
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
          {streamsReceivedProps?.length > 0 &&
            streamsReceivedProps.map((s, i) => {
              // if (!s?.was_canceled) {
              return (
                <LaunchCard
                  stream={s}
                  key={i}
                  viewType={StreamCardView.RECIPIENT_VIEW}
                />
              );
              // }
            })}
        </Box>
      )}

      {viewType == ViewType.TABS && (
        <TableLaunchpad
          streams={streamsReceivedProps}
          viewType={StreamCardView.RECIPIENT_VIEW}
        ></TableLaunchpad>
      )}
    </Box>
  );
};

interface ISenderLaunchComponent {
  launchSend: LaunchInterface[];
  setStreamsSend: (lockups: LaunchInterface[]) => void;
  viewType?: ViewType;
  setViewType: (viewType: ViewType) => void;
}
const SenderLaunchComponent = ({
  launchSend,
  setStreamsSend,
  viewType,
  setViewType,
}: ISenderLaunchComponent) => {
  const account = useAccount();

  return (
    <Box>
      <Text>Find here your stream</Text>
      <Text>Total: {launchSend?.length}</Text>

      {viewType == ViewType.CARDS && (
        <Box
          display={"grid"}
          gridTemplateColumns={{
            base: "repeat(1,1fr)",
            md: "repeat(2,1fr)",
          }}
          gap={{ base: "0.5em" }}
        >
          {launchSend?.length > 0 &&
            launchSend.map((s, i) => {
              console.log("s", s);

              if (!s?.was_canceled) {
                return (
                  <LaunchCard
                    stream={s}
                    key={i}
                    viewType={StreamCardView.SENDER_VIEW}
                  />
                );
              }
            })}
        </Box>
      )}

      {viewType == ViewType.TABS && (
        <TableLaunchpad
          streams={launchSend}
          viewType={StreamCardView.SENDER_VIEW}
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
