
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const deployFunction : DeployFunction  = async function(hre: HardhatRuntimeEnvironment){
    
    const { getNamedAccounts, deployments, network } = hre; 
    const { deploy, log }=  deployments;
    const { deployer } = await getNamedAccounts();
    log("Deploying OpWiz...");
    const opWizContract = await deploy("OpWiz", {
        from: deployer,
        args: [],
        log: true,
        waitConfirmations: 1
    });
    console.log(`Deployed OpWiz on network: ${network.name}, and on address: ${opWizContract.address}`);
}

export default deployFunction;