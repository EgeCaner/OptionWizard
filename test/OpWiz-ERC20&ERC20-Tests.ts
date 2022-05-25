import { expect } from "chai";
import { Wallet } from "ethers";
import { ethers, network } from "hardhat";
import { it } from "mocha";
import { SimpleERC721, SimpleERC1155, SimpleERC20, OpWiz, SimpleERC721__factory, SimpleERC1155__factory, SimpleERC20__factory, OpWiz__factory } from "../typechain";
import { moveTime } from "../utils/move-time";
import { developmentChains } from "../helper-hardhat-config";
 
(!developmentChains.includes(network.name))
  ? describe.skip
  :describe("OpWiz Tests: ERC20&ERC20 options", function () {

    let wallet: Wallet, acc1: Wallet, acc2: Wallet, erc20_t1: SimpleERC20,
     erc20_t2: SimpleERC20, erc721: SimpleERC721, erc1155: SimpleERC1155 , opWiz: OpWiz;

    beforeEach(async function (){

       [wallet, acc1, acc2]= await (ethers as any).getSigners();
       const ERC721_Factory = await ethers.getContractFactory("SimpleERC721") as SimpleERC721__factory;
       const ERC1155 = await ethers.getContractFactory("SimpleERC1155") as SimpleERC1155__factory;
       const ERC20 = await ethers.getContractFactory("SimpleERC20") as SimpleERC20__factory;
       const Opwiz = await ethers.getContractFactory("OpWiz") as OpWiz__factory;
       erc721 = (await ERC721_Factory.deploy("test","TST"));
       await erc721.deployed();
       erc1155 = (await ERC1155.deploy("test"));
       await erc1155.deployed();
       erc20_t1 = (await ERC20.deploy("token1","TKNO", 1000000, wallet.address));
       await erc20_t1.deployed();
       expect(await erc20_t1.balanceOf(wallet.address)).to.equal(1000000);
       erc20_t2 = (await ERC20.deploy("token2","TKNT", 1000000, wallet.address));
       await erc20_t2.deployed();
       expect(await erc20_t2.balanceOf(wallet.address)).to.equal(1000000);
       opWiz = (await Opwiz.deploy());
       await opWiz.deployed();
       await expect(erc721.mint(wallet.address, 1)).to.emit(erc721, 'Transfer').withArgs(ethers.constants.AddressZero, wallet.address, 1);
       await expect(erc1155.mint(wallet.address, 1, 5)).to.emit(erc1155, "TransferSingle").withArgs(wallet.address, ethers.constants.AddressZero, wallet.address, 1, 5);
       //console.log(`Address of owner: ${wallet.address}\nAddress of other: ${acc1.address}\nAddress of ERC20-1: ${erc20_t1.address}\nAddress of ERC20-2: ${erc20_t2.address}\nAddress of ERC721: ${erc721.address}\nAddress of ERC1155: ${erc1155.address}\nAddress of OpWiz: ${opWiz.address}`)
    });

    describe ("OfferOption with ERC20 colleteral", function() {
        it("OfferOption ERC20 to ERC20 with ERC20 premium", async () => {
          await expect(opWiz.offerOption(erc20_t1.address, erc20_t2.address, erc20_t1.address, 0, 0 ,0)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, false);
          let tx = await erc20_t1.approve(opWiz.address, 50000);
          await tx.wait(1);
          await expect(await opWiz.setOptionParams(1, 50000, 30000, 3000, 1000, 100)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, true);
        });
    });

    describe ("Paricipate in offered option", function() {
      beforeEach(async function () {
        await expect(opWiz.offerOption(erc20_t1.address, erc20_t2.address, erc20_t1.address, 0, 0 ,0)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, false);
        let tx = await erc20_t1.approve(opWiz.address, 50000);
        await tx.wait(1);
        await expect(opWiz.setOptionParams(1, 50000, 30000, 3000, 1000, 100)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, true);
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
        await expect(opWiz.connect(acc1).listOption(1, erc20_t2.address, 0, 20000)).to.emit(opWiz, "Listed").withArgs(1, true);
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
        await expect(opWiz.connect(acc1).withdraw(erc20_t2.address, 0, 20000)).to.emit(opWiz, "Withdraw").withArgs(erc20_t2.address, acc1.address, 20000);
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
          await moveTime(2000*86400);
          await expect(opWiz.connect(acc1).exerciseOption(1)).to.be.revertedWith("D9");
          await expect(opWiz.connect(wallet).refundColleteral(1)).to.emit(opWiz, "WithdrawColleteral").withArgs(wallet.address, 1, 50000);
          await expect(opWiz.connect(wallet).refundColleteral(1)).to.emit(opWiz, "WithdrawColleteral").withArgs(wallet.address, 1, 0);
        });
    });
  });
});
