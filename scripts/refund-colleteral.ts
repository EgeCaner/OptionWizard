import { ethers, network } from "hardhat";
import { OpWizChainlinkCompatible } from "../typechain";
import { developmentChains } from "../helper-hardhat-config";
import { ERC20__factory } from "../typechain/factories/ERC20__factory";
import { ERC20 } from "../typechain/ERC20";


export async function refundColleteral(optionId : number){

    const { initiator }= await ethers.getNamedSigners();
    const WAIT_CONFIRMATION = developmentChains.includes(network.name) ? 1 : 6;
    const opWizChainlink : OpWizChainlinkCompatible = await ethers.getContract("OpWizChainlinkCompatible");
    const colleteral = (await opWizChainlink.options(optionId)).colleteral;
    const colleteralToken = new ethers.Contract(colleteral, ERC20__factory.abi, initiator) as ERC20; 
    const balanceBefore = await colleteralToken.balanceOf(initiator.address);
    const amountOfColleteral = (await opWizChainlink.options(optionId)).amountOfColleteral;
    const refundColleteralTx = await opWizChainlink.connect(initiator).refundColleteral(optionId);
    const balanceAfter = await colleteralToken.balanceOf(initiator.address);
    const refundColleteralTxReceipt = await refundColleteralTx.wait(WAIT_CONFIRMATION);
    console.log(refundColleteralTxReceipt);
    if ((balanceAfter.sub(balanceBefore)) == amountOfColleteral){
        console.log(`Refund Colleteral Success`);
    } else {
        console.log(`Refund Colleteral Fail`);
    }
    console.log(`Balance of ${initiator.address} for token at address ${colleteral} is ${balanceAfter}`);
}

export default refundColleteral;