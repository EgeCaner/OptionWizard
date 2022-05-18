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
import "contracts/OpWiz/IOpWiz.sol";
import "hardhat/console.sol";

/*
* D1 : Asset type is not ERC20 directly transfer asset to this contract with related calldata params
* D2 : Only initiator of the option is allowed
* D3 : Only participant of the option is allowed
* D4 : Colleteral cannot be withdraw conditions not met
* D5 : Asset type does not match any standart
* D6 : Colleteral asset type is not ERC20
* D7 : Option already exercised
* D8 : Option not expired
* D9 : Option already expired
* D10 : Option not exercised
* D11 : Nothing to withdraw 
* D12 : Not participated yet!
* D13 : Already participated
* D14 : Option is not listed
* D15 : Amount exceeds withdraw allowance
* D16 : Option params already setted
* D19 : Asset does not match
* D20 : Insufficient funds
* D21 : Invalid mode has been selected
* D22 : Index of the asset does not match
* D23 : This contract does not support ERC1155 batch receive
*/

contract OpWiz is ERC165, IERC1155Receiver, IERC721Receiver, IOpWiz{
    
    using Counters for Counters.Counter;
    using Address for address;

    Counters.Counter public counter;

    bytes4 public immutable  ERC721_INTERFACE_ID = 0x80ac58cd;

    bytes4 public immutable  ERC1155_INTERFACE_ID = 0xd9b67a26;

    mapping (uint => Option) public options;

    mapping (uint => OptionDetails) public optionDetails;

    mapping (address => mapping (address => uint)) withdrawAllowance;


    modifier RejectZeroAddress(address addr) {
        require(addr != address(0), "Transaction to address(0)!");
        _;
    }

    modifier OptionExists(uint optionId) {
        require(options[optionId].colleteral != address(0), "Option does not exists.");
        _;
    }

    modifier OnlyParticipant(address from, uint optionId) {
        require(from == options[optionId].participant, "D3");
        _;
    }

    modifier OnlyInitiator(address from, uint optionId) {
        require(from == options[optionId].initiator,  "D2");
        _;
    }

    modifier Participated(uint optionId, bool check) {
        if (!check){
            require(options[optionId].participant == address(0), "D13");
        } else {
            require(options[optionId].participant != address(0), "D12");
        }
        _;
    }

    modifier OfferPeriod(uint optionId, bool check) {
        require(optionDetails[optionId].offerEnd > 0, "Option paramaters not setted yet");
        if (check){
            require(optionDetails[optionId].offerEnd >= block.timestamp, "Offer expired");
        } else {
            require(optionDetails[optionId].offerEnd < block.timestamp, "Offer not expired yet!");
        }
        _;
    }

    modifier Expired(uint optionId, bool check) {
        if (check){
            require(optionDetails[optionId].optionExpiry < block.timestamp, "D8");
        } else {
            require(optionDetails[optionId].optionExpiry >= block.timestamp, "D9");
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

    function offerOption(
        address colleteral,
        address counterAsset,
        address premiumAsset,
        uint indexOfColleteral, 
        uint indexOfCA, 
        uint indexOfPremium
        ) 
        external 
        override
        RejectZeroAddress(colleteral)
        RejectZeroAddress(counterAsset)
        RejectZeroAddress(premiumAsset)
        {
            counter.increment();
            uint index = counter.current();
            options[index].colleteral  = colleteral;
            Option storage option = options[index];
            OptionDetails storage optionDetail = optionDetails[index];
            option.counterAsset = counterAsset;
            option.premiumAsset = premiumAsset;
            option.indexOfColleteral = indexOfColleteral;
            option.indexOfCounter = indexOfCA;
            option.indexOfPremium = indexOfPremium;
            option.initiator = msg.sender;
            optionDetail.colleteralType = _determineERCStandart(colleteral);
            optionDetail.counterAssetType = _determineERCStandart(counterAsset);
            optionDetail.premiumAssetType = _determineERCStandart(premiumAsset);
            emit Offer(msg.sender, index, false);
        }
    
    function setOptionParams(
        uint optionId,
        uint amountOfColleteral,
        uint amountOfCA, 
        uint premiumAmount, 
        uint optionExpiry, 
        uint offerEnd) 
        external
    {   
        require(optionDetails[optionId].colleteralType == uint(AssetTypes.ERC20), "D6");
        IERC20(options[optionId].colleteral).transferFrom(msg.sender, address(this), amountOfColleteral);
        _setOptionParams(msg.sender, optionId, amountOfColleteral, amountOfCA, premiumAmount, optionExpiry, offerEnd);
        
    }

    function participateOption(uint optionId) 
        external 
        override
    {
        require(optionDetails[optionId].premiumAssetType == uint(AssetTypes.ERC20), "D1");
        IERC20(options[optionId].premiumAsset).transferFrom(msg.sender, address(this), options[optionId].premiumAmount);
        _participateOption(msg.sender, optionId);
    }

    function refundColleteral(uint optionId) 
        external 
        override
        OptionExists(optionId) 
        OnlyInitiator(msg.sender, optionId) 
        OfferPeriod(optionId, false) 
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
        OptionExists(optionId) 
        OnlyInitiator(msg.sender, optionId) 
        Participated(optionId, true)
    {
        require(options[optionId].premiumAmount > 0 , "D11");
        uint amount = options[optionId].premiumAmount;
        options[optionId].premiumAmount = 0;
        if (optionDetails[optionId].premiumAssetType == uint(AssetTypes.ERC20)) {
            IERC20(options[optionId].premiumAsset).transfer(msg.sender, amount);
        } else if(optionDetails[optionId].premiumAssetType == uint(AssetTypes.ERC721)) {
            IERC721(options[optionId].premiumAsset).safeTransferFrom(
                address(this), 
                msg.sender, 
                options[optionId].indexOfPremium
            );
        } else if(optionDetails[optionId].premiumAssetType == uint(AssetTypes.ERC1155)) {
            IERC1155(options[optionId].premiumAsset).safeTransferFrom(
                address(this), 
                msg.sender, 
                options[optionId].indexOfPremium, 
                amount,
                bytes("")
            );
        } else {
            revert("D5");
        }
        emit WithdrawPremium(msg.sender, optionId, amount);
    }

    function exerciseOption(uint optionId) 
        external 
        override 
    {
        require(optionDetails[optionId].counterAssetType ==  uint(AssetTypes.ERC20), "D6");
        IERC20(options[optionId].counterAsset).transferFrom(msg.sender , address(this), options[optionId].amountOfCA);
        _exerciseOption(msg.sender ,optionId);
    }

    function listOption(
        uint optionId, 
        address asset, 
        uint amount
        ) 
        external 
        override 
        OptionExists(optionId) 
        OnlyParticipant(msg.sender, optionId)
        Expired(optionId ,false) 
    {
        require(!optionDetails[optionId].exercised, "D7");
        optionDetails[optionId].isListed = true;
        optionDetails[optionId].listAsset = asset;
        optionDetails[optionId].listAmount = amount;
        optionDetails[optionId].listAssetType = _determineERCStandart(asset);
        emit Listed(optionId, true);
    }

    function delistOption(uint optionId) 
        public 
        override 
        OptionExists(optionId) 
        OnlyParticipant(msg.sender, optionId) 
    {
        require(optionDetails[optionId].isListed, "D7");
        optionDetails[optionId].isListed = false;
        emit Listed(optionId, false);
    }

    function withdrawCA(uint optionId) 
        external 
        override 
        OptionExists(optionId) 
        OnlyInitiator(msg.sender, optionId)  
    {
        require(optionDetails[optionId].exercised, "D10");
        require(options[optionId].amountOfCA > 0, "D11");
        uint amount = options[optionId].amountOfCA;
        options[optionId].amountOfCA = 0;
        if (optionDetails[optionId].counterAssetType == uint(AssetTypes.ERC20)) {
            IERC20(options[optionId].counterAsset).transfer(msg.sender, amount);
        } else if(optionDetails[optionId].counterAssetType == uint(AssetTypes.ERC721)) {
            IERC721(options[optionId].counterAsset).safeTransferFrom(
                address(this),
                msg.sender,
                options[optionId].indexOfCounter);
        } else if(optionDetails[optionId].counterAssetType == uint(AssetTypes.ERC1155)) {
            IERC1155(options[optionId].counterAsset).safeTransferFrom(
                address(this), 
                msg.sender, 
                options[optionId].indexOfCounter, 
                amount,
                bytes("")
                );
        } else {
            revert("D5");
        }
        emit WithdrawCA(msg.sender, optionId, options[optionId].amountOfCA);
    }

    function buyOption(uint optionId) 
        external 
        override 
    {
        require(optionDetails[optionId].listAssetType == uint(AssetTypes.ERC20), "D6");
        IERC20(optionDetails[optionId].listAsset).transferFrom(msg.sender, address(this), optionDetails[optionId].listAmount);
        _buyOption(msg.sender ,optionId);
    }

    function withdraw(
        address asset,
        uint index, 
        uint amount) external override 
    {
        require(withdrawAllowance[asset][msg.sender] >= amount, "D15");
        withdrawAllowance[asset][msg.sender] -= amount;
        uint assetType = _determineERCStandart(asset);
        if (assetType == uint(AssetTypes.ERC20)) {
            IERC20(asset).transfer(msg.sender, amount);
        } else if(assetType == uint(AssetTypes.ERC721)) {
            IERC721(asset).safeTransferFrom(
                address(this),
                msg.sender,
                index
                );
        } else if(assetType == uint(AssetTypes.ERC1155)) {
            IERC1155(asset).safeTransferFrom(
                address(this), 
                msg.sender, 
                index, 
                amount,
                bytes("")
                );
            } else {
                revert("D5");
        }
        emit Withdraw(asset, msg.sender, amount);
        }


    function onERC721Received(
            address operator,
            address from,
            uint256 tokenId,
            bytes calldata data
        ) external virtual override returns (bytes4){
            _handleTokenReceive(operator, from, tokenId, 1, data, true); 
            return this.onERC721Received.selector;
        }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
        ) external virtual override returns (bytes4)
    {   
       _handleTokenReceive(operator, from, id, value, data, false);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external virtual override returns (bytes4){
        revert("Does not implement ERC1155BatchReceive");
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

    function _determineERCStandart(address addr) internal returns (uint8){
        if (addr.isContract()){
            if(_isSupportsInterface(addr, ERC1155_INTERFACE_ID)){
                return uint8(AssetTypes.ERC1155);
            } else if (_isSupportsInterface(addr, ERC721_INTERFACE_ID)){
                return uint8(AssetTypes.ERC721);
            } else {
                return uint8(AssetTypes.ERC20);
            }
        } else {
            revert("Address is not a contract");
        }
    }

    function _participateOption(address participator,uint optionId) 
        internal      
        OptionExists(optionId) 
        Participated(optionId, false) 
        OfferPeriod(optionId, true)  
    {
        options[optionId].participant = participator;
        optionDetails[optionId].offerEnd = block.timestamp;
        emit Participate(participator, optionId);
    } 

    function _setOptionParams(
        address initiator,
        uint optionId,
        uint amountOfColleteral,
        uint amountOfCA, 
        uint premiumAmount, 
        uint optionExpiry, 
        uint offerEnd
        ) 
        internal 
        OptionExists(optionId) 
        OnlyInitiator(initiator, optionId) 
        {
            require(optionDetails[optionId].optionExpiry == 0, "D16");
            options[optionId].amountOfColleteral = amountOfColleteral;
            options[optionId].amountOfCA = amountOfCA;
            options[optionId].premiumAmount = premiumAmount;
            optionDetails[optionId].optionExpiry = block.timestamp + optionExpiry;
            optionDetails[optionId].offerEnd = block.timestamp + offerEnd;
            emit Offer(initiator, optionId, true);
        }

    function _transferColleteral(address to, uint optionId) internal {
        uint amount = options[optionId].amountOfColleteral;
        options[optionId].amountOfColleteral = 0;
        if (optionDetails[optionId].colleteralType == uint(AssetTypes.ERC20)) {
            IERC20(options[optionId].colleteral).transfer(to, amount);
        } else if(optionDetails[optionId].colleteralType == uint(AssetTypes.ERC721)) {
            IERC721(options[optionId].colleteral).safeTransferFrom(
                address(this),
                to,
                options[optionId].indexOfColleteral);
        } else if(optionDetails[optionId].colleteralType == uint(AssetTypes.ERC1155)) {
            IERC1155(options[optionId].colleteral).safeTransferFrom(
                address(this), 
                to, 
                options[optionId].indexOfColleteral, 
                amount,
                bytes("")
                );
        } else {
            revert("D5");
        }
        emit WithdrawColleteral(to, optionId, amount);
    }

     function _exerciseOption(address to,uint optionId) 
        internal 
        OptionExists(optionId) 
        Expired(optionId, false)
        OnlyParticipant(to, optionId)
    {
        require(!optionDetails[optionId].exercised, "D7");
        optionDetails[optionId].exercised = true;
        _transferColleteral(to ,optionId);
        emit Exercise(to, optionId);
    }

    function _buyOption(address to, uint optionId) 
        internal 
        OptionExists(optionId) 
        Expired(optionId, false)
    {
        require(optionDetails[optionId].isListed, "D14");
        withdrawAllowance[optionDetails[optionId].listAsset][options[optionId].participant] += optionDetails[optionId].listAmount;
        emit Transfer(options[optionId].participant, to, optionId);
        options[optionId].participant = to;
        delistOption(optionId);
    }

    /**
        modes:
        - 1 : SetOptionParams
        - 2 : Participate
        - 3 : Buy Option
        - 4 : Exercise Option
    */
    function _handleTokenReceive(   
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data,
        bool check) internal 
    {   
        uint8 mode = abi.decode(data[:32], (uint8));     
        if(mode == 1) {
            //console.log("mode: 1");
            (uint optionId,
            uint amountOfCA, 
            uint premiumAmount, 
            uint optionExpiry, 
            uint offerEnd)  = abi.decode(data[32:], (uint , uint, uint, uint, uint));
            require(msg.sender == options[optionId].colleteral, "D19");
            require(id == options[optionId].indexOfColleteral, "D22");
            _setOptionParams(operator, optionId, value, amountOfCA, premiumAmount, optionExpiry, offerEnd);
        } else if(mode == 2) {
            console.log("mode: 2");
            uint optionId= abi.decode(data[32:], (uint));
            require(msg.sender == options[optionId].premiumAsset, "D19");
            require(check || options[optionId].premiumAmount >= value, "D20");
            require(id == options[optionId].indexOfPremium, "D22");
            _participateOption(operator ,optionId);
        } else if(mode == 3) {
            //console.log("mode: 3");
            uint optionId= abi.decode(data[32:], (uint));
            require(msg.sender == optionDetails[optionId].listAsset, "D19");
            require(check || optionDetails[optionId].listAmount >= value, "D20");
            require(id == optionDetails[optionId].indexOfListAsset, "D22");
            _buyOption(operator, optionId);
        } else if(mode == 4) {
            console.log("mode: 4");
            uint optionId= abi.decode(data[32:], (uint));
            require(msg.sender == options[optionId].counterAsset, "D19");
            require(check || options[optionId].amountOfCA >= value, "D20");
            require(id == options[optionId].indexOfCounter, "D22");
            _exerciseOption(operator ,optionId);
        } else {
            revert("D21");
        }
    }        
}