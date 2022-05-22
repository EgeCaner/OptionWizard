import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { developmentChains } from "../helper-hardhat-config";
import { ethers } from "hardhat";

const deployFunction : DeployFunction  = async function(hre: HardhatRuntimeEnvironment){
    
    const { getNamedAccounts, deployments, network } = hre; 
    const { deploy, log }=  deployments;
    const { deployer, initiator } = await getNamedAccounts();
    log("Deploying ERC20Token...");
    const simpleERC20Contract = await deploy("SimpleERC20", {
        from: deployer,
        args: ["Test", "TST", ethers.utils.parseEther('100000'), initiator],
        log: true,
        waitConfirmations: developmentChains.includes(network.name) ? 1 : 6
    });
    console.log(`Deployed ERC20Token on network: ${network.name}, and on address: ${simpleERC20Contract.address}`);
    console.log(`Deployer Address: ${deployer}`);
}

export default deployFunction;
deployFunction.tags = ['all', 'ERC20'];