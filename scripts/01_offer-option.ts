import { BigNumberish, Contract } from "ethers";
import { ethers, network } from "hardhat";
import { Address } from "hardhat-deploy/types";
import { OpWizChainlinkCompatible } from "../typechain";
import { developmentChains } from "../helper-hardhat-config";
import { ERC20__factory } from "../typechain/factories/ERC20__factory";
import { ERC20 } from "../typechain/ERC20";
import { parseEther } from "ethers/lib/utils";


export async function offer(
    colleteral : Address, 
    counterAsset: Address, 
    premiumAsset: Address, 
    colleteralAmount: BigNumberish,
    counterAmount: BigNumberish,
    premiumAmount: BigNumberish,
    offerEnd: BigNumberish,
    optionExpiry: BigNumberish 
    ){

    const { initiator }= await ethers.getNamedSigners();
    const WAIT_CONFIRMATION = developmentChains.includes(network.name) ? 1 : 6;
    const colleteralToken = new ethers.Contract(colleteral, ERC20__factory.abi, initiator) as ERC20; 
    const opWizChainlink : OpWizChainlinkCompatible = await ethers.getContract("OpWizChainlinkCompatible");
    const approveTx = await colleteralToken.connect(initiator).approve(opWizChainlink.address, colleteralAmount);
    await approveTx.wait(WAIT_CONFIRMATION);
    
    const offerTx = await opWizChainlink.connect(initiator).offerOption(
        colleteral,
        counterAsset, 
        premiumAsset, 
        colleteralAmount, 
        counterAmount, 
        premiumAmount, 
        optionExpiry, 
        offerEnd
    );

    const offerTxReceipt = await offerTx.wait(WAIT_CONFIRMATION);
    console.log(offerTxReceipt);
}

var erc20 : ERC20;
ethers.getContract("SimpleERC20")
.then((contract: Contract) =>  
{
    erc20 = contract as ERC20 
    offer(
        erc20.address, 
        erc20.address, 
        erc20.address, 
        parseEther('2'), 
        parseEther('1'), 
        parseEther('0.2'), 
        20000, 
        10000
        )
        .then(() => console.log("Offer Made"))
        .catch((error) => {
            console.error(error)
            process.exit(1)
          });
})
.catch((error) => {
    console.error(error)
    process.exit(1)
  });

export default offer;