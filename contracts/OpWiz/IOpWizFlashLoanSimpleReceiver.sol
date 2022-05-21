// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./IOpWizSimple.sol";
import "@aave/core-v3/contracts/flashloan/interfaces/IFlashLoanSimpleReceiver.sol";

interface IOpWizFlashLoanSimpleReceiver is IOpWizSimple, IFlashLoanSimpleReceiver {

    function flashExercise(
        uint optionId,
        address flashPool,
        uint amount,
        uint16 referralCode,
        bytes calldata params
    ) external;
}