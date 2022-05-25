import { ethers, network } from "hardhat";
import { OpWizChainlinkCompatible } from "../typechain";
import { developmentChains } from "../helper-hardhat-config";

export async function exerciseOption(optionId: number){

    const { participator }= await ethers.getNamedSigners();
    const WAIT_CONFIRMATION = developmentChains.includes(network.name) ? 1 : 6;
    const opWizChainlink : OpWizChainlinkCompatible = await ethers.getContract("OpWizChainlinkCompatible");
    const exerciseOptionTx = await opWizChainlink.connect(participator).exerciseOption(optionId);
    const exerciseOptionTxReceipt = await exerciseOptionTx.wait(WAIT_CONFIRMATION);
    console.log(exerciseOptionTxReceipt);

}

exerciseOption(1)
.then(() => console.log("Option Exercised"))
.catch((error) => {
    console.error(error)
    process.exit(1)
  });

export default exerciseOption;