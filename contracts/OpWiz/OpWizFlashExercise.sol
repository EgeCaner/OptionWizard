// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./IOpWizFlashLoanSimpleReceiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./OpWizSimple.sol";
import { IPoolAddressesProvider } from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import { IPool } from "@aave/core-v3/contracts/interfaces/IPool.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract OpWizFlashExercise is IERC165, OpWizSimple, IOpWizFlashLoanSimpleReceiver {

    mapping(address => uint) private lastBalances;

    IPoolAddressesProvider public override ADDRESSES_PROVIDER;
    IPool public override POOL;

    modifier onlyPool(){
        require(msg.sender == address(POOL), "Only flash-pool allowed");
        _;
    }

    function flashExercise(
        uint optionId, 
        address flashPool, 
        uint16 referralCode,
        bytes calldata params
    ) 
        external 
        onlyParticipant(msg.sender, optionId)
        expired(optionId, false)
        rejectZeroAddress(flashPool)
    {   
        Option storage option = options[optionId];
        lastBalances[option.counterAsset] = IERC20(option.counterAsset).balanceOf(address(this));
        ADDRESSES_PROVIDER = IPoolAddressesProvider(flashPool);
        POOL = IPool(ADDRESSES_PROVIDER.getPool());
        POOL.flashLoanSimple(address(this), option.counterAsset, option.amountOfCA, params, referralCode);
    }

    /**
   * @notice Executes an operation after receiving the flash-borrowed asset
   * @dev Ensure that the contract can return the debt + premium, e.g., has
   *      enough funds to repay and has approved the Pool to pull the total amount
   * @param asset The address of the flash-borrowed asset
   * @param amount The amount of the flash-borrowed asset
   * @param premium The fee of the flash-borrowed asset
   * @param initiator The address of the flashloan initiator
   * @param params The byte-encoded params passed when initiating the flashloan
   * @return True if the execution of the operation succeeds, false otherwise
   */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external onlyPool() returns (bool){
        //implement the arbitrage here
        (
            uint optionId,
            address router,
            uint24 fee,
            uint256 amountOutMinimum,
            uint160 sqrtPriceLimitX96
        
        ) = abi.decode(params, (uint, address, uint24, uint256, uint160));
        uint currentBalance = IERC20(options[optionId].counterAsset).balanceOf(address(this));
        require((currentBalance - amount) >= lastBalances[options[optionId].counterAsset], "D20");
        require(asset == options[optionId].counterAsset, "Assets does not match" );
        require(amount >= options[optionId].amountOfCA, "D20");
        lastBalances[options[optionId].counterAsset] = IERC20(options[optionId].counterAsset).balanceOf(address(this));
        _flashExercise(optionId);
        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter.ExactInputSingleParams({
            tokenIn: options[optionId].colleteral,
            tokenOut: options[optionId].counterAsset, 
            fee: fee, 
            recipient: address(this), 
            deadline: block.timestamp + 1, 
            amountIn: options[optionId].amountOfColleteral, 
            amountOutMinimum: amountOutMinimum, 
            sqrtPriceLimitX96: sqrtPriceLimitX96
        });

        uint debt = amount + premium;
        uint256 receivedAmount = ISwapRouter(router).exactInputSingle(swapParams);
        require((receivedAmount - debt) > 0 , "No profits gained");
        currentBalance = IERC20(options[optionId].counterAsset).balanceOf(address(this));
        require(currentBalance > lastBalances[options[optionId].counterAsset], "No profits gained");
        IERC20(options[optionId].counterAsset).approve(ADDRESSES_PROVIDER.getPool(), debt);
        return true;
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
               interfaceId == this.executeOperation.selector;
    }

    function _flashExercise(uint optionId) internal participated(optionId, true) expired(optionId, false){
        require(!optionDetails[optionId].exercised, "D7");
        optionDetails[optionId].exercised = true;
        emit Exercise(options[optionId].participant, optionId);
    }
}