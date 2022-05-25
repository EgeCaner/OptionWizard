import { ethers, network } from "hardhat";
import { OpWizChainlinkCompatible } from "../typechain";
import { developmentChains } from "../helper-hardhat-config";
import { ERC20__factory } from "../typechain/factories/ERC20__factory";
import { ERC20 } from "../typechain/ERC20";


export async function withdrawCounterAsset(optionId : number){

    const { initiator }= await ethers.getNamedSigners();
    const WAIT_CONFIRMATION = developmentChains.includes(network.name) ? 1 : 6;
    const opWizChainlink : OpWizChainlinkCompatible = await ethers.getContract("OpWizChainlinkCompatible");
    const counterAsset = (await opWizChainlink.options(optionId)).counterAsset;
    const counterAmount = (await opWizChainlink.options(optionId)).amountOfCA;
    const counterToken = new ethers.Contract(counterAsset, ERC20__factory.abi, initiator) as ERC20; 
    const balanceBefore = await counterToken.balanceOf(initiator.address);
    const withdrawCATx = await opWizChainlink.connect(initiator).withdrawCA(optionId);
    const withdrawCATxReceipt = await withdrawCATx.wait(WAIT_CONFIRMATION);
    console.log(withdrawCATxReceipt);
    const balanceAfter = await counterToken.balanceOf(initiator.address);
    if ((balanceAfter.sub(balanceBefore)) == counterAmount){
        console.log(`Withdraw Counter Asset Success`);
    } else {
        console.log(`Withdraw Counter Asset Fail`);
    }
    console.log(`Balance of ${initiator.address} for token at address ${counterAsset} is ${balanceAfter}`);
}

withdrawCounterAsset(1)
.then(() => console.log("Withdraw Counter Asset Success"))
.catch((error) => {
    console.error(error)
    process.exit(1)
  });

export default withdrawCounterAsset;