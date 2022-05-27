// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./IOpWizSimple.sol";

interface IOpWizFlashExercise is IOpWizSimple {

    function flashExercise(
        uint optionId,
        uint minAmount,
        bytes calldata params
    ) external;

}