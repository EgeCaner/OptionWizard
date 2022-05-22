import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const deployFunction : DeployFunction  = async function(hre: HardhatRuntimeEnvironment){
    
    const { getNamedAccounts, deployments, network } = hre; 
    const { deploy, log }=  deployments;
    const { deployer } = await getNamedAccounts();
    log("Deploying OpWizChainlinkCompatible...");
    const opWizFlashExerciseContract = await deploy("OpWizFlashExercise", {
        from: deployer,
        args: [],
        log: true,
        waitConfirmations: 1
    });
    console.log(`Deployed OpWizChainlinkCompatible on network: ${network.name}, and on address: ${opWizFlashExerciseContract.address}`);
}

export default deployFunction;