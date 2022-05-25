import { ethers, network } from "hardhat";
import { OpWizChainlinkCompatible } from "../typechain";
import { developmentChains } from "../helper-hardhat-config";
import { ERC20__factory } from "../typechain/factories/ERC20__factory";
import { ERC20 } from "../typechain/ERC20";


export async function withdrawPremium(optionId : number){

    const { initiator }= await ethers.getNamedSigners();
    const WAIT_CONFIRMATION = developmentChains.includes(network.name) ? 1 : 6;
    const opWizChainlink : OpWizChainlinkCompatible = await ethers.getContract("OpWizChainlinkCompatible");
    const premiumAsset = (await opWizChainlink.options(optionId)).premiumAsset;
    const premiumAmount = (await opWizChainlink.options(optionId)).premiumAmount;
    const premiumToken = new ethers.Contract(premiumAsset, ERC20__factory.abi, initiator) as ERC20; 
    const balanceBefore = await premiumToken.balanceOf(initiator.address);
    const withdrawPremiumTx = await opWizChainlink.connect(initiator).withdrawPremium(optionId);
    const withdrawPremiumTxReceipt = await withdrawPremiumTx.wait(WAIT_CONFIRMATION);
    console.log(withdrawPremiumTxReceipt);
    const balanceAfter = await premiumToken.balanceOf(initiator.address);
    if ((balanceAfter.sub(balanceBefore)) == premiumAmount){
        console.log(`Withdraw Premium Asset Success`);
    } else {
        console.log(`Withdraw Premium Asset Fail`);
    }
    console.log(`Balance of ${initiator.address} for token at address ${premiumAsset} is ${balanceAfter}`);
}

withdrawPremium(1)
.then(() => "Premium withdrawn")
.catch((error) => {
    console.error(error)
    process.exit(1)
  });
  
export default withdrawPremium;
