import { ethers, network } from "hardhat";
import { OpWizChainlinkCompatible, ERC20__factory, ERC20 } from "../typechain";
import { developmentChains } from "../helper-hardhat-config";
import { Address } from "hardhat-deploy/types";
import { BigNumberish, Contract } from "ethers";
import { parseEther } from "ethers/lib/utils";

export async function approveToken(tokenAddress: Address, amount: BigNumberish){

    const { participator }= await ethers.getNamedSigners();
    const WAIT_CONFIRMATION = developmentChains.includes(network.name) ? 1 : 6;
    const token = new ethers.Contract(tokenAddress, ERC20__factory.abi, participator) as ERC20; 
    const opWizChainlink : OpWizChainlinkCompatible = await ethers.getContract("OpWizChainlinkCompatible");
    const approveTx = await token.connect(participator).approve(opWizChainlink.address, amount);
    await approveTx.wait(WAIT_CONFIRMATION);
}

var erc20 : ERC20;
ethers.getContract("SimpleERC20")
.then((contract: Contract) =>  
{
    erc20 = contract as ERC20 
    approveToken(
        erc20.address,
        parseEther('1'), 
        )
        .then(() => console.log("Approve Token"))
        .catch((error) => {
            console.error(error)
            process.exit(1)
          });
})
.catch((error) => {
    console.error(error)
    process.exit(1)
  });
  
export default approveToken;