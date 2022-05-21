import { Wallet } from "ethers";
import { ethers } from "hardhat";
import { OpWiz } from "../typechain/OpWiz";

async function deployOpwiz(){
    let walletPath = {
        "standard": "m/44'/60'/0'/0/0",
    
        // @TODO: Include some non-standard wallet paths
    };
    
    let mnemonic = process.env.KOVAN_PRIVATE_KEY;
    if(mnemonic){
        let hdnode = ethers.utils.HDNode.fromMnemonic(mnemonic);
        let node = hdnode.derivePath(walletPath.standard);
        var provider = ethers.getDefaultProvider("kovan");
        var wallet: Wallet = new ethers.Wallet(node.privateKey, provider);
        const Opwiz = await ethers.getContractFactory("OpWiz", wallet);
        const contract : OpWiz = await Opwiz.deploy();
        console.log(contract.address);
        console.log(contract.deployTransaction.hash);
        await contract.deployed();
    } else {
        throw Error("mnemonic undefined");
    }
   
}

deployOpwiz().then(() => process.exit(0))
.catch((error) => {
    console.error(error)
    process.exit(1)
  });