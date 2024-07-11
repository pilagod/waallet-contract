// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import { ERC1967Proxy } from "@openzeppelin-contracts/4.9/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract CodeReader {
    bytes constant public code = type(ERC1967Proxy).creationCode;
}
