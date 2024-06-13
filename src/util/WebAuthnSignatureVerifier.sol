// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Passkey } from "src/interface/IPasskeyAccount.sol";
import { Base64Url } from "./Base64Url.sol";

library WebAuthnSignatureVerifier {
    /// P256 curve order n/2 for malleability check
    uint256 constant P256_N_DIV_2 =
        57896044605178124381348723474703786764998477612067880171211129530534256022184;

    bytes1 constant AUTH_DATA_FLAGS_UP = 0x01; // Bit 0
    bytes1 constant AUTH_DATA_FLAGS_UV = 0x04; // Bit 2
    bytes1 constant AUTH_DATA_FLAGS_BE = 0x08; // Bit 3
    bytes1 constant AUTH_DATA_FLAGS_BS = 0x10; // Bit 4

    // Using a struct to avoid stack too deep errors
    struct SignatureData {
        bytes challenge;
        bytes authenticatorData;
        bool requireUserVerification;
        string clientDataJSON;
        uint256 challengeLocation;
        uint256 responseTypeLocation;
        uint256 r;
        uint256 s;
        uint256 x;
        uint256 y;
    }

    // TODO: Assign Passkey with credId.
    function isPasskeyValid(Passkey memory _passkey)
        internal
        pure
        returns (bool)
    {
        return _passkey.pubKeyX != 0 && _passkey.pubKeyY != 0;
    }

    function verifySignatureAllowMalleability(
        address p256Verifier,
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

    function verifySignature(
        address p256Verifier,
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

        return verifySignatureAllowMalleability(
            p256Verifier, messageHash, r, s, x, y
        );
    }

    /**
     * Verifies a Webauthn P256 signature (Authentication Assertion) as described
     * in https://www.w3.org/TR/webauthn-2/#sctn-verifying-assertion. We do not
     * verify all the steps as described in the specification, only ones relevant
     * to our context. Please carefully read through this list before usage.
     */
    function verifySignatureWebauthn(
        address p256Verifier,
        SignatureData memory signatureData
    ) internal view returns (bool) {
        // Check that authenticatorData has good flags
        if (
            signatureData.authenticatorData.length < 37
                || !_checkAuthFlags(
                    signatureData.authenticatorData[32],
                    signatureData.requireUserVerification
                )
        ) {
            return false;
        }

        // Check that response is for an authentication assertion
        string memory responseType = '"type":"webauthn.get"';
        if (
            !contains(
                responseType,
                signatureData.clientDataJSON,
                signatureData.responseTypeLocation
            )
        ) {
            return false;
        }

        // Check that challenge is in the clientDataJSON
        string memory challengeB64url =
            Base64Url.encode(signatureData.challenge);
        string memory challengeProperty =
            string.concat('"challenge":"', challengeB64url, '"');

        if (
            !contains(
                challengeProperty,
                signatureData.clientDataJSON,
                signatureData.challengeLocation
            )
        ) {
            return false;
        }

        // Check that the public key signed sha256(authenticatorData || sha256(clientDataJSON))
        bytes32 clientDataJSONHash = sha256(bytes(signatureData.clientDataJSON));
        bytes32 messageHash = sha256(
            abi.encodePacked(
                signatureData.authenticatorData, clientDataJSONHash
            )
        );

        return verifySignature(
            p256Verifier,
            messageHash,
            signatureData.r,
            signatureData.s,
            signatureData.x,
            signatureData.y
        );
    }

    /// Checks whether substr occurs in str starting at a given byte offset.
    function contains(
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
