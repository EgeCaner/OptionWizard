// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IOpWizSimple.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";

contract OpWizSimple is IOpWizSimple { 
 using Counters for Counters.Counter;
    
    Counters.Counter private counter;

    mapping(uint => Option) public options;
    mapping(uint => OptionDetails) public optionDetails;
    mapping(address => mapping(address => uint)) public withdrawAllowance;

    modifier rejectZeroAddress(address addr) {
        require(addr != address(0), "Transaction to address(0)!");
        _;
    }

    modifier optionExists(uint optionId) {
        require(options[optionId].colleteral != address(0), "Option does not exists.");
        _;
    }

    modifier onlyParticipant(address from, uint optionId) {
        require(from == options[optionId].participant, "D3");
        _;
    }

    modifier onlyInitiator(address from, uint optionId) {
        require(from == options[optionId].initiator,  "D2");
        _;
    }

    modifier participated(uint optionId, bool check) {
        if (!check){
            require(options[optionId].participant == address(0), "D13");
        } else {
            require(options[optionId].participant != address(0), "D12");
        }
        _;
    }

    modifier offerPeriod(uint optionId, bool check) {
        require(optionDetails[optionId].offerEnd > 0, "Option paramaters not setted yet");
        if (check){
            require(optionDetails[optionId].offerEnd >= block.timestamp, "Offer expired");
        } else {
            require(optionDetails[optionId].offerEnd < block.timestamp, "Offer not expired yet!");
        }
        _;
    }

    modifier expired(uint optionId, bool check) {
        if (check){
            require(optionDetails[optionId].optionExpiry < block.timestamp, "D8");
        } else {
            require(optionDetails[optionId].optionExpiry >= block.timestamp, "D9");
        }
        _;
    }

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
        external
        override 
        rejectZeroAddress(colleteral)
        rejectZeroAddress(counterAsset)
        rejectZeroAddress(premiumAsset)
    {
        IERC20(colleteral).transferFrom(msg.sender, address(this), amountOfColleteral);
        counter.increment();
        uint index = counter.current();
        options[index].colleteral  = colleteral;
        Option storage option = options[index];
        option.counterAsset = counterAsset;
        option.premiumAsset = premiumAsset;
        option.amountOfColleteral = amountOfColleteral;
        option.premiumAmount = premiumAmount;
        option.amountOfCA = amountOfCA;
        optionDetails[index].offerEnd = block.timestamp + offerEnd;
        optionDetails[index].optionExpiry = block.timestamp + optionExpiry;
        option.initiator = msg.sender;
        emit Offer(msg.sender, index, true);
    }
    
    /**
    * @notice participate in option contract by paying the option premium
    * @dev transfers premium asset to contract, sets isParticipated to true and participator to msg.sender options mapping
    * @param optionId ID of the option
    */
    function participateOption(uint optionId)  external override {
        _participateOption(msg.sender, optionId);
        IERC20(options[optionId].premiumAsset).transferFrom(
            msg.sender, 
            address(this),
            options[optionId].premiumAmount
        );   
    }

    /**
    * @notice withdraw colleteral only if no ones participates in offer period or option expires worthless
    * @dev refund the colleteral only if option is not participated or option expires worthless
    * @param optionId ID of the option
    */
    function refundColleteral(uint optionId) 
        external
        override 
        onlyInitiator(msg.sender, optionId) 
        offerPeriod(optionId, false) 
    {
        require((options[optionId].participant == address(0) || 
        (optionDetails[optionId].optionExpiry < block.timestamp && 
        !optionDetails[optionId].exercised)), "D4");
        _transferColleteral(msg.sender, optionId);   
    }

    /**
    * @notice withdraw the option premium 
    * @dev transfers the premium asset if there is a participant in option contract only callable by the option initiator
    * @param optionId ID of the option
    */
    function withdrawPremium(uint optionId) 
        external 
        override 
        onlyInitiator(msg.sender, optionId) 
        participated(optionId, true)
    {
        require(options[optionId].premiumAmount > 0 , "D11");
        uint amount = options[optionId].premiumAmount;
        options[optionId].premiumAmount = 0;
        IERC20(options[optionId].premiumAsset).transfer(msg.sender, amount);
        emit WithdrawPremium(msg.sender, optionId, amount);
    }

    /**
    * @notice exercies the option
    * @dev transfers the counter assets to contract and transfers the colleteral to msg.sender only callable by the participator
    * @param optionId ID of the option
    */
    function exerciseOption(uint optionId) external override onlyParticipant(msg.sender, optionId){
        _exerciseOption(optionId);
        IERC20(options[optionId].counterAsset).transferFrom(
            msg.sender, 
            address(this), 
            options[optionId].amountOfCA
        );
    }

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
        external 
        override 
        onlyParticipant(msg.sender, optionId)
        expired(optionId, false)
        rejectZeroAddress(asset)
    {
        require(!optionDetails[optionId].exercised, "D7");
        optionDetails[optionId].isListed = true;
        optionDetails[optionId].listAsset = asset;
        optionDetails[optionId].listAmount = amount;
        emit Listed(optionId, true);
    }

    /**
    * @notice delists the option from secondary market
    * @dev sets listed field of option to false in option mapping, only callable by the participator
    * @param optionId ID of the option
    */
    function delistOption(uint optionId) external override {
        _delistOption(msg.sender, optionId);
    }

    /**
    * @notice transfers the counter asset to caller
    * @dev transfer the counter asset to initiator only if option is exercised
    * @param optionId ID of the option, receiver Address of buyer of the option  contract
    */
    function withdrawCA(uint optionId) external override onlyInitiator(msg.sender, optionId) {
        require(optionDetails[optionId].exercised, "D10");
        require(options[optionId].amountOfCA > 0, "D11");
        uint amount = options[optionId].amountOfCA;
        options[optionId].amountOfCA = 0;
        IERC20(options[optionId].counterAsset).transfer(msg.sender, amount);
        emit WithdrawCA(msg.sender, optionId, amount);
    }

    /**
    * @notice buy the option from secondary market
    * @dev change participator address to msg.sender and delist the option from secondary market
    * @param optionId ID of the option
    */
    function buyOption(uint optionId) external override {
         _buyOption(msg.sender ,optionId);
        IERC20(optionDetails[optionId].listAsset).transferFrom(
            msg.sender, 
            address(this), 
            optionDetails[optionId].listAmount
        );
    }

    /**
    * @notice withdraw the amount that seller of the option should receive
    * @dev transfer the token that option seller should receive
    * @param asset Address of the token to receive
    * @param amount Amount of thw token received
    */
    function withdraw(address asset, uint amount) external override {
        require(withdrawAllowance[asset][msg.sender] >= amount, "D15");
        withdrawAllowance[asset][msg.sender] -= amount;
        IERC20(asset).transfer(msg.sender, amount);
        emit Withdraw(asset, msg.sender, amount);
    } 

    function _participateOption(address participator,uint optionId) 
        internal      
        optionExists(optionId) 
        participated(optionId, false) 
        offerPeriod(optionId, true)  
    {
        options[optionId].participant = participator;
        optionDetails[optionId].offerEnd = block.timestamp;
        emit Participate(participator, optionId);
    } 

    function _transferColleteral(address to, uint optionId) internal {
        uint amount = options[optionId].amountOfColleteral;
        options[optionId].amountOfColleteral = 0;
        IERC20(options[optionId].colleteral).transfer(to, amount);
        emit WithdrawColleteral(to, optionId, amount);
    }

     function _exerciseOption(uint optionId) 
        internal 
        expired(optionId, false)
    {
        address to = options[optionId].participant;
        require(!optionDetails[optionId].exercised, "D7");
        optionDetails[optionId].exercised = true;
        _transferColleteral(to ,optionId);
        emit Exercise(to, optionId);
    }

    function _buyOption(address to, uint optionId) 
        internal 
        optionExists(optionId) 
        expired(optionId, false)
    {
        require(optionDetails[optionId].isListed, "D14");
        withdrawAllowance[optionDetails[optionId].listAsset][options[optionId].participant] += optionDetails[optionId].listAmount;
        emit Transfer(options[optionId].participant, to, optionId);
        options[optionId].participant = to;
        _delistOption(to ,optionId);
    }

    function _delistOption(address participant, uint optionId) 
        internal
        onlyParticipant(participant, optionId) 
    {
        require(optionDetails[optionId].isListed, "D7");
        optionDetails[optionId].isListed = false;
        emit Listed(optionId, false);
    }    
}