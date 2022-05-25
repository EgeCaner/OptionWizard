import { expect } from "chai";
import { Wallet } from "ethers";
import { defaultAbiCoder } from "ethers/lib/utils";
import { developmentChains } from "../helper-hardhat-config";
import { ethers, network } from "hardhat";
import { it } from "mocha";
import { OpWizChainlinkCompatible, OpWizChainlinkCompatible__factory, SimpleERC20 } from "../typechain";

(developmentChains.includes(network.name))
  ? describe.skip
  : describe("Bytes calldatta signature verification", function(){
    let wallet: Wallet, acc1: Wallet, erc20_t1: SimpleERC20,
    erc20_t2: SimpleERC20, opWiz: OpWizChainlinkCompatible;
    beforeEach(async function(){
        [wallet, acc1]= await (ethers as any).getSigners();
        const ERC20 = await ethers.getContractFactory("SimpleERC20");
        const OpWizChainlinkFactory = await ethers.getContractFactory("OpWizChainlinkCompatible") as OpWizChainlinkCompatible__factory;
        opWiz = await OpWizChainlinkFactory.deploy() as OpWizChainlinkCompatible;
        await opWiz.deployed();
        erc20_t1 = (await ERC20.deploy("token1","TKNO", 1000000, wallet.address)) as SimpleERC20;
        await erc20_t1.deployed();
        expect(await erc20_t1.balanceOf(wallet.address)).to.equal(1000000);
        erc20_t2 = (await ERC20.deploy("token2","TKNT", 1000000, wallet.address)) as SimpleERC20;
        await erc20_t2.deployed();
        expect(await erc20_t2.balanceOf(wallet.address)).to.equal(1000000);
        let tx = await erc20_t1.approve(opWiz.address, 50000);
        await tx.wait(1);
        await expect(opWiz.offerOption(erc20_t1.address, erc20_t2.address, erc20_t1.address,  50000, 30000, 3000, 2000, 1000)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, true);
        tx = await erc20_t2.connect(wallet).transfer(acc1.address, 500000);
        await tx.wait(1);
        tx = await erc20_t1.connect(wallet).transfer(acc1.address, 500000);
        await tx.wait(1);
        expect(await erc20_t1.balanceOf(acc1.address)).to.equal(500000);
        expect(await erc20_t2.balanceOf(acc1.address)).to.equal(500000);
        erc20_t1.connect(acc1).approve(opWiz.address, 3000);
        await expect(opWiz.connect(acc1).participateOption(1)).to.emit(opWiz, "Participate").withArgs(acc1.address, 1);
        let optionInfo  = await opWiz.options(1);
        expect(optionInfo.participant).to.equal(acc1.address);
        expect((await opWiz.options(1)).amountOfColleteral).to.equal(50000);
        expect(await erc20_t1.balanceOf(opWiz.address)).to.equal(53000);
        //withdraw premium
        await expect(opWiz.connect(wallet).withdrawPremium(1)).to.emit(opWiz, "WithdrawPremium").withArgs(wallet.address, 1, 3000);
        expect(await erc20_t1.balanceOf(wallet.address)).to.equal(453000);
    });

    /*it("Should revert if signature not verifies", async function(){
        const params = defaultAbiCoder.encode(["uint", "int"], [1, 2]);
        const signature = await wallet.signMessage(params);
        console.log(`Ts: Signature: ${signature}`);
        const txParams = defaultAbiCoder.encode(["uint", "int", "string"], [1 ,2, signature]);
        const txParamsDecoded =defaultAbiCoder.decode(["uint", "int", "string"], txParams);
        console.log(`Ts: Encoded params: ${txParams}`);
        console.log(`Ts: Decoded params: ${txParamsDecoded}`);
        console.log(`Ts: Wallet address ${wallet.address}`);
        console.log(ethers.utils.verifyMessage(params, signature));
        //await opWiz.connect(acc1).checkUpkeep(txParams);
    });*/

    it("Should verify the signature", async function(){
        //create calldata params here
        const params = defaultAbiCoder.encode(["uint", "int"], [1, 2]);
        const signature = await acc1.signMessage(params);
        console.log(`Signature: ${signature}`);
        const txParams = defaultAbiCoder.encode(["bytes", "bytes"], [signature ,params]);
        const txParamsDecoded =defaultAbiCoder.decode(["uint", "int", "bytes"], txParams);
        console.log(`Ts: Encoded params: ${txParams}`);
        console.log(`Ts: Decoded params: ${txParamsDecoded}`);
        console.log(`Ts: Acc1 address ${acc1.address}`);
        const hash = ethers.utils.keccak256(params);
        console.log(`TS: ${ethers.utils.verifyMessage(params, signature)}`);
        console.log(`TS: ${ethers.utils.recoverAddress(hash, signature)}`);
        const signer_ = await opWiz.connect(acc1).verify(params, signature);
        console.log(`TS:  Signer: ${signer_}`);
    });

});
   
