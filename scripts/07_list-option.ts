import { ethers, network } from "hardhat";
import { OpWizChainlinkCompatible } from "../typechain";
import { developmentChains } from "../helper-hardhat-config";
import { Address } from "hardhat-deploy/types";
import { BigNumberish } from "ethers";


export async function listOption(optionId: number, listAsset: Address, listAmount: BigNumberish){

    const { participator }= await ethers.getNamedSigners();
    const WAIT_CONFIRMATION = developmentChains.includes(network.name) ? 1 : 6;
    const opWizChainlink : OpWizChainlinkCompatible = await ethers.getContract("OpWizChainlinkCompatible");
    const listOptionTx = await opWizChainlink.connect(participator).listOption(optionId, listAsset, listAmount);
    const listOptionTxReceipt = await listOptionTx.wait(WAIT_CONFIRMATION);
    console.log(listOptionTxReceipt);
}

export default listOption;