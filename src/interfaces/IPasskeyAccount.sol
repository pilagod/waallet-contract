// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

struct Passkey {
    uint256 pubKeyX;
    uint256 pubKeyY;
}

interface IPasskeyAccount {
    event PasskeySet(uint256 publicKeyX, uint256 publicKeyY);
    event PasskeyUpdated(uint256 publicKeyX, uint256 publicKeyY);

    function updatePasskey(uint256 publicKeyX, uint256 publicKeyY) external;
}
