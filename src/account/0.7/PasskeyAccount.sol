// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {
    IEntryPoint,
    PackedUserOperation
} from "@account-abstraction/0.7/contracts/interfaces/IEntryPoint.sol";
import { SimpleAccount } from
    "@account-abstraction/0.7/contracts/samples/SimpleAccount.sol";
import { SIG_VALIDATION_FAILED } from
    "@account-abstraction/0.7/contracts/core/Helpers.sol";

import { IPasskeyAccount, Passkey } from "src/interface/IPasskeyAccount.sol";
import { Base64Url } from "src/util/Base64Url.sol";
import { WebAuthnSignatureVerifier } from
    "src/core/WebAuthnSignatureVerifier.sol";

contract PasskeyAccount is
    SimpleAccount,
    IPasskeyAccount,
    WebAuthnSignatureVerifier
{
    Passkey public passkey;

    // The constructor is used only for the "implementation" and only sets immutable values.
    // Mutable value slots for proxy accounts are set by the 'initialize' function.
    constructor(
        IEntryPoint _entryPoint,
        address _p256Verifier
    ) SimpleAccount(_entryPoint) WebAuthnSignatureVerifier(_p256Verifier) { }

    /**
     * The initializer for the PassKeysAcount instance.
     * @param credId the credentail id of the passkey.
     * @param pubKeyX public key X val from a passkey that will have a full ownership and control of this account.
     * @param pubKeyY public key X val from a passkey that will have a full ownership and control of this account.
     */
    function initialize(
        string calldata credId,
        uint256 pubKeyX,
        uint256 pubKeyY
    ) external initializer {
        super._initialize(address(0));
        _initPasskey(credId, pubKeyX, pubKeyY);
    }

    // TODO: Assign Passkey with credId.
    function isPasskeyValid(Passkey memory _passkey)
        public
        pure
        returns (bool)
    {
        return _passkey.pubKeyX != 0 && _passkey.pubKeyY != 0;
    }

    function updatePasskey(Passkey calldata _passkey)
        external
        virtual
        override
    {
        require(msg.sender == address(this), "Only wallet can update passkeys");
        require(isPasskeyValid(_passkey), "Zero passkey is not allowed");
        require(isPasskeyValid(passkey), "Passkey doesn't exist");
        passkey.credId = _passkey.credId;
        passkey.pubKeyX = _passkey.pubKeyX;
        passkey.pubKeyY = _passkey.pubKeyY;
        emit PasskeyUpdated(passkey.credId, passkey.pubKeyX, passkey.pubKeyY);
    }

    function validateSignature(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash // As Webauthn's challenge
    ) external view returns (uint256) {
        return _validateSignature(userOp, userOpHash);
    }

    function _initPasskey(
        string memory credId,
        uint256 pubKeyX,
        uint256 pubKeyY
    ) internal {
        require(!isPasskeyValid(passkey), "Passkey already exists");
        passkey.credId = credId;
        passkey.pubKeyX = pubKeyX;
        passkey.pubKeyY = pubKeyY;
        emit PasskeyInitialized(credId, passkey.pubKeyX, passkey.pubKeyY);
    }

    /**
     * @param userOp typical PackedUserOperation
     * @param userOpHash the hash of the user operation.
     * @return validationData
     */
    function _validateSignature(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash // As Webauthn's challenge
    ) internal view virtual override returns (uint256) {
        require(isPasskeyValid(passkey), "Passkey doesn't exist");
        (
            bool isSimulation,
            bytes memory authenticatorData,
            bool requireUserVerification,
            string memory clientDataJSON,
            uint256 challengeLocation,
            uint256 responseTypeLocation,
            uint256 r,
            uint256 s
        ) = abi.decode(
            userOp.signature,
            (bool, bytes, bool, string, uint256, uint256, uint256, uint256)
        );

        bytes memory challenge =
            isSimulation ? bytes("") : abi.encodePacked(userOpHash);

        bool isSigValid = verifySignatureWebauthn(
            SignatureData({
                challenge: challenge,
                authenticatorData: authenticatorData,
                requireUserVerification: requireUserVerification,
                clientDataJSON: clientDataJSON,
                challengeLocation: challengeLocation,
                responseTypeLocation: responseTypeLocation,
                r: r,
                s: s,
                x: passkey.pubKeyX,
                y: passkey.pubKeyY
            })
        );
        if (isSimulation) {
            return SIG_VALIDATION_FAILED;
        }
        return isSigValid ? 0 : SIG_VALIDATION_FAILED;
    }
}
