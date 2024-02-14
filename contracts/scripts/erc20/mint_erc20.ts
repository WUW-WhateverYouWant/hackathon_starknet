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
    nodeUrl: "SN_SEPOLIA",
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

  let fileStr = path.resolve(__dirname, "../../constants/erc20_mintable.contract_class.json")

  // Parse the compiled contract files
  const compiledSierra = json.parse(
    fs
      .readFileSync(fileStr)
      .toString("ascii")
  );

  let compileFile = path.resolve(__dirname, "../../constants/erc20_mintable.compiled_contract_class.json")

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

  const contractClassHash = CLASS_HASH.ERC20_MINTABLE_SEPOLIA
  console.log("✅ Test Contract declared with classHash =", contractClassHash);

  const tokenContract= new Contract(compiledSierra.abi,  CONFIG_ADDRESS.ERC20_MINTABLE_SEPOLIA, account0)


  console.log(" CONFIG_ADDRESS.ERC20_MINTABLE",  CONFIG_ADDRESS.ERC20_MINTABLE_SEPOLIA)
  console.log("account0?.address", account0?.address)
  // const init_supply= cairo.uint256(1000)
  // const mint_supply= cairo.uint256(100*10**18)
  const mint_supply= cairo.uint256(100)

  console.log("mint_supply", mint_supply)

  const mint = await tokenContract.mint(account0?.address,mint_supply)
  console.log("mint", mint)

 
  console.log("✅ Test completed.");
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
