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
import fs, { read, readFileSync } from "fs";
import dotenv from "dotenv";
import path from "path"
import { CLASS_HASH, CONFIG_ADDRESS, TOKENS_ADDRESS } from "../../config";
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

  // Parse the compiled contract files


  let fileStr = path.resolve(__dirname, "../../constants/launchpad.contract_class.json")
  const compiledSierra = json.parse(
    fs
      .readFileSync(fileStr)
      .toString("ascii")
  );
  let compileFile = path.resolve(__dirname, "../../constants/launchpad.compiled_contract_class.json")

  const compiledCasm = json.parse(
    fs
      .readFileSync(compileFile.toString())
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


  const contractClassHash = CLASS_HASH.LAUNCHPAD
  let nonce = await account0.getNonce();
  console.log("nonce", nonce)
  const launchpadContract = new Contract(compiledSierra.abi, CONFIG_ADDRESS.LAUNCHPAD, account0)

  // External setup addresss
  // // Set oracle pragma address 
  // let pragma_address = CONFIG_ADDRESS.PRAGMA_ORACLE_SEPOLIA
  // console.log("set_pragma_address")

  // const set_pragma_address = await launchpadContract.set_pragma_address(pragma_address)
  // // set jediwap factory
  // let factory_jediswap_v2 = CONFIG_ADDRESS.JEDIWAP_FACTORY_V2_SEPOLIA
  // console.log("set_jediswap_v2")

  // const set_jediswap_v2 = await launchpadContract.set_address_jediswap_factory_v2(factory_jediswap_v2)


  // let nft_jediswap_v2 = CONFIG_ADDRESS.JEDISWAP_NFT_ROUTER_V2_SEPOLIA
  // console.log("set_jediswap_nft_router_v2")

  // const set_jediswap_nft_router_v2 = await launchpadContract.set_address_jediswap_nft_router_v2(nft_jediswap_v2)

  // Set fees
  let is_paid_dollar = true;
  let address_token_to_pay = TOKENS_ADDRESS.ETH;
  let amount_to_paid_dollar_launch = cairo.uint256(10);
  let selector = shortString.encodeShortString("ETH/USD");
  // let selector = cairo.felt("ETH/USD");

  // const set_fees = await launchpadContract.set_params_fees(true,
  //   address_token_to_pay,
  //   amount_to_paid_dollar_launch,
  //   selector,
  //   // { nonce: nonce }
  // )
  console.log("set oracle")

  // const set_oracle_base_asset = await launchpadContract.set_oracle_base_asset(
  //   address_token_to_pay,
  //   true,
  //   // { nonce: nonce }
  // )
  // console.log("set_is_paid_dollar_launch")

  // const set_is_paid_dollar_launch = await launchpadContract.set_is_paid_dollar_launch(true,);
  const set_is_paid_dollar_launch = await launchpadContract.set_is_paid_dollar_launch(false,);

  nonce = await account0.getNonce();
  console.log("nonce", nonce)
  console.log("set token selector")

  const set_token_selector = await launchpadContract.set_token_selector(
    address_token_to_pay,
    selector,
    // { nonce: nonce }

  )
  // console.log("Admin process setup.", set_fees);

  // await provider.waitForTransaction(set_fees);
  console.log("✅ Admin process setup fees.");



  // Wait for the deployment transaction to be confirmed

}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
