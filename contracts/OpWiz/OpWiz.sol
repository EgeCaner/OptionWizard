// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "contracts/OpWiz/IOpwiz.sol";
import "hardhat/console.sol";

/*
* D1 = Asset type is not ERC20 directly transfer asset to this contract with related calldata params
*/

contract OpWiz is ERC165, IERC1155Receiver, IERC721Receiver, IOpWiz{
    
    using Counters for Counters.Counter;
    using Address for address;

    Counters.Counter counter;

    bytes4 public immutable  ERC721_INTERFACE_ID = 0x80ac58cd;

    bytes4 public immutable  ERC1155_INTERFACE_ID = 0xd9b67a26;

    mapping (uint => OptionDetails) public options;

    modifier RejectZeroAddress(address addr) {
        require(addr != address(0), "Transaction to address(0)!");
        _;
    }

    modifier OptionExists(uint optionID) {
        require(options[optionID].colleteral != address(0), "Option does not exists.");
        _;
    }

    modifier OnlyParticipant(uint optionID) {
        require(msg.sender == options[optionID].participant, "Only participant of the option is allowed");
        _;
    }

    modifier OnlyInitiator(uint optionID) {
        require(msg.sender == options[optionID].initiator,  "Only initiator of the option is allowed");
        _;
    }

    modifier Participated(uint optionID, bool check) {
        if (!check){
            require(options[optionID].participant == address(0), "Already participated");
        } else {
            require(options[optionID].participant != address(0), "Not participated yet!");
        }
        _;
    }

    modifier OfferPeriod(uint optionId, bool check) {
        if (check){
            require(options[optionId].offerEnd >= block.timestamp, "Offer expired");
        } else {
            require(options[optionId].offerEnd < block.timestamp, "Offer not expired yet!");
        }
        _;
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override(ERC165, IERC165) returns (bool) {
        return
          interfaceID == this.supportsInterface.selector ||
          interfaceID == this.onERC721Received.selector
                         ^ this.onERC1155Received.selector 
                         ^ this.onERC1155BatchReceived.selector;
    }

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
        external 
        RejectZeroAddress(colleteral)
        RejectZeroAddress(counterAsset)
        RejectZeroAddress(premiumAsset)
        {
            require(_determineERCStandart(colleteral) != AssetTypes.ERC20, "This function should only called if colleteral is ERC20 token");
            IERC20(colleteral).transferFrom(msg.sender, address(this), amountOfColleteral);
            counter.increment();
            options[counter.current()].initiator = msg.sender;
            options[counter.current()].colleteral  = colleteral;
            options[counter.current()].counterAsset = counterAsset;
            options[counter.current()].premiumAsset = premiumAsset;
            options[counter.current()].counterAsset = counterAsset;
            options[counter.current()].indexOfCounter = indexOfCA;
            options[counter.current()].indexOfPremium = indexOfPremium;
            options[counter.current()].amountOfColleteral = amountOfColleteral;
            options[counter.current()].amountOfCA = amountOfCA;
            options[counter.current()].premiumAmount = premiumAmount;
            options[counter.current()].optionExpiry = block.timestamp + optionExpiry;
            options[counter.current()].offerEnd = block.timestamp + offerEnd;
            options[counter.current()].colleteralType = AssetTypes.ERC20;
            options[counter.current()].counterAssetType = _determineERCStandart(counterAsset);
            options[counter.current()].premiumAssetType = _determineERCStandart(premiumAsset);
            emit Offer(msg.sender, counter.current());
        }
    
    /**
    * @notice participate in option contract by paying the option premium
    * @dev transfers premium asset to contract, sets isParticipated to true and participator to msg.sender options mapping
    * @param optionID ID of the option
    */
    function participateOption(uint optionID)  external OptionExists(optionID) Participated(optionID, false) OfferPeriod(optionID, true) {
        require(options[optionID].counterAssetType == AssetTypes.ERC20, "D1");
        IERC20(options[optionID].counterAsset).transferFrom(msg.sender, address(this), options[optionID].premiumAmount);
        _participateOption(optionID);
    }

    /**
    * @notice withdraw colleteral only if no ones participates in offer period or option expires worthless
    * @dev refund the colleteral only if option is not participated or option expires worthless
    * @param optionID ID of the option
    */
    function refundColleteral(uint optionID) 
        external 
        OptionExists(optionID) 
        OnlyInitiator(optionID) 
        OfferPeriod(optionID, false) {
        require(options[optionID].participant == address(0) || 
        (options[optionID].optionExpiry < block.timestamp && 
        options[optionID].exercised), "Colleteral cannot be withdraw conditions not met");
        uint amount = options[optionID].amountOfColleteral;
        options[optionID].amountOfColleteral = 0;
        if (options[optionID].colleteralType == AssetTypes.ERC20) {
            IERC20(options[optionID].colleteral).transfer(msg.sender, amount);
        } else if(options[optionID].colleteralType == AssetTypes.ERC721) {
            IERC721(options[optionID].colleteral).safeTransferFrom(address(this), msg.sender, options[optionID].indexOfColleteral);
        } else if(options[optionID].colleteralType == AssetTypes.ERC1155){
            IERC1155(options[optionID].colleteral).safeTransferFrom(
                address(this), 
                msg.sender, 
                options[optionID].indexOfColleteral, 
                options[optionID].amountOfColleteral,
                bytes("")
                );
        } else {
            revert("Asset type does not match any standart");
        }
    }

    /**
    * @notice withdraw the option premium 
    * @dev transfers the premium asset if there is a participant in option contract only callable by the option initiator
    * @param optionID ID of the option
    */
    function withdrawPremium(uint optionID) external OptionExists(optionID) OnlyInitiator(optionID) Participated(optionID, true){
        require(options[optionID].premiumAmount > 0 , "no premium to withdraw");
        uint amount = options[optionID].premiumAmount;
        options[optionID].premiumAmount = 0;
        if (options[optionID].premiumAssetType == AssetTypes.ERC20) {
            IERC20(options[optionID].premiumAsset).transfer(msg.sender, amount);
        } else if(options[optionID].premiumAssetType == AssetTypes.ERC721) {
            IERC721(options[optionID].premiumAsset).safeTransferFrom(address(this), msg.sender, options[optionID].indexOfPremium);
        } else if(options[optionID].premiumAssetType == AssetTypes.ERC1155){
            IERC1155(options[optionID].premiumAsset).safeTransferFrom(
                address(this), 
                msg.sender, 
                options[optionID].indexOfPremium, 
                amount,
                bytes("")
                );
        } else {
            revert("Asset type does not match any standart");
        }

    }

    function exerciseOption(uint optionID) external OptionExists(optionID) OnlyParticipant(optionID) {}

    function listOption(uint optionID, address asset, uint amount, AssetTypes assetType) external OptionExists(optionID) OnlyParticipant(optionID) {}

    function delistOption(uint optionID) external OptionExists(optionID) OnlyParticipant(optionID) {}

    function withdrawCA(uint optionID) external OptionExists(optionID) OnlyInitiator(optionID)  {}

    function buyOption(uint optionID) external OptionExists(optionID) {}


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
        console.log(string(data));
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

    function _isSupportsInterface(address addr, bytes4 interfaceId) internal returns (bool) {
        if (addr.isContract()){
            try IERC165(addr).supportsInterface(interfaceId) returns (bool retval) {
                return retval;
            } catch (bytes memory reason) {
                return false;
                }
        } else {
            return false;
        }
    }

    function _determineERCStandart(address addr) internal returns (AssetTypes){
        if (addr.isContract()){
            if(_isSupportsInterface(addr, ERC1155_INTERFACE_ID)){
                return AssetTypes.ERC1155;
            } else if (_isSupportsInterface(addr, ERC721_INTERFACE_ID)){
                return AssetTypes.ERC721;
            } else {
                return AssetTypes.ERC20;
            }
        } else {
            revert("Address is not a contract");
        }
    }

    function _participateOption(uint optionID) private {
        options[optionID].participant == msg.sender;
        options[optionID].offerEnd = block.timestamp;
        emit Participate(msg.sender, optionID);
    } 
}