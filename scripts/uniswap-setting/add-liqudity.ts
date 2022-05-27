import { BigNumberish, Contract } from "ethers";
import { ethers, network } from "hardhat";
import { Address } from "hardhat-deploy/types";
import { developmentChains, UNISWAP_FACTORY, networkConfig} from "../../helper-hardhat-config";
import { IUniswapV3Pool__factory } from "../../typechain/factories/IUniswapV3Pool__factory";
import { IUniswapV3Pool } from "../../typechain/IUniswapV3Pool";

export async function createUniswapPool(token0: Address, token1: Address, fee: BigNumberish){
    const { participator }= await ethers.getNamedSigners();
    const WAIT_CONFIRMATION = developmentChains.includes(network.name) ? 1 : 6;
    const uniswapPool = new ethers.Contract(
        UNISWAP_FACTORY, 
        IUniswapV3Pool__factory.abi, 
        participator
    ) as IUniswapV3Pool;
    /*let createPoolTx = await uniswapPool.mint(participator.address, );
    let txReceipt = await createPoolTx.wait(WAIT_CONFIRMATION);
    console.log(txReceipt);
    console.log(txReceipt.events);*/
}
ethers.getContract("SimpleERC20")
.then((contract : Contract) => {
    createUniswapPool(contract.address, networkConfig[42].linkToken as string, 3500)
    .then(()=> console.log(`pool created`));
})
.catch((error) => {
    console.error(error)
    process.exit(1)
  });