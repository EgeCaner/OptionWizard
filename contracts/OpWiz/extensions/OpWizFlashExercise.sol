// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "../interfaces/IOpWizFlashExercise.sol";
import "../OpWizSimple.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract OpWizFlashExercise is OpWizSimple, IOpWizFlashExercise {

    mapping(address => uint) private lastBalances;

    function flashExercise(
        uint optionId, 
        bytes calldata params
    ) 
        external 
        onlyParticipant(msg.sender, optionId)
        expired(optionId, false)
    {   
        _flashExercise(optionId, params);
    }

    function _flashExercise(uint optionId, bytes calldata params) internal participated(optionId, true) expired(optionId, false){
        require(!optionDetails[optionId].exercised, "D7");
        optionDetails[optionId].exercised = true;
        Option storage option = options[optionId];
        (
            address router,
            uint24 fee,
            uint256 amountOutMinimum,
            uint160 sqrtPriceLimitX96
        
        ) = abi.decode(params, (address, uint24, uint256, uint160));
        lastBalances[option.counterAsset] = _getBalance(option.counterAsset, address(this));
        uint amountOfColleteral = option.amountOfColleteral;
        option.amountOfColleteral = 0;
        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter.ExactInputSingleParams({
            tokenIn: option.colleteral,
            tokenOut: option.counterAsset, 
            fee: fee, 
            recipient: address(this), 
            deadline: block.timestamp + 1, 
            amountIn: amountOfColleteral, 
            amountOutMinimum: amountOutMinimum, 
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });

        uint256 receivedAmount = ISwapRouter(router).exactInputSingle(swapParams);
        require((receivedAmount - option.amountOfCA) > 0 , "No profits gained");
        uint256 currentBalance = _getBalance(option.counterAsset, address(this));
        require(currentBalance > lastBalances[option.counterAsset], "No profits gained");
        emit Exercise(option.participant, optionId);
        withdrawAllowance[option.counterAsset][option.participant] += (receivedAmount - option.amountOfCA);
    }

    function _getBalance(address token, address account) internal view returns(uint256 amount){
        (bool success, bytes memory data) =
        token.staticcall(abi.encodeWithSelector(IERC20.balanceOf.selector, account));
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }
    
}