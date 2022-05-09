// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract SimpleERC1155 is ERC1155{

    constructor(string memory _uri) ERC1155(_uri){}

    function mint(address to, uint256  id, uint256 amount) external{
        _mint(to, id, amount, "");
    }
}