// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "../OpWizSimple.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../interfaces/IOpWizChainlinkCompatible.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "hardhat/console.sol";

contract OpWizChainlinkCompatible is IERC165, OpWizSimple, IOpWizChainlinkCompatible { 
    using ECDSA for bytes;
    using ECDSA for bytes32;

    function setPriceFeedAddress(uint optionId, address _priceFeedAddress) external override onlyParticipant(msg.sender, optionId){
        optionDetails[optionId].priceFeedAddress = _priceFeedAddress;
    }

    /**
    * @notice method that is simulated by the keepers to see if any work actually
    * needs to be performed. This method does does not actually need to be
    * executable, and since it is only ever simulated it can consume lots of gas.
    * @dev To ensure that it is never called, you may want to add the
    * cannotExecute modifier from KeeperBase to your implementation of this
    * method.
    * @param checkData specified in the upkeep registration so it is always the
    * same for a registered upkeep. This can easily be broken down into specific
    * arguments using `abi.decode`, so multiple upkeeps can be registered on the
    * same contract and easily differentiated by the contract.
    * @return upkeepNeeded boolean to indicate whether the keeper should call
    * performUpkeep or not.
    * @return performData bytes that the keeper should call performUpkeep with, if
    * upkeep is needed. If you would like to encode data to decode later, try
    * `abi.encode`.
    */
    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData){
        console.log("entering encoding");
        (
            uint optionId,
            int strikePrice,
            bytes memory sig
        ) = abi.decode(checkData,(uint, int, bytes)); 
        console.log("out encoding");
        console.log("entering kecccak");
        bytes32 hash_ = keccak256(abi.encode(optionId, strikePrice));
        address signer = hash_.toEthSignedMessageHash().recover(sig);
        console.log("out keccak");
        console.log(signer);

        //require(options[optionId].participant == ECDSA.recover(hash_, signature), "Params does not provided by option participator");
        console.log("sigVerifies");
        (    /*uint80 roundID*/,
            int price, 
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        )= AggregatorV3Interface(optionDetails[optionId].priceFeedAddress).latestRoundData();

        return (price >= strikePrice , checkData);
    }

    /**
    * @notice method that is actually executed by the keepers, via the registry.
    * The data returned by the checkUpkeep simulation will be passed into
    * this method to actually be executed.
    * @dev The input to this method should not be trusted, and the caller of the
    * method should not even be restricted to any single registry. Anyone should
    * be able call it, and the input should be validated, there is no guarantee
    * that the data passed in is the performData returned from checkUpkeep. This
    * could happen due to malicious keepers, racing keepers, or simply a state
    * change while the performUpkeep transaction is waiting for confirmation.
    * Always validate the data passed in.
    * @param performData is the data which was passed back from the checkData
    * simulation. If it is encoded, it can easily be decoded into other types by
    * calling `abi.decode`. This data should not be trusted, and should be
    * validated against the contract's current state.
    */
    function performUpkeep(bytes calldata performData) external override {
        (
            uint optionId,
            int strikePrice,
            bytes memory signature
        ) = abi.decode(performData, (uint, int, bytes)); 

        (    /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        )= AggregatorV3Interface(optionDetails[optionId].priceFeedAddress).latestRoundData();
        
        require(price > strikePrice, "Option is OTM");
        _exerciseOption(optionId);
        IERC20(options[optionId].counterAsset).transferFrom(
            options[optionId].participant, 
            address(this), 
            options[optionId].amountOfCA
        );
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        return interfaceId == this.supportsInterface.selector || 
               interfaceId == this.checkUpkeep.selector ^ this.performUpkeep.selector;

    }

    function verify(bytes memory message, bytes memory sig) external pure returns(address signer){
        signer= message.toEthSignedMessageHash().recover(sig);
    }

}