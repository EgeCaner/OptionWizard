// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;


import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "./IOpWizSimple.sol";

/**
* @title Interface of the OptionWizard contract
* @author Ege Caner
 */
interface IOpWizChainlinkCompatible is IOpWizSimple, KeeperCompatibleInterface {
   
    function setPriceFeedAddress(uint optionId, address _priceFeedAddress) external;

}