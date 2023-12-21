// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

struct Passkey {
    string credId;
    uint256 pubKeyX;
    uint256 pubKeyY;
}

interface IPasskeyAccount {
    event PasskeyInitialized(string credId, uint256 pubKeyX, uint256 pubKeyY);
    event PasskeyUpdated(string credId, uint256 pubKeyX, uint256 pubKeyY);

    function updatePasskey(Passkey calldata _passkey) external;
}
