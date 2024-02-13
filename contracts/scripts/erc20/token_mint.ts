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
import { CLASS_HASH, CONFIG_ADDRESS } from "../../config";
import path from "path";
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
  let fileStr = path.resolve(__dirname, "../../constants/erc20.json")

  const compiledSierra = json.parse(
    fs
      .readFileSync(fileStr)

      .toString("ascii")
  );

  let compileFile = path.resolve(__dirname, "../../constants/erc20.compiled_contract_class.json")

  const compiledCasm = json.parse(
    fs
    
      .readFileSync(compileFile)

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

  const contractClassHash =CLASS_HASH.ERC20_MINTABLE_SEPOLIA;

  console.log("✅ Test Contract declared with classHash =", contractClassHash);

  const tokenContract= new Contract(compiledSierra.abi,  CONFIG_ADDRESS.ERC20_MINTABLE_SEPOLIA, account0)
  const mint = await tokenContract.mint(account0?.address, "10")
  console.log("mint")
  // await provider.waitForTransaction(mint);
  // console.log("symbol", symbol)
 
  console.log("✅ Test completed.");
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

//Deployed Address
// 0x0661bd47eb4c872cd316a305dc673221a8f8a27379e6aa3a97a21a542efbb76f on goerli
