// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { EntryPoint } from
    "@account-abstraction/0.6/contracts/core/EntryPoint.sol";
import { SimpleAccountFactory } from
    "@account-abstraction/0.6/contracts/samples/SimpleAccountFactory.sol";
import { VerifyingPaymaster } from
    "@account-abstraction/0.6/contracts/samples/VerifyingPaymaster.sol";

contract EntryPoint0p6 is EntryPoint { }
