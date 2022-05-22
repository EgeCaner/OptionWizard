import { BigNumberish, Contract } from "ethers";
import { ethers, network } from "hardhat";
import { Address } from "hardhat-deploy/types";
import { developmentChains } from "../helper-hardhat-config";
import { ERC20__factory } from "../typechain/factories/ERC20__factory";
import { ERC20 } from "../typechain/ERC20";
import { parseEther } from "ethers/lib/utils";


export async function sendERC20TokenTo(tokenAddress: Address, to: Address, amount: BigNumberish){
    const { initiator }= await ethers.getNamedSigners();
    const WAIT_CONFIRMATION = developmentChains.includes(network.name) ? 1 : 6;
    const tokenContract = new ethers.Contract(tokenAddress, ERC20__factory.abi, initiator) as ERC20; 
    const transferTx = await tokenContract.connect(initiator).transfer(to, amount);
    await transferTx.wait(WAIT_CONFIRMATION);
}

var erc20 : ERC20;
ethers.getContract("SimpleERC20")
.then((contract: Contract) =>  
{
    erc20 = contract as ERC20 
    ethers.getNamedSigners()
    .then(({ participator }) =>  sendERC20TokenTo(erc20.address, participator.address, parseEther("2"))
    .then(() => console.log("ERC20 Token Transfer Made"))
    .catch((error) => {
        console.error(error)
        process.exit(1)
      })
    )
    .catch((error) => {
        console.error(error)
        process.exit(1)
      })
   
})
.catch((error) => {
    console.error(error)
    process.exit(1)
  });

export default sendERC20TokenTo;