// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "contracts/OpWiz/IOpWizChainlinkCompatible.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract OpWizChainlinkCompatible is IOpWizChainlinkCompatible {
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
    * @dev if asset type is not ERC20 handle this functionality with receive hooks using calldata
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
    function delistOption(uint optionId) external override {}

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
    * @dev If asset type is  not ERC20 revert and handle this functionality using receive hooks
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

    function SetPriceFeedAddress(uint optionId, address _priceFeedAddress) external override onlyParticipant(msg.sender, optionId){
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
    function checkUpkeep(bytes calldata checkData) external override returns (bool upkeepNeeded, bytes memory performData){
        (uint optionId, int strikePrice) = abi.decode(checkData,(uint, int)); 
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
        (uint optionId, int strikePrice) = abi.decode(performData, (uint, int)); 
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