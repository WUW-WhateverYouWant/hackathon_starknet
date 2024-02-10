import {
  constants,
  Provider,
  Contract,
  Account,
  json,
  shortString,
  RpcProvider,
  hash,
  cairo,
} from "starknet";
import fs from "fs";
import dotenv from "dotenv";
import path from "path";
import { CLASS_HASH, PINATA_URL } from "../../config";
// const PUBLIC_KEY = process.env.PUBLIC_KEY;
// const PRIVATE_KEY = process.env.PUBLIC_KEY;
dotenv.config();
const PUBLIC_KEY = process.env.PUBLIC_KEY2;
const PRIVATE_KEY = process.env.PK_DEV2;
async function main() {
  if (!PUBLIC_KEY) {
    console.log("Provide public key in env");
    return;
  }

  if (!PRIVATE_KEY) {
    console.log("Provide private key in env");
    return;
  }
  // Initialize RPC provider with a specified node URL (Goerli testnet in this case)
  const provider = new RpcProvider({
    nodeUrl: "SN_GOERLI",
  });

  // Check that communication with provider is OK
  const ci = await provider.getChainId();
  console.log("chain Id =", ci);

  // initialize existing Argent X testnet  account
  const accountAddress = PUBLIC_KEY;
  const privateKey = PRIVATE_KEY;

  const account0 = new Account(provider, accountAddress, privateKey);
  console.log("existing_ACCOUNT_ADDRESS=", accountAddress);
  console.log("existing account connected.\n");

  // Parse the compiled contract files

  let fileStr = path.resolve(
    __dirname,
    "../../constants/nft_ownable_metadata.contract_class.json"
  );

  const compiledSierra = json.parse(
    fs
      .readFileSync(fileStr)
      .toString("ascii")
  );
  let fileCompiled = path.resolve(
    __dirname,
    "../../constants/nft_ownable_metadata.compiled_contract_class.json"
  );

  const compiledCasm = json.parse(
    fs
      .readFileSync(fileCompiled)
      .toString("ascii")
  );

  //**************************************************************************************** */
  // Since we already have the classhash we will be skipping this part
  // Declare the contract

  // const ch = hash.computeSierraContractClassHash(compiledSierra);
  // console.log("Class hash calc =", ch);
  // const compCH = hash.computeCompiledClassHash(compiledCasm);
  // console.log("compiled class hash =", compCH);
  // const declareResponse = await account0.declare({
  //   contract: compiledSierra,
  //   casm: compiledCasm,
  // });
  // const contractClassHash = declareResponse.class_hash;
  // // Wait for the transaction to be confirmed and log the transaction receipt
  //  const txR = await provider.waitForTransaction(
  //   declareResponse.transaction_hash
  // );

  // const contractClassHash = CLASS_HASH.NFT_OWNABLE_METADATA;
  const contractClassHash = CLASS_HASH.NFT_OWNABLE_METADATA;

  console.log("contractClassHash", contractClassHash);

  console.log("✅ Test Contract declared with classHash =", contractClassHash);

  console.log("Deploy of contract in progress...");
  const name = cairo.felt("TESTOR");
  const symbol = cairo.felt("TEST");
  // const name = "TESTOR";
  // const symbol = "TEST";
  console.log("name", name);
  console.log("symbol", symbol);
  const nonce = await account0.getNonce();

  let base_uri = PINATA_URL.contractBaseURI;
  base_uri = PINATA_URL.contractHash;

  //  let base_uri_felt = shortString.splitLongString(base_uri);
  let base_uri_felt = base_uri;


  // const base_uri_felt = cairo.felt(base_uri);

  let token_uri_unreavled = PINATA_URL.tokenBaseURIUnrevelead;

  console.log("accountAddress", accountAddress);
  const { transaction_hash: th2, address } = await account0.deployContract(
    {
      classHash: contractClassHash,
      constructorCalldata: [
        accountAddress.toString(),
        name,
        symbol,
        base_uri_felt,
        // "gang gang"
        // base_uri_felt
      ],
    },
    { nonce: nonce }
  );
  console.log("🚀 contract_address =", address);
  // Wait for the deployment transaction to be confirmed
  await provider.waitForTransaction(th2);

  console.log("✅ Test completed.");
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
