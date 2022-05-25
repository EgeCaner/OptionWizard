import { ethers, network } from "hardhat";
import { OpWizChainlinkCompatible } from "../typechain";
import { developmentChains } from "../helper-hardhat-config";
import { ERC20__factory } from "../typechain/factories/ERC20__factory";
import { ERC20 } from "../typechain/ERC20";

export async function buyOption(optionId: number){

    const { buyer }= await ethers.getNamedSigners();
    const WAIT_CONFIRMATION = developmentChains.includes(network.name) ? 1 : 6;
    const opWizChainlink : OpWizChainlinkCompatible = await ethers.getContract("OpWizChainlinkCompatible");
    const listAsset = (await opWizChainlink.optionDetails(optionId)).listAsset;
    const listAmount = (await opWizChainlink.optionDetails(optionId)).listAmount;
    const listToken = new ethers.Contract(listAsset, ERC20__factory.abi, buyer) as ERC20; 
    const approveTx = await listToken.approve(opWizChainlink.address, listAmount);
    await approveTx.wait(WAIT_CONFIRMATION);
    const buyOptionTx = await opWizChainlink.connect(buyer).buyOption(optionId);
    const buyOptionTxReceipt = await buyOptionTx.wait(WAIT_CONFIRMATION);
    console.log(buyOptionTxReceipt);
    if ((await opWizChainlink.options(optionId)).participant == buyer.address){
        console.log(`Buy Option Success`);
    } else {
        console.log(`Buy Option Fail`);
    }
}

export default buyOption;