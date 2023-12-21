// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Base64Url } from "../utils/Base64Url.sol";
import { IEntryPoint, UserOperation } from "@aa/interfaces/IEntryPoint.sol";
import { IPasskeyAccount, Passkey } from "../interfaces/IPasskeyAccount.sol";
import { P256Verifier } from "../utils/P256Verifier.sol";
import { SimpleAccount } from "@aa/samples/SimpleAccount.sol";

contract PasskeyAccount is SimpleAccount, IPasskeyAccount {
    string public knownCredId;
    P256Verifier public immutable p256Verifier;
    Passkey private passkey;
    
    // The constructor is used only for the "implementation" and only sets immutable values.
    // Mutable value slots for proxy accounts are set by the 'initialize' function.
    constructor(IEntryPoint anEntryPoint) SimpleAccount(anEntryPoint) {
        // Get a P256Verifier instance from the mainnet or Sepolia testnet.
        // p256Verifier = P256Verifier(0xc2b78104907F722DABAc4C69f826a522B2754De4);
        p256Verifier = new P256Verifier();
    }

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

    function updatePasskey(
        string calldata credId,
        uint256 pubKeyX,
        uint256 pubKeyY
    ) external virtual override {
        require(msg.sender == address(this), "Only wallet can update passkeys");
        require(pubKeyX != 0 && pubKeyY != 0, "Zero passkey is not allowed");
        require(
            passkey.pubKeyX != 0 && passkey.pubKeyY != 0,
            "Passkey doesn't exist"
        );
        knownCredId = credId;
        passkey.credId = credId;
        passkey.pubKeyX = pubKeyX;
        passkey.pubKeyY = pubKeyY;
        emit PasskeyUpdated(credId, passkey.pubKeyX, passkey.pubKeyY);
    }

    function validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash // As Webauthn's challenge
    ) external view returns (uint256) {
        return _validateSignature(userOp, userOpHash);
    }

    function _initPasskey(
        string memory credId,
        uint256 pubKeyX,
        uint256 pubKeyY
    ) internal {
        require(
            passkey.pubKeyX == 0 && passkey.pubKeyY == 0,
            "Passkey already exists"
        );
        knownCredId = credId;
        passkey.credId = credId;
        passkey.pubKeyX = pubKeyX;
        passkey.pubKeyY = pubKeyY;
        emit PasskeyInitialized(credId, passkey.pubKeyX, passkey.pubKeyY);
    }

    /**
     * @param userOp typical userOperation
     * @param userOpHash the hash of the user operation.
     * @return validationData
     */
    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash // As Webauthn's challenge
    ) internal view virtual override returns (uint256) {
        require(
            passkey.pubKeyX != 0 && passkey.pubKeyY != 0,
            "Passkey doesn't exist"
        );
        (
            bytes memory authenticatorData,
            bool requireUserVerification,
            string memory clientDataJSON,
            uint256 challengeLocation,
            uint256 responseTypeLocation,
            uint256 r,
            uint256 s
        ) = abi.decode(
            userOp.signature,
            (bytes, bool, string, uint256, uint256, uint256, uint256)
        );
        return _verifySignatureWebauthn(
            abi.encodePacked(userOpHash),
            authenticatorData,
            requireUserVerification,
            clientDataJSON,
            challengeLocation,
            responseTypeLocation,
            r,
            s,
            passkey.pubKeyX,
            passkey.pubKeyY
        ) ? 0 : SIG_VALIDATION_FAILED;
    }

    function _verifySignatureAllowMalleability(
        bytes32 messageHash,
        uint256 r,
        uint256 s,
        uint256 x,
        uint256 y
    ) internal view returns (bool) {
        bytes memory args = abi.encode(messageHash, r, s, x, y);
        (bool success, bytes memory ret) =
            address(p256Verifier).staticcall(args);
        assert(success); // never reverts, always returns 0 or 1

        return abi.decode(ret, (uint256)) == 1;
    }

    /// P256 curve order n/2 for malleability check
    uint256 constant P256_N_DIV_2 =
        57896044605178124381348723474703786764998477612067880171211129530534256022184;

    function _verifySignature(
        bytes32 messageHash,
        uint256 r,
        uint256 s,
        uint256 x,
        uint256 y
    ) internal view returns (bool) {
        // check for signature malleability
        if (s > P256_N_DIV_2) {
            return false;
        }

        return _verifySignatureAllowMalleability(messageHash, r, s, x, y);
    }

    /**
     * Verifies a Webauthn P256 signature (Authentication Assertion) as described
     * in https://www.w3.org/TR/webauthn-2/#sctn-verifying-assertion. We do not
     * verify all the steps as described in the specification, only ones relevant
     * to our context. Please carefully read through this list before usage.
     */
    function _verifySignatureWebauthn(
        bytes memory challenge,
        bytes memory authenticatorData,
        bool requireUserVerification,
        string memory clientDataJSON,
        uint256 challengeLocation,
        uint256 responseTypeLocation,
        uint256 r,
        uint256 s,
        uint256 x,
        uint256 y
    ) internal view returns (bool) {
        // Check that authenticatorData has good flags
        if (
            authenticatorData.length < 37
                || !_checkAuthFlags(authenticatorData[32], requireUserVerification)
        ) {
            return false;
        }

        // Check that response is for an authentication assertion
        string memory responseType = '"type":"webauthn.get"';
        if (!_contains(responseType, clientDataJSON, responseTypeLocation)) {
            return false;
        }

        // Check that challenge is in the clientDataJSON
        string memory challengeB64url = Base64Url.encode(challenge);
        string memory challengeProperty =
            string.concat('"challenge":"', challengeB64url, '"');

        if (!_contains(challengeProperty, clientDataJSON, challengeLocation)) {
            return false;
        }

        // Check that the public key signed sha256(authenticatorData || sha256(clientDataJSON))
        bytes32 clientDataJSONHash = sha256(bytes(clientDataJSON));
        bytes32 messageHash =
            sha256(abi.encodePacked(authenticatorData, clientDataJSONHash));

        return _verifySignature(messageHash, r, s, x, y);
    }

    /// Checks whether substr occurs in str starting at a given byte offset.
    function _contains(
        string memory substr,
        string memory str,
        uint256 location
    ) internal pure returns (bool) {
        bytes memory substrBytes = bytes(substr);
        bytes memory strBytes = bytes(str);

        uint256 substrLen = substrBytes.length;
        uint256 strLen = strBytes.length;

        for (uint256 i = 0; i < substrLen; i++) {
            if (location + i >= strLen) {
                return false;
            }

            if (substrBytes[i] != strBytes[location + i]) {
                return false;
            }
        }

        return true;
    }

    bytes1 constant AUTH_DATA_FLAGS_UP = 0x01; // Bit 0
    bytes1 constant AUTH_DATA_FLAGS_UV = 0x04; // Bit 2
    bytes1 constant AUTH_DATA_FLAGS_BE = 0x08; // Bit 3
    bytes1 constant AUTH_DATA_FLAGS_BS = 0x10; // Bit 4

    /// Verifies the authFlags in authenticatorData. Numbers in inline comment
    /// correspond to the same numbered bullets in
    /// https://www.w3.org/TR/webauthn-2/#sctn-verifying-assertion.
    function _checkAuthFlags(
        bytes1 flags,
        bool requireUserVerification
    ) internal pure returns (bool) {
        // 17. Verify that the UP bit of the flags in authData is set.
        if (flags & AUTH_DATA_FLAGS_UP != AUTH_DATA_FLAGS_UP) {
            return false;
        }

        // 18. If user verification was determined to be required, verify that
        // the UV bit of the flags in authData is set. Otherwise, ignore the
        // value of the UV flag.
        if (
            requireUserVerification
                && (flags & AUTH_DATA_FLAGS_UV) != AUTH_DATA_FLAGS_UV
        ) {
            return false;
        }

        // 19. If the BE bit of the flags in authData is not set, verify that
        // the BS bit is not set.
        if (flags & AUTH_DATA_FLAGS_BE != AUTH_DATA_FLAGS_BE) {
            if (flags & AUTH_DATA_FLAGS_BS == AUTH_DATA_FLAGS_BS) {
                return false;
            }
        }

        return true;
    }
}
