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
import { CONFIG_ADDRESS } from "../../config";
import path from "path";
// const PUBLIC_KEY = process.env.PUBLIC_KEY;
// const PRIVATE_KEY = process.env.PUBLIC_KEY;
dotenv.config();
const PUBLIC_KEY = process.env.PUBLIC_KEY2;
const PRIVATE_KEY = process.env.PK_DEV2;
const PUBLIC_KEY_ONE = process.env.PK_ONE;
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

  let fileStr = path.resolve(__dirname, "../../constants/erc721.json")


  // Parse the compiled contract files
  const compiledSierra = json.parse(
    fs
      // .readFileSync("erc721.json")
      .readFileSync(fileStr)
      .toString("ascii")
  );
  let fileCompiled = path.resolve(__dirname, "../../constants/erc721.compiled_contract.json")

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
  // console.log("contractClassHash", contractClassHash)

  // // Wait for the transaction to be confirmed and log the transaction receipt
  // const txR = await provider.waitForTransaction(
  //   declareResponse.transaction_hash
  // );
  // console.log("tx receipt =", txR);
  //**************************************************************************************** */

  const contractClassHash =
    "0x6012b224e2dc901c9461cb30d1c3aca01bbf5602ffc1da071c8aa6fa5e3b027";

  console.log("✅ Test Contract declared with classHash =", contractClassHash);

  const nftContract= new Contract(compiledSierra.abi,  CONFIG_ADDRESS.NFT_MINTOR, account0)

  const nonce = await account0?.getNonce()
  const transfer = await nftContract.transfer_from(account0?.address, PUBLIC_KEY_ONE, "4",{
    nonce:nonce
  })
  console.log("transfer")
 
  console.log("✅ Transfer Test completed.");
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
