// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./IOpWizFlashLoanSimpleReceiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./OpWizSimple.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";

contract OpWizFlashExercise is IERC165, OpWizSimple, IOpWizFlashLoanSimpleReceiver {

    IPoolAddressesProvider public override ADDRESSES_PROVIDER;
    IPool public override POOL;

    function flashExercise(
        uint optionId, 
        address flashPool, 
        uint amount,  
        uint16 referralCode,
        bytes calldata params
    ) 
        external 
        onlyParticipant(msg.sender, optionId)
        expired(optionId, false)
    {
       ADDRESSES_PROVIDER = IPoolAddressesProvider(flashPool);
       POOL = IPool(ADDRESSES_PROVIDER.getPool());
       POOL.flashLoanSimple(address(this), options[optionId].colleteral, options[optionId].amountOfColleteral, params, referralCode);
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
    ) external returns (bool){
        //implement the arbitrage here
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

}