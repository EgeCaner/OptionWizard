import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { developmentChains } from "../helper-hardhat-config";
const deployFunction : DeployFunction  = async function(hre: HardhatRuntimeEnvironment){
    
    const { getNamedAccounts, deployments, network } = hre; 
    const { deploy, log }=  deployments;
    const { deployer } = await getNamedAccounts();
    log("Deploying OpWizChainlinkCompatible...");
    const opWizChainlinkCompatibleContract = await deploy("OpWizChainlinkCompatible", {
        from: deployer,
        args: [],
        log: true,
        waitConfirmations: developmentChains.includes(network.name) ? 1 : 6
    });
    console.log(`Deployed OpWizChainlinkCompatible on network: ${network.name}, and on address: ${opWizChainlinkCompatibleContract.address}`);
}

export default deployFunction;
deployFunction.tags = ['all', 'OpWizChainlink'];