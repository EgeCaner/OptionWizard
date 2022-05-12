import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract, Event, Wallet } from "ethers";
import { ethers } from "hardhat";
import { it } from "mocha";
import { OpWiz } from "../typechain/OpWiz";
import { SimpleERC721 } from "../typechain/SimpleERC721";
import { SimpleERC1155 } from "../typechain/SimpleERC1155";


const stringToBytes = (str: string): number[] => {
    return str.split('').map((x) => x.charCodeAt(0));
  };

function stringToBytesUTF8(str: string): number[] {
    return stringToBytes(encodeURIComponent(str));
  }
 
describe("onERC721Received & onERC1155Received hooks", function () {

    let wallet:Wallet, other:Wallet , erc721: SimpleERC721, erc1155: SimpleERC1155 ,receiver: OpWiz;

    beforeEach(async function (){

       ;[wallet, other]= await (ethers as any).getSigners();
       const ERC721 = await ethers.getContractFactory("SimpleERC721");
       erc721 = (await ERC721.deploy("test","TST")) as SimpleERC721;
       await erc721.deployed();
       const ERC1155 = await ethers.getContractFactory("SimpleERC1155");
       erc1155 = (await ERC1155.deploy("test")) as SimpleERC1155;
       await erc1155.deployed();
       const Receiver = await ethers.getContractFactory("OpWiz");
       receiver = (await Receiver.deploy())  as OpWiz;
       await receiver.deployed();
    });

    describe("Mint and transfer ERC721 to SC with receiverHook", function (){
        it("Should mint nft & Should recieve from hook",  async () =>{
            await expect(erc721.mint(wallet.address, 1)).to.emit(erc721, 'Transfer').withArgs(ethers.constants.AddressZero, wallet.address, 1);
            let tx =  await erc721["safeTransferFrom(address,address,uint256)"](wallet.address, receiver.address, 1);
            (await tx).wait(1);
            expect(await erc721.balanceOf(receiver.address)).to.equal(1);
        });
    });

    describe("Mint and transfer ERC1155 to SC with receiverHook", function (){
        it("Should mint nft & Should recieve from hook",  async () =>{
            await expect(erc1155.mint(wallet.address, 1, 5)).to.emit(erc1155, "TransferSingle").withArgs(wallet.address, ethers.constants.AddressZero, wallet.address, 1, 5);
            let tx = await erc1155.safeTransferFrom(wallet.address, receiver.address, 1, 3, stringToBytesUTF8("Exercise"));
            (await tx).wait(1);
            expect(await erc1155.balanceOf(receiver.address, 1)).to.equal(3);
        });
    });
});
