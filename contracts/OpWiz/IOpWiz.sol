// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
* @title Interface of the OptionWizard contract
* @author Ege Caner
 */
interface IOpWiz is IERC165, IERC1155Receiver, IERC721Receiver{
    
    enum AssetTypes { ERC20, ERC721, ERC1155 }

    struct OptionDetails{
        address colleteral;
        address counterAsset;
        address premiumAsset; 
        address listAsset;
        address initiator;
        address participant;
        uint indexOfColleteral;
        uint indexOfCounter;
        uint indexOfPremium;
        uint indexOfListAsset;
        uint amountOfColleteral;
        uint amountOfCA;
        uint premiumAmount; 
        uint offerEnd;
        uint optionExpiry;
        uint listAmount;
        bool isListed;
        bool exercised;
        AssetTypes colleteralType;
        AssetTypes counterAssetType;
        AssetTypes listAssetType;
        AssetTypes premiumAssetType;
    }

    event Offer(
       address indexed initiator,
       uint indexed optionID
    );

    event Participate(
        address indexed participator,
        uint indexed optionID
    );

    event Exercise(
        address indexed participator,
        uint indexed optionID
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint indexed optionID
    );

    event List(
        uint optionID,
        bool isListed
    );

    event WithdrawCA(
        address to,
        uint optionID,
        uint amount
    );

    event WithdrawPremium(
        address to,
        uint optionID,
        uint amount
    );

    event WithdrawColleteral(
        address to,
        uint optionID,
        uint amount
    );

    /**
    * @notice publish an offer for the option contract
    * @dev locks the colleteral, save the OptionSpecs to mapping with optionId and emits OfferEvent
    * @param colleteral Address of colleteral asset, counterAsset Address of counter asset, 
    * @param premiumAsset Address of premium asset, amountOfColleteral Amount of colleteral to be locked and promised,
    * @param amountOfCA Amount of counter asset that initiator is willing to receive,
    * @param premiumAmount Amount of asset that option seller wants to receive as premium
    * @param offerEnd Block timestamp where validity of the offer expires
    * @param optionExpiry Block timestamp where option expires
    */
    function offerOption(
        address colleteral,
        address counterAsset,
        address premiumAsset, 
        uint amountOfColleteral,
        uint indexOfCA, 
        uint amountOfCA,
        uint indexOfPremium, 
        uint premiumAmount, 
        uint offerEnd,
        uint optionExpiry
        ) 
        external;
    
    /**
    * @notice participate in option contract by paying the option premium
    * @dev transfers premium asset to contract, sets isParticipated to true and participator to msg.sender options mapping
    * @param optionID ID of the option
    */
    function participateOption(uint optionID)  external;

    /**
    * @notice withdraw colleteral only if no ones participates in offer period or option expires worthless
    * @dev refund the colleteral only if option is not participated or option expires worthless
    * @param optionID ID of the option
    */
    function refundColleteral(uint optionID) external;

    /**
    * @notice withdraw the option premium 
    * @dev transfers the premium asset if there is a participant in option contract only callable by the option initiator
    * @param optionID ID of the option
    */
    function withdrawPremium(uint optionID) external;

    /**
    * @notice exercies the option
    * @dev transfers the counter assets to contract and transfers the colleteral to msg.sender only callable by the participator
    * @dev if asset type is not ERC20 handle this functionality with receive hooks using calldata
    * @param optionID ID of the option
    */
    function exerciseOption(uint optionID) external;

    /**
    * @notice list the option in secondary market
    * @dev sets listed field of option to true, asset address and amount in option mapping
    * @param optionID ID of the option, asset Address of the asset that seller wants to receive, amount Amount of asset
    */
    function listOption(uint optionID, address asset, uint amount, AssetTypes assetType) external;

    /**
    * @notice delists the option from secondary market
    * @dev sets listed field of option to false in option mapping, only callable by the participator
    * @param optionID ID of the option
    */
    function delistOption(uint optionID) external;

    /**
    * @notice transfers the counter asset to caller
    * @dev transfer the counter asset to initiator only if option is exercised
    * @param optionID ID of the option, receiver Address of buyer of the option  contract
    */
    function withdrawCA(uint optionID) external;

    /**
    * @notice buy the option from secondary market
    * @dev change participator address to msg.sender and delist the option from secondary market
    * @dev If asset type is  not ERC20 revert and handle this functionality using receive hooks
    * @param optionID ID of the option
    */
    function buyOption(uint optionID) external;

}