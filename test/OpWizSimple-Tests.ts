import { expect } from "chai";
import { Wallet } from "ethers";
import { ethers } from "hardhat";
import { it } from "mocha";
import { SimpleERC20, OpWizSimple } from "../typechain";
import { moveBlocks } from "../utils/move-blocks";
 
describe("OpWiz Tests: ERC20&ERC20 options", function () {

    let wallet: Wallet, acc1: Wallet, acc2: Wallet, erc20_t1: SimpleERC20,
     erc20_t2: SimpleERC20, opWiz: OpWizSimple;

    beforeEach(async function (){

       [wallet, acc1, acc2]= await (ethers as any).getSigners();
       const ERC20 = await ethers.getContractFactory("SimpleERC20");
       const OpwizSimple = await ethers.getContractFactory("OpWizSimple");
       erc20_t1 = (await ERC20.deploy("token1","TKNO", 1000000, wallet.address)) as SimpleERC20;
       await erc20_t1.deployed();
       expect(await erc20_t1.balanceOf(wallet.address)).to.equal(1000000);
       erc20_t2 = (await ERC20.deploy("token2","TKNT", 1000000, wallet.address)) as SimpleERC20;
       await erc20_t2.deployed();
       expect(await erc20_t2.balanceOf(wallet.address)).to.equal(1000000);
       opWiz = (await OpwizSimple.deploy()) as OpWizSimple;
       await opWiz.deployed();
    });

    describe ("OfferOption with ERC20 colleteral", function() {
        it("OfferOption ERC20 to ERC20 with ERC20 premium", async () => {
            let tx = await erc20_t1.approve(opWiz.address, 50000);
            await tx.wait(1);
            await expect(opWiz.offerOption(erc20_t1.address, erc20_t2.address, erc20_t1.address,  50000, 30000, 3000, 2000, 1000)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, true);
        });
    });

    describe ("Paricipate in offered option", function() {
      beforeEach(async function () {
        let tx = await erc20_t1.approve(opWiz.address, 50000);
        await tx.wait(1);
        await expect(opWiz.offerOption(erc20_t1.address, erc20_t2.address, erc20_t1.address,  50000, 30000, 3000, 2000, 1000)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, true);
        tx = await erc20_t2.connect(wallet).transfer(acc1.address, 500000);
        await tx.wait(1);
        tx = await erc20_t1.connect(wallet).transfer(acc1.address, 500000);
        await tx.wait(1);
        expect(await erc20_t1.balanceOf(acc1.address)).to.equal(500000);
        expect(await erc20_t2.balanceOf(acc1.address)).to.equal(500000);
      }); 
  
      it("Participates in ERC20 to ERC20 with ERC20 premium", async () => {
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

      it("Sell option in exhange of ERC20 token", async () => {
        erc20_t1.connect(acc1).approve(opWiz.address, 3000);
        await expect(opWiz.connect(acc1).participateOption(1)).to.emit(opWiz, "Participate").withArgs(acc1.address, 1);
        let optionInfo  = await opWiz.options(1);
        expect(optionInfo.participant).to.equal(acc1.address);
        expect((await opWiz.options(1)).amountOfColleteral).to.equal(50000);
        expect(await erc20_t1.balanceOf(opWiz.address)).to.equal(53000);
        //withdraw premium
        await expect(opWiz.connect(wallet).withdrawPremium(1)).to.emit(opWiz, "WithdrawPremium").withArgs(wallet.address, 1, 3000);
        expect(await erc20_t1.balanceOf(wallet.address)).to.equal(453000);
        await expect(opWiz.connect(acc1).listOption(1, erc20_t2.address, 20000)).to.emit(opWiz, "Listed").withArgs(1, true);
        await erc20_t2.connect(wallet).transfer(acc2.address, 40000);
        await erc20_t2.connect(acc2).approve(opWiz.address, 20000);
        let tx = await opWiz.connect(acc2).buyOption(1);
        let txEvents = (await tx.wait(1)).events;
        txEvents?.pop();
        let event = txEvents?.pop();
        if (event && event.args) {
          expect(event.event).to.equal("Transfer");
          expect(event.args[0]).to.equal(acc1.address);
          expect(event.args[1]).to.equal(acc2.address);
          expect(event.args[2]).to.equal(1);
        }
        expect((await opWiz.options(1)).participant).to.equal(acc2.address);
        expect(await erc20_t2.balanceOf(acc2.address)).to.equal(20000);
        await erc20_t2.connect(acc1).approve(opWiz.address, 20000);
        await expect(opWiz.connect(acc1).buyOption(1)).to.be.revertedWith("D14");
        await expect(opWiz.connect(acc1).withdraw(erc20_t2.address, 20000)).to.emit(opWiz, "Withdraw").withArgs(erc20_t2.address, acc1.address, 20000);
        expect(await erc20_t2.balanceOf(acc1.address)).to.equal(520000);
      });

      describe ("Exercise option scenarios", function() {

        beforeEach(async () => {
          await expect(opWiz.connect(wallet).withdrawPremium(1)).to.be.revertedWith("D12");
          await erc20_t1.connect(acc1).approve(opWiz.address, 3000);
          await expect(opWiz.connect(acc1).participateOption(1)).to.emit(opWiz, "Participate").withArgs(acc1.address, 1);
          let optionInfo  = await opWiz.options(1);
          expect(optionInfo.participant).to.equal(acc1.address);
          await erc20_t1.connect(wallet).approve(opWiz.address, 3000);
          await expect(opWiz.connect(wallet).participateOption(1)).to.be.revertedWith("D13");
          expect((await opWiz.options(1)).amountOfColleteral).to.equal(50000);
          expect(await erc20_t1.balanceOf(opWiz.address)).to.equal(53000);
          //withdraw premium
          await expect(opWiz.connect(wallet).withdrawPremium(1)).to.emit(opWiz, "WithdrawPremium").withArgs(wallet.address, 1, 3000);
          expect(await erc20_t1.balanceOf(wallet.address)).to.equal(453000);
          await expect(opWiz.connect(wallet).withdrawPremium(1)).to.be.revertedWith("D11");
        });

        it("Exercise option receive colleteral& withdraw counter asset", async () => {
          await expect(opWiz.connect(wallet).withdrawCA(1)).to.be.revertedWith("D10");
          let tx = await erc20_t2.connect(acc1).approve(opWiz.address, 30000);
          await tx.wait(1);
          await expect(opWiz.connect(acc1).exerciseOption(1)).to.emit(opWiz, "Exercise").withArgs(acc1.address, 1);
          tx = await erc20_t2.connect(acc1).approve(opWiz.address, 30000);
          await tx.wait(1);
          await  expect(opWiz.connect(acc1).exerciseOption(1)).to.be.revertedWith("D7");
          expect(await erc20_t2.balanceOf(acc1.address)).to.equal(470000);
          expect(await erc20_t1.balanceOf(acc1.address)).to.equal(547000);
          await expect(opWiz.connect(wallet).withdrawCA(1)).to.emit(opWiz, "WithdrawCA").withArgs(wallet.address, 1, 30000);
          await expect(opWiz.connect(wallet).withdrawCA(1)).to.be.revertedWith("D11");
          expect(await erc20_t2.balanceOf(wallet.address)).to.equal(530000);
        });

        it("Should revert if expired options tries to get exercised & withdraw colleteral", async () => {
          await expect(opWiz.connect(wallet).withdrawCA(1)).to.be.revertedWith("D10");
          let tx = await erc20_t2.connect(acc1).approve(opWiz.address, 30000);
          await tx.wait(1);
          await expect(opWiz.connect(wallet).refundColleteral(1)).to.emit(opWiz, "WithdrawColleteral").to.revertedWith("D4");
          await moveBlocks(2000);
          await expect(opWiz.connect(acc1).exerciseOption(1)).to.be.revertedWith("D9");
          await expect(opWiz.connect(wallet).refundColleteral(1)).to.emit(opWiz, "WithdrawColleteral").withArgs(wallet.address, 1, 50000);
          await expect(opWiz.connect(wallet).refundColleteral(1)).to.emit(opWiz, "WithdrawColleteral").withArgs(wallet.address, 1, 0);
        });
    });
  });
});
