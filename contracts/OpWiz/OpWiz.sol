// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "hardhat/console.sol";

contract OpWiz is IERC1155Receiver, IERC721Receiver{

    function supportsInterface(bytes4 interfaceID) external virtual override view returns (bool) {
        return
          interfaceID == this.supportsInterface.selector || // ERC165
          interfaceID == this.onERC721Received.selector
                         ^ this.onERC1155Received.selector 
                         ^ this.onERC1155BatchReceived.selector; // Simpson
    }

    function onERC721Received(
            address operator,
            address from,
            uint256 tokenId,
            bytes calldata data
        ) external virtual override returns (bytes4){
            console.log("receivedERC721");
            return this.onERC721Received.selector;
        }
    
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external virtual override returns (bytes4){
        console.log("receivedERC1155");
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external virtual override returns (bytes4){
        console.log("batchReceivedERC1155");
        return this.onERC1155BatchReceived.selector;
    }
}