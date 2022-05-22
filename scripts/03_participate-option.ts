import { ethers, network } from "hardhat";
import { OpWizChainlinkCompatible } from "../typechain";
import { developmentChains } from "../helper-hardhat-config";
import { ERC20__factory } from "../typechain/factories/ERC20__factory";
import { ERC20 } from "../typechain/ERC20";

export async function participate(optionId: number){

    const { participator }= await ethers.getNamedSigners();
    const WAIT_CONFIRMATION = developmentChains.includes(network.name) ? 1 : 6;
    console.log(`Participator Address: ${participator.address}`);
    const opWizChainlink : OpWizChainlinkCompatible = await ethers.getContract("OpWizChainlinkCompatible");
    const premiumAsset = (await opWizChainlink.options(optionId)).premiumAsset;
    const premiumAmount = (await opWizChainlink.options(optionId)).premiumAmount;
    console.log(`Premium assets: ${premiumAsset}\nPremium Amount: ${premiumAmount}`);
    const premiumToken = new ethers.Contract(premiumAsset, ERC20__factory.abi, participator) as ERC20; 
    
    const approveTx = await premiumToken.connect(participator).approve(opWizChainlink.address, premiumAmount);
    await approveTx.wait(WAIT_CONFIRMATION);
    console.log("Token Approved");
    const participant = (await opWizChainlink.options(optionId)).participant;
    const offerEnd = (await opWizChainlink.optionDetails(optionId)).offerEnd;
    console.log(`Participator is: ${participant}\nOffer Ends in block: ${offerEnd}`);
    const participateTx = await opWizChainlink.connect(participator).participateOption(optionId);

    const participateTxReceipt = await participateTx.wait(WAIT_CONFIRMATION);
    console.log(participateTxReceipt);
}

participate(1)
.then(() => console.log(`Participated in option`))
.catch((error) => {
    console.error(error)
    process.exit(1)
  });

export default participate;