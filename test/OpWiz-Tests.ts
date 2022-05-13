import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract, Event, Wallet } from "ethers";
import { ethers } from "hardhat";
import { it } from "mocha";
import { OpWiz } from "../typechain/OpWiz";
import { SimpleERC721 } from "../typechain/SimpleERC721";
import { SimpleERC1155 } from "../typechain/SimpleERC1155";
import  { SimpleERC20 } from "../typechain/SimpleERC20";
import { ECDH } from "crypto";

const stringToBytes = (str: string): number[] => {
    return str.split('').map((x) => x.charCodeAt(0));
  };

function stringToBytesUTF8(str: string): number[] {
    return stringToBytes(encodeURIComponent(str));
  }
 
describe("onERC721Received & onERC1155Received hooks", function () {

    let wallet:Wallet, other:Wallet, erc20_t1:SimpleERC20, erc20_t2:SimpleERC20, erc721: SimpleERC721, erc1155: SimpleERC1155 , opWiz: OpWiz;

    beforeEach(async function (){

       [wallet, other]= await (ethers as any).getSigners();
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
       console.log(`Address of owner: ${wallet.address}\nAddress of other: ${other.address}\nAddress of ERC20-1: ${erc20_t1.address}\nAddress of ERC20-2: ${erc20_t2.address}\nAddress of ERC721: ${erc721.address}\nAddress of ERC1155: ${erc1155.address}\nAddress of OpWiz: ${opWiz.address}`)
    });

    describe ("OfferOption", function() {
        it("OfferOption ERC20 to ERC20 with ERC20 premium", async () => {
          expect( await opWiz.offerOption(erc20_t1.address, erc20_t2.address, erc20_t1.address, 0, 0 ,0)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, false);
          let tx = await erc20_t1.approve(opWiz.address, 50000);
          await tx.wait(1);
          expect ( await opWiz.setOptionParams(1, 50000, 30000, 3000, 1000, 100)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, true);
        });
    });

    describe ("Paricipate in offered option", function() {
      beforeEach(async function () {
        expect( await opWiz.offerOption(erc20_t1.address, erc20_t2.address, erc20_t1.address, 0, 0 ,0)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, false);
        let tx = await erc20_t1.approve(opWiz.address, 50000);
        await tx.wait(1);
        expect ( await opWiz.setOptionParams(1, 50000, 30000, 3000, 1000, 100)).to.emit(opWiz, "Offer").withArgs(wallet.address, 1, true);
        tx = await erc20_t2.connect(wallet).transfer(other.address, 500000);
        await tx.wait(1);
        tx = await erc20_t1.connect(wallet).transfer(other.address, 500000);
        await tx.wait(1);
        expect(await erc20_t1.balanceOf(other.address)).to.equal(500000);
        expect(await erc20_t2.balanceOf(other.address)).to.equal(500000);
      }); 
  
      it("Participates in ERC20 to ERC20 with ERC20 premium", async () => {
        erc20_t1.connect(other).approve(opWiz.address, 3000);
        expect(await opWiz.connect(other).participateOption(1)).to.emit(opWiz, "Participate").withArgs(other.address, 1);
        let optionInfo  = await opWiz.options(1);
        let optionDetailsInfo = await opWiz.optionDetails(1);
        console.log("#".repeat(10));
        console.log(optionInfo);
        console.log("#".repeat(10));
        console.log(optionDetailsInfo);
        expect(optionInfo.participant).to.equal(other.address);
        expect((await opWiz.options(1)).amountOfColleteral).to.equal(50000);
        expect(await erc20_t1.balanceOf(opWiz.address)).to.equal(53000);
        //withdraw premium
        expect(await opWiz.connect(wallet).withdrawPremium(1)).to.emit(opWiz, "WithdrawPremium").withArgs(wallet.address, 1, 3000);
        expect(await erc20_t1.balanceOf(wallet.address)).to.equal(453000);
      });
  });
});
