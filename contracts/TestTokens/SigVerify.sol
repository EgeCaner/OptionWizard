// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import  "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SigVerify {
    using ECDSA for bytes;
    using ECDSA for bytes32;

    function verify(bytes memory message, bytes memory sig) public view returns(address){
        return message.toEthSignedMessageHash().recover(sig);
    }
}

