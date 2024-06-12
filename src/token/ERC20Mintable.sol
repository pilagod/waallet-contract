// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    ERC20,
    ERC20Burnable
} from
    "@openzeppelin-contracts/5.0/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { Context } from
    "@openzeppelin-contracts/5.0/contracts/utils/Context.sol";

contract ERC20Mintable is Context, ERC20Burnable {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) { }

    function mint(address to, uint256 value) external {
        _mint(to, value);
    }
}
