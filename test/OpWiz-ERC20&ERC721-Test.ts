import { expect } from "chai";
import { Wallet } from "ethers";
import { ethers } from "hardhat";
import { it } from "mocha";
import { OpWiz } from "../typechain/OpWiz";
import { SimpleERC721 } from "../typechain/SimpleERC721";
import { SimpleERC1155 } from "../typechain/SimpleERC1155";
import  { SimpleERC20 } from "../typechain/SimpleERC20";
import { moveBlocks } from "../utils/move-blocks";

describe("OpWiz Tests: Options with multiple ERC standarts", function () {

    let wallet: Wallet, acc1: Wallet, acc2: Wallet, erc20_t1: SimpleERC20,
     erc20_t2: SimpleERC20, erc721: SimpleERC721, erc1155: SimpleERC1155 , opWiz: OpWiz, abiCoder = ethers.utils.defaultAbiCoder;

    beforeEach(async function (){

       [wallet, acc1, acc2]= await (ethers as any).getSigners();
       const ERC721 = await ethers.getContractFactory("SimpleERC721");
       const ERC1155 = await ethers.getContractFactory("SimpleERC1155");
       const ERC20 = await ethers.getContractFactory("SimpleERC20");
       const Opwiz = await ethers.getContractFactory("OpWiz");
       erc721 = (await ERC721.deploy("test","TST"));
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

    describe ("ERC721 colleteral", function() {
          
        it("OfferOption ERC721 to ERC20 with ERC20 premium", async () => {
          expect(await opWiz.offerOption(erc721.address, erc20_t2.address, erc20_t1.address, 1, 0 ,0)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, false);
          let setOptionParamsInfo = abiCoder.encode(["uint8", "uint", "uint", "uint", "uint", "uint"], [1, 1, 50000, 3000, 2000, 1000]);
          expect(await erc721.connect(wallet)["safeTransferFrom(address,address,uint256,bytes)"](wallet.address, opWiz.address, 1, setOptionParamsInfo)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, true);
          expect(await erc721.balanceOf(opWiz.address)).to.equal(1);
          expect((await opWiz.options(1)).amountOfCA).to.equal(50000);
          expect((await opWiz.options(1)).premiumAmount).to.equal(3000);
          expect((await opWiz.options(1)).amountOfColleteral).to.equal(1);
          expect((await opWiz.optionDetails(1)).counterAssetType).to.equal(0);
          expect((await opWiz.optionDetails(1)).premiumAssetType).to.equal(0);
          expect((await opWiz.optionDetails(1)).colleteralType).to.equal(1);
        });

        it("OfferOption ERC721 to ERC721 with ERC20 premium", async () => {
          expect(await opWiz.offerOption(erc721.address, erc721.address, erc20_t1.address, 1, 2 ,0)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, false);
          let setOptionParamsInfo = abiCoder.encode(["uint8", "uint", "uint", "uint", "uint", "uint"], [1, 1, 50000, 3000, 2000, 1000]);
          expect(await erc721.connect(wallet)["safeTransferFrom(address,address,uint256,bytes)"](wallet.address, opWiz.address, 1, setOptionParamsInfo)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, true);
          expect(await erc721.balanceOf(opWiz.address)).to.equal(1);
          expect((await opWiz.options(1)).amountOfCA).to.equal(50000);
          expect((await opWiz.options(1)).premiumAmount).to.equal(3000);
          expect((await opWiz.options(1)).amountOfColleteral).to.equal(1);
          expect((await opWiz.optionDetails(1)).counterAssetType).to.equal(1);
          expect((await opWiz.optionDetails(1)).premiumAssetType).to.equal(0);
          expect((await opWiz.optionDetails(1)).colleteralType).to.equal(1);
        });

        it("OfferOption ERC721 to ERC1155 with ERC20 premium", async () => {
          expect(await opWiz.offerOption(erc721.address, erc1155.address, erc20_t1.address, 1, 2 ,0)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, false);
          let setOptionParamsInfo = abiCoder.encode(["uint8", "uint", "uint", "uint", "uint", "uint"], [1, 1, 50000, 3000, 2000, 1000]);
          expect(await erc721.connect(wallet)["safeTransferFrom(address,address,uint256,bytes)"](wallet.address, opWiz.address, 1, setOptionParamsInfo)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, true);
          expect(await erc721.balanceOf(opWiz.address)).to.equal(1);
          expect((await opWiz.options(1)).amountOfCA).to.equal(50000);
          expect((await opWiz.options(1)).premiumAmount).to.equal(3000);
          expect((await opWiz.options(1)).amountOfColleteral).to.equal(1);
          expect((await opWiz.optionDetails(1)).counterAssetType).to.equal(2);
          expect((await opWiz.optionDetails(1)).premiumAssetType).to.equal(0);
          expect((await opWiz.optionDetails(1)).colleteralType).to.equal(1);
        });
    });

    describe("Participate ERC721 colleteral options", function(){
      beforeEach(async function () {
        let tx = await erc20_t2.connect(wallet).transfer(acc1.address, 500000);
        await tx.wait(1);
        tx = await erc20_t1.connect(wallet).transfer(acc1.address, 500000);
        await tx.wait(1);
        expect(await erc20_t1.balanceOf(acc1.address)).to.equal(500000);
        expect(await erc20_t2.balanceOf(acc1.address)).to.equal(500000);
      }); 
      it("Participate ERC721 colleteral, ERC20 counter asset&ERC20 premium", async () => {
        expect(await opWiz.offerOption(erc721.address, erc20_t2.address, erc20_t1.address, 1, 0 ,0)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, false);
        let setOptionParamsInfo = abiCoder.encode(["uint8", "uint", "uint", "uint", "uint", "uint"], [1, 1, 50000, 3000, 2000, 1000]);
        expect(await erc721.connect(wallet)["safeTransferFrom(address,address,uint256,bytes)"](wallet.address, opWiz.address, 1, setOptionParamsInfo)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, true);
        expect(await erc721.balanceOf(opWiz.address)).to.equal(1);
        expect((await opWiz.options(1)).amountOfCA).to.equal(50000);
        expect((await opWiz.options(1)).premiumAmount).to.equal(3000);
        expect((await opWiz.options(1)).amountOfColleteral).to.equal(1);
        expect((await opWiz.optionDetails(1)).counterAssetType).to.equal(0);
        expect((await opWiz.optionDetails(1)).premiumAssetType).to.equal(0);
        expect((await opWiz.optionDetails(1)).colleteralType).to.equal(1);
        await erc20_t1.connect(acc1).approve(opWiz.address, 3000);
        expect(await opWiz.connect(acc1).participateOption(1)).to.emit(opWiz, "Participate").withArgs(acc1.address, 1);
        expect(await erc20_t1.balanceOf(opWiz.address)).to.equal(3000);
        expect(await opWiz.connect(wallet).withdrawPremium(1)).to.emit(opWiz, "WithdrawPremium").withArgs(wallet.address, 1, 3000);
        expect(await erc20_t1.balanceOf(wallet.address)).to.equal(503000);
      });
    
      it("Participate ERC721 colleteral, ERC20 counter asset&ERC721 premium", async () => {
        await expect(erc721.mint(wallet.address, 2)).to.emit(erc721, 'Transfer').withArgs(ethers.constants.AddressZero, wallet.address, 2);
        expect(await opWiz.offerOption(erc721.address, erc20_t2.address, erc721.address, 1, 0 ,2)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, false);
        let setOptionParamsInfo = abiCoder.encode(["uint8", "uint", "uint", "uint", "uint", "uint"], [1, 1, 50000, 1, 2000, 1000]);
        expect(await erc721.connect(wallet)["safeTransferFrom(address,address,uint256,bytes)"](wallet.address, opWiz.address, 1, setOptionParamsInfo)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, true);
        expect(await erc721.balanceOf(opWiz.address)).to.equal(1);
        expect((await opWiz.options(1)).amountOfCA).to.equal(50000);
        expect((await opWiz.options(1)).premiumAmount).to.equal(1);
        expect((await opWiz.options(1)).amountOfColleteral).to.equal(1);
        expect((await opWiz.optionDetails(1)).counterAssetType).to.equal(0);
        expect((await opWiz.optionDetails(1)).premiumAssetType).to.equal(1);
        expect((await opWiz.optionDetails(1)).colleteralType).to.equal(1);
        expect(await erc721.ownerOf(2)).to.equal(wallet.address);
        await erc721.connect(wallet)["safeTransferFrom(address,address,uint256)"](wallet.address, acc1.address, 2);
        let  participateOptionInfo = abiCoder.encode(["uint8", "uint"], [2, 1]);
        /*
        console.log(participateOptionInfo);
        console.log(setOptionParamsInfo);
        */
        expect(await erc721.connect(acc1)["safeTransferFrom(address,address,uint256,bytes)"](acc1.address, opWiz.address, 2, participateOptionInfo)).to.emit(opWiz, "Offer").withArgs(acc1.address, 1, true);
        expect((await opWiz.options(1)).participant).to.equal(acc1.address);
        expect(await erc721.balanceOf(opWiz.address)).to.equal(2);
        expect(await opWiz.connect(wallet).withdrawPremium(1)).to.emit(opWiz, "WithdrawPremium").withArgs(wallet.address, 1, 1);
        expect(await erc721.balanceOf(wallet.address)).to.equal(1);
        expect(await erc721.balanceOf(opWiz.address)).to.equal(1);
      });

      it("Participate ERC721 colleteral, ERC20 counter asset&ERC1155 premium", async () => {
        expect(await opWiz.offerOption(erc721.address, erc20_t2.address, erc1155.address, 1, 0 ,1)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, false);
        let setOptionParamsInfo = abiCoder.encode(["uint8", "uint", "uint", "uint", "uint", "uint"], [1, 1, 50000, 1, 2000, 1000]);
        expect(await erc721.connect(wallet)["safeTransferFrom(address,address,uint256,bytes)"](wallet.address, opWiz.address, 1, setOptionParamsInfo)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, true);
        expect(await erc721.balanceOf(opWiz.address)).to.equal(1);
        expect((await opWiz.options(1)).amountOfCA).to.equal(50000);
        expect((await opWiz.options(1)).premiumAmount).to.equal(1);
        expect((await opWiz.options(1)).amountOfColleteral).to.equal(1);
        expect((await opWiz.optionDetails(1)).counterAssetType).to.equal(0);
        expect((await opWiz.optionDetails(1)).premiumAssetType).to.equal(2);
        expect((await opWiz.optionDetails(1)).colleteralType).to.equal(1);
        await erc1155.connect(wallet).safeTransferFrom(wallet.address, acc1.address, 1, 1, ethers.constants.AddressZero);
        let  participateOptionInfo = abiCoder.encode(["uint8", "uint"], [2, 1]);
        /*
        console.log(participateOptionInfo);
        console.log(setOptionParamsInfo);
        */
        expect(await erc1155.connect(acc1).safeTransferFrom(acc1.address, opWiz.address, 1, 1, participateOptionInfo)).to.emit(opWiz, "Offer").withArgs(acc1.address, 1, true);
        expect((await opWiz.options(1)).participant).to.equal(acc1.address);
        expect(await erc721.balanceOf(opWiz.address)).to.equal(1);
        expect(await erc1155.balanceOf(opWiz.address, 1)).to.equal(1);
        expect(await erc1155.balanceOf(wallet.address, 1)).to.equal(4);
        expect(await opWiz.connect(wallet).withdrawPremium(1)).to.emit(opWiz, "WithdrawPremium").withArgs(wallet.address, 1, 1);
        expect(await erc1155.balanceOf(wallet.address, 1)).to.equal(5);
      });

      it("Option expires and refund colleteral", async () => {
        expect(await opWiz.offerOption(erc721.address, erc20_t2.address, erc1155.address, 1, 0 ,1)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, false);
        let setOptionParamsInfo = abiCoder.encode(["uint8", "uint", "uint", "uint", "uint", "uint"], [1, 1, 50000, 1, 2000, 1000]);
        expect(await erc721.connect(wallet)["safeTransferFrom(address,address,uint256,bytes)"](wallet.address, opWiz.address, 1, setOptionParamsInfo)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, true);
        expect(await erc721.balanceOf(opWiz.address)).to.equal(1);
        expect((await opWiz.options(1)).amountOfCA).to.equal(50000);
        expect((await opWiz.options(1)).premiumAmount).to.equal(1);
        expect((await opWiz.options(1)).amountOfColleteral).to.equal(1);
        expect((await opWiz.optionDetails(1)).counterAssetType).to.equal(0);
        expect((await opWiz.optionDetails(1)).premiumAssetType).to.equal(2);
        expect((await opWiz.optionDetails(1)).colleteralType).to.equal(1);
        await erc1155.connect(wallet).safeTransferFrom(wallet.address, acc1.address, 1, 1, ethers.constants.AddressZero);
        await expect(opWiz.connect(wallet).refundColleteral(1)).to.revertedWith("Offer not expired yet!");
        let  participateOptionInfo = abiCoder.encode(["uint8", "uint"], [2, 1]);
        /*
        console.log(participateOptionInfo);
        console.log(setOptionParamsInfo);
        */
        expect(await erc1155.connect(acc1).safeTransferFrom(acc1.address, opWiz.address, 1, 1, participateOptionInfo)).to.emit(opWiz, "Offer").withArgs(acc1.address, 1, true);
        expect((await opWiz.options(1)).participant).to.equal(acc1.address);
        expect(await erc721.balanceOf(opWiz.address)).to.equal(1);
        expect(await erc1155.balanceOf(opWiz.address, 1)).to.equal(1);
        expect(await erc1155.balanceOf(wallet.address, 1)).to.equal(4);
        expect(await opWiz.connect(wallet).withdrawPremium(1)).to.emit(opWiz, "WithdrawPremium").withArgs(wallet.address, 1, 1);
        expect(await erc1155.balanceOf(wallet.address, 1)).to.equal(5);
        await moveBlocks(1000);
        await expect(opWiz.connect(acc1).refundColleteral(1)).to.revertedWith("D2");
        await expect(opWiz.connect(wallet).refundColleteral(2)).to.revertedWith("Option does not exists.");
        await expect(opWiz.connect(wallet).refundColleteral(1)).to.revertedWith("D4");
        await moveBlocks(1000);
        expect(await  erc721.balanceOf(wallet.address)).to.equal(0);
        expect(await opWiz.connect(wallet).refundColleteral(1)).to.emit(opWiz, "WithdrawColleteral").withArgs(wallet.address, 1, 1);
        expect(await  erc721.balanceOf(wallet.address)).to.equal(1);
      });

      describe("Lists the option and buyer buys the option", function(){
        beforeEach(async function(){
          expect(await opWiz.offerOption(erc721.address, erc20_t2.address, erc1155.address, 1, 0 ,1)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, false);
          let setOptionParamsInfo = abiCoder.encode(["uint8", "uint", "uint", "uint", "uint", "uint"], [1, 1, 50000, 1, 2000, 1000]);
          expect(await erc721.connect(wallet)["safeTransferFrom(address,address,uint256,bytes)"](wallet.address, opWiz.address, 1, setOptionParamsInfo)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, true);
          expect(await erc721.balanceOf(opWiz.address)).to.equal(1);
          expect((await opWiz.options(1)).amountOfCA).to.equal(50000);
          expect((await opWiz.options(1)).premiumAmount).to.equal(1);
          expect((await opWiz.options(1)).amountOfColleteral).to.equal(1);
          expect((await opWiz.optionDetails(1)).counterAssetType).to.equal(0);
          expect((await opWiz.optionDetails(1)).premiumAssetType).to.equal(2);
          expect((await opWiz.optionDetails(1)).colleteralType).to.equal(1);
          await erc1155.connect(wallet).safeTransferFrom(wallet.address, acc1.address, 1, 1, ethers.constants.AddressZero);
          await expect(opWiz.connect(wallet).refundColleteral(1)).to.revertedWith("Offer not expired yet!");
          let  participateOptionInfo = abiCoder.encode(["uint8", "uint"], [2, 1]);
          expect(await erc1155.connect(acc1).safeTransferFrom(acc1.address, opWiz.address, 1, 1, participateOptionInfo)).to.emit(opWiz, "Offer").withArgs(acc1.address, 1, true);
          expect((await opWiz.options(1)).participant).to.equal(acc1.address);
        });
        
        it("lists&buys option in secondary market where list asset is erc721",async ()=>{
          await expect(erc721.mint(acc2.address, 2)).to.emit(erc721, 'Transfer').withArgs(ethers.constants.AddressZero, acc2.address, 2);
          await expect(opWiz.connect(wallet).listOption(1, erc721.address, 2, 1)).to.revertedWith("D3");
          expect(await opWiz.connect(acc1).listOption(1, erc721.address, 2, 1)).to.emit(opWiz, "Listed").withArgs(1, true);
          let buyParams = abiCoder.encode(["uint8", "uint"], [3, 1]);
          expect(await erc721.connect(acc2)["safeTransferFrom(address,address,uint256,bytes)"](acc2.address, opWiz.address, 2, buyParams)).to.emit(opWiz, "Transfer").withArgs(acc1.address, acc2.address, 1);
          expect((await opWiz.options(1)).participant).to.equal(acc2.address);
          expect(await erc721.balanceOf(opWiz.address)).to.equal(2);
          expect(await opWiz.connect(acc1).withdraw(erc721.address, 2, 1)).to.emit(opWiz, "Withdraw").withArgs(erc721.address, acc1.address, 1);
          await expect(opWiz.connect(acc2).delistOption(1)).to.revertedWith("D7");
          await expect(opWiz.connect(acc1).delistOption(1)).to.revertedWith("D3");
        });

        it("lists&buys option in secondary market where list asset is erc20",async ()=>{
          await expect(opWiz.connect(wallet).listOption(1, erc20_t1.address, 0, 15000)).to.revertedWith("D3");
          expect(await opWiz.connect(acc1).listOption(1, erc20_t1.address, 0, 15000)).to.emit(opWiz, "Listed").withArgs(1, true);
          await erc20_t1.connect(wallet).transfer(acc2.address, 15000);
          await erc20_t1.connect(acc2).approve(opWiz.address, 15000);
          expect(await opWiz.connect(acc2).buyOption(1)).to.emit(opWiz, "Transfer").withArgs(acc1.address,  acc2.address, 1);
          expect((await opWiz.options(1)).participant).to.equal(acc2.address);
          expect(await opWiz.connect(acc1).withdraw(erc20_t1.address, 0,  15000)).to.emit(opWiz, "Withdraw").withArgs(erc20_t1.address, acc1.address, 15000);
        });

        it("lists&buys option in secondary market where list asset is erc1155",async ()=>{
          await expect(opWiz.connect(wallet).listOption(1, erc1155.address, 1, 4)).to.revertedWith("D3");
          expect(await opWiz.connect(acc1).listOption(1, erc1155.address, 1, 4)).to.emit(opWiz, "Listed").withArgs(1, true);
          await erc1155.connect(wallet).safeTransferFrom(wallet.address, acc2.address, 1, 4, ethers.constants.AddressZero);
          let buyParams = abiCoder.encode(["uint8", "uint"], [3, 1]);
          await expect(erc1155.connect(acc2).safeTransferFrom(acc2.address, opWiz.address, 1, 3, buyParams)).to.revertedWith("D20");
          expect(await erc1155.connect(acc2).safeTransferFrom(acc2.address, opWiz.address, 1, 4, buyParams)).to.emit(opWiz, "Transfer").withArgs(acc1.address, acc2.address, 4);
          expect((await opWiz.options(1)).participant).to.equal(acc2.address);
          expect(await opWiz.connect(acc1).withdraw(erc1155.address, 1, 4)).to.emit(opWiz, "Withdraw").withArgs(erc20_t1.address, acc1.address, 4);
          expect(await erc1155.balanceOf(acc1.address, 1)).to.equal(4);
          expect(await erc1155.balanceOf(acc2.address, 1)).to.equal(0);
        });
      });
  });
});
