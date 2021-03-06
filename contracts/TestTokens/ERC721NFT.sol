// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract SimpleERC721 is ERC721{

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_){
        
    }

    function mint(address to, uint  tokenId) external{
        _safeMint(to, tokenId);
    }
}