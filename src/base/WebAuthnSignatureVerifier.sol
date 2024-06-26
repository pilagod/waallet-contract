// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Base64Url } from "src/util/Base64Url.sol";

abstract contract WebAuthnSignatureVerifier {
    address public immutable p256Verifier;

    /// P256 curve order n/2 for malleability check
    uint256 private constant _P256_N_DIV_2 =
        57896044605178124381348723474703786764998477612067880171211129530534256022184;

    bytes1 private constant _AUTH_DATA_FLAGS_UP = 0x01; // Bit 0
    bytes1 private constant _AUTH_DATA_FLAGS_UV = 0x04; // Bit 2
    bytes1 private constant _AUTH_DATA_FLAGS_BE = 0x08; // Bit 3
    bytes1 private constant _AUTH_DATA_FLAGS_BS = 0x10; // Bit 4

    constructor(address _p256Verifier) {
        p256Verifier = _p256Verifier;
    }

    function verifySignatureAllowMalleability(
        bytes32 messageHash,
        uint256 r,
        uint256 s,
        uint256 x,
        uint256 y
    ) public view returns (bool) {
        bytes memory args = abi.encode(messageHash, r, s, x, y);

        (bool success, bytes memory data) = p256Verifier.staticcall(args);

        uint256 returnValue;
        // Return true if the call was successful and the return value is 1
        if (success && data.length > 0) {
            assembly {
                returnValue := mload(add(data, 0x20))
            }
            return returnValue == 1;
        }

        // Otherwise return false for the unsucessful calls and invalid signatures
        return false;
    }

    function verifySignature(
        bytes32 messageHash,
        uint256 r,
        uint256 s,
        uint256 x,
        uint256 y
    ) public view returns (bool) {
        // check for signature malleability
        if (s > _P256_N_DIV_2) {
            return false;
        }

        return verifySignatureAllowMalleability(messageHash, r, s, x, y);
    }

    /**
     * Verifies a Webauthn P256 signature (Authentication Assertion) as described
     * in https://www.w3.org/TR/webauthn-2/#sctn-verifying-assertion. We do not
     * verify all the steps as described in the specification, only ones relevant
     * to our context. Please carefully read through this list before usage.
     */
    function verifySignatureWebauthn(
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
    ) public view returns (bool) {
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

        return verifySignature(messageHash, r, s, x, y);
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

    /// Verifies the authFlags in authenticatorData. Numbers in inline comment
    /// correspond to the same numbered bullets in
    /// https://www.w3.org/TR/webauthn-2/#sctn-verifying-assertion.
    function _checkAuthFlags(
        bytes1 flags,
        bool requireUserVerification
    ) internal pure returns (bool) {
        // 17. Verify that the UP bit of the flags in authData is set.
        if (flags & _AUTH_DATA_FLAGS_UP != _AUTH_DATA_FLAGS_UP) {
            return false;
        }

        // 18. If user verification was determined to be required, verify that
        // the UV bit of the flags in authData is set. Otherwise, ignore the
        // value of the UV flag.
        if (
            requireUserVerification
                && (flags & _AUTH_DATA_FLAGS_UV) != _AUTH_DATA_FLAGS_UV
        ) {
            return false;
        }

        // 19. If the BE bit of the flags in authData is not set, verify that
        // the BS bit is not set.
        if (flags & _AUTH_DATA_FLAGS_BE != _AUTH_DATA_FLAGS_BE) {
            if (flags & _AUTH_DATA_FLAGS_BS == _AUTH_DATA_FLAGS_BS) {
                return false;
            }
        }

        return true;
    }
}
