import { ethers, network } from "hardhat";
import { OpWizChainlinkCompatible } from "../typechain";
import { developmentChains } from "../helper-hardhat-config";
import { Address } from "hardhat-deploy/types";

export async function setPriceFeedAddress(optionId: number, priceFeed: Address){

    const { participator }= await ethers.getNamedSigners();
    const WAIT_CONFIRMATION = developmentChains.includes(network.name) ? 1 : 6;
    const opWizChainlink : OpWizChainlinkCompatible = await ethers.getContract("OpWizChainlinkCompatible");
    const listOptionTx = await opWizChainlink.connect(participator).setPriceFeedAddress(optionId, priceFeed);
    const listOptionTxReceipt = await listOptionTx.wait(WAIT_CONFIRMATION);
    console.log(listOptionTxReceipt);
}

//BNB/USD kovan price feed: "0x8993ED705cdf5e84D0a3B754b5Ee0e1783fcdF16";
const address = "0x8993ED705cdf5e84D0a3B754b5Ee0e1783fcdF16";
setPriceFeedAddress(1, address)
.then(() => console.log("Price-feed address setted"))
.catch((error) => {
    console.error(error)
    process.exit(1)
  });

export default setPriceFeedAddress;