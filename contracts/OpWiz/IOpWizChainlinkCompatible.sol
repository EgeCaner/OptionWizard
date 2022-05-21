// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

/**
* @title Interface of the OptionWizard contract
* @author Ege Caner
 */
interface IOpWizChainlinkCompatible is IERC165, KeeperCompatibleInterface {

    struct Option { 
        address initiator;
        address participant;
        address colleteral;
        address counterAsset;
        address premiumAsset;
        uint amountOfColleteral;
        uint amountOfCA;
        uint premiumAmount; 
    }

    struct OptionDetails {
        address listAsset;
        uint offerEnd;
        uint optionExpiry;
        uint listAmount;
        bool isListed;
        bool exercised;
        address priceFeedAddress;
    }

    event Offer(
       address indexed initiator,
       uint indexed optionId,
       bool setted
    );
    
    event Participate(
        address indexed participator,
        uint indexed optionId
    );

    event Exercise(
        address indexed participator,
        uint indexed optionId
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint indexed optionId
    );

    event Listed(
        uint optionId,
        bool isListed
    );

    event WithdrawCA(
        address to,
        uint optionId,
        uint amount
    );

    event WithdrawPremium(
        address to,
        uint optionId,
        uint amount
    );

    event WithdrawColleteral(
        address to,
        uint optionId,
        uint amount
    );

    event Withdraw(
        address asset,
        address to,
        uint amount
    );

    /**
    * @notice publish an offer for the option contract
    * @dev locks the colleteral, save the OptionSpecs to mapping with optionId and emits OfferEvent
    * @param colleteral Address of colleteral asset, counterAsset Address of counter asset, 
    * @param premiumAsset Address of premium asset, amountOfColleteral Amount of colleteral to be locked and promised
    */
    function offerOption(
        address colleteral,
        address counterAsset,
        address premiumAsset,
        uint amountOfColleteral,
        uint amountOfCA, 
        uint premiumAmount, 
        uint optionExpiry, 
        uint offerEnd
    ) 
        external;
    
    /**
    * @notice participate in option contract by paying the option premium
    * @dev transfers premium asset to contract, sets isParticipated to true and participator to msg.sender options mapping
    * @param optionId ID of the option
    */
    function participateOption(uint optionId)  external;

    /**
    * @notice withdraw colleteral only if no ones participates in offer period or option expires worthless
    * @dev refund the colleteral only if option is not participated or option expires worthless
    * @param optionId ID of the option
    */
    function refundColleteral(uint optionId) external;

    /**
    * @notice withdraw the option premium 
    * @dev transfers the premium asset if there is a participant in option contract only callable by the option initiator
    * @param optionId ID of the option
    */
    function withdrawPremium(uint optionId) external;

    /**
    * @notice exercies the option
    * @dev transfers the counter assets to contract and transfers the colleteral to msg.sender only callable by the participator
    * @dev if asset type is not ERC20 handle this functionality with receive hooks using calldata
    * @param optionId ID of the option
    */
    function exerciseOption(uint optionId) external;

    /**
    * @notice list the option in secondary market
    * @dev sets listed field of option to true, asset address and amount in option mapping
    * @param optionId ID of the option, asset Address of the asset that seller wants to receive, amount Amount of asset
    */
    function listOption(
        uint optionId, 
        address asset,
        uint amount
    ) 
        external;

    /**
    * @notice delists the option from secondary market
    * @dev sets listed field of option to false in option mapping, only callable by the participator
    * @param optionId ID of the option
    */
    function delistOption(uint optionId) external;

    /**
    * @notice transfers the counter asset to caller
    * @dev transfer the counter asset to initiator only if option is exercised
    * @param optionId ID of the option, receiver Address of buyer of the option  contract
    */
    function withdrawCA(uint optionId) external;

    /**
    * @notice buy the option from secondary market
    * @dev change participator address to msg.sender and delist the option from secondary market
    * @dev If asset type is  not ERC20 revert and handle this functionality using receive hooks
    * @param optionId ID of the option
    */
    function buyOption(uint optionId) external;

    /**
    * @notice withdraw the amount that seller of the option should receive
    * @dev transfer the token that option seller should receive
    * @param asset Address of the token to receive
    * @param amount Amount of thw token received
    */
    function withdraw(
        address asset,
        uint amount
    ) external;

    function SetPriceFeedAddress(uint optionId, address _priceFeedAddress) external;

}