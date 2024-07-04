// SPDX-License-Identifier: UNLICENSED
// Force a specific Solidity version for reproducibility.
pragma solidity ^0.8.13;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";

import { EntryPoint } from
    "@account-abstraction/0.6/contracts/core/EntryPoint.sol";
import { IEntryPoint } from
    "@account-abstraction/0.6/contracts/interfaces/IEntryPoint.sol";
import {
    UserOperation,
    UserOperationLib
} from "@account-abstraction/0.6/contracts/interfaces/UserOperation.sol";

import { ECDSA } from
    "@openzeppelin-contracts/4.9/contracts/utils/cryptography/ECDSA.sol";

import { PasskeyAccount } from "src/account/0.6/PasskeyAccount.sol";
import { PasskeyAccountFactory } from
    "src/account/0.6/PasskeyAccountFactory.sol";
import { Base64Url } from "src/util/Base64Url.sol";

contract PasskeyAccountTest is Test {
    using UserOperationLib for UserOperation;

    // Secp256r1 curve order
    uint256 constant P256_N =
        0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551;

    address constant entryPointAddr = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    string constant credId = "9h5F3DgLSjSMdnVOadmhCw";
    uint256 constant pubKeyX =
        67299174900712686363169673082376821529726602378544032702281553676098545184711;
    uint256 constant pubKeyY =
        104273800132786176334597151467609377740095818152192999025225464410568038480397;
    uint256 constant salt = 0;

    IEntryPoint public entryPoint;
    PasskeyAccountFactory public passkeyAccountFactory;
    PasskeyAccount public passkeyAccount;

    function setUp() public {
        bytes memory entryPointCreationCode = type(EntryPoint).creationCode;

        // Align the entryPoint address with the one on the Gethnode and Mainnet
        vm.etch(entryPointAddr, entryPointCreationCode);
        entryPoint = IEntryPoint(entryPointAddr);

        // Deploy the PasskeyAccountFactory and PasskeyAccount
        passkeyAccountFactory = new PasskeyAccountFactory(entryPoint, address(0));
        passkeyAccount =
            passkeyAccountFactory.createAccount(credId, pubKeyX, pubKeyY, salt);
    }

    function testWebauthnWithUserOp() public view {
        UserOperation memory userOp = this.createUserOp();
        bytes32 userOpHash = getUserOpHash(userOp);
        string memory userOpHashBaseUrl = Base64Url.encode(
            abi.encodePacked(ECDSA.toEthSignedMessageHash(userOpHash))
        ); // YGHW12yxLom580l3ybtTZF8a8NDl2LgdPmX1B_y2eno
        string memory clientDataJson = string.concat(
            '{"type":"webauthn.get","challenge":"',
            userOpHashBaseUrl,
            '","origin":"https://webauthn.passwordless.id","crossOrigin":false}'
        );

        bytes memory authenticatorData =
            hex"4fb20856f24a6ae7dafc2781090ac8477ae6e2bd072660236cc614c6fb7c2ea01d00000000";
        uint256 sigR =
            38724109948561436095576077243032190621845383779944965127969356788038003839143;
        uint256 sigS =
            76418446211974146173072857078323968075884095252188304117596341969150001009713;

        console2.logString("+ userOpHashBaseUrl:");
        console2.logString(userOpHashBaseUrl);
        console2.logString("+ clientDataJsonBaseUrl:");
        console2.logString(clientDataJson);
        console2.logString("+ signatureS:");
        console2.logUint(sigS);
        console2.logString("+ signatureSMalleability:");
        console2.logUint(P256_N - sigS);

        userOp.signature = abi.encode(
            false,
            authenticatorData,
            true,
            clientDataJson,
            uint256(23),
            uint256(1),
            sigR,
            sigS
        );
        // Validate signature failed
        assertEq(passkeyAccount.validateSignature(userOp, userOpHash), 1);

        // For malleable signatures, like upper-range s-values, calculate a new s-value.
        if (sigS > P256_N / 2) {
            sigS = P256_N - sigS;
        }

        userOp.signature = abi.encode(
            false,
            authenticatorData,
            true,
            clientDataJson,
            uint256(23),
            uint256(1),
            sigR,
            sigS
        );
        // Validate signature succeeded
        assertEq(passkeyAccount.validateSignature(userOp, userOpHash), 0);
    }

    /**
     * Helpers
     */
    function createUserOp() public pure returns (UserOperation memory) {
        return UserOperation({
            sender: address(0),
            nonce: 0,
            initCode: bytes(""),
            callData: bytes(""),
            callGasLimit: 999999,
            verificationGasLimit: 999999,
            preVerificationGas: 0,
            maxFeePerGas: 1 gwei,
            maxPriorityFeePerGas: 1 gwei,
            paymasterAndData: bytes(""),
            signature: bytes("")
        });
    }

    function getUserOpHash(UserOperation memory userOp)
        public
        view
        returns (bytes32)
    {
        return this._getUserOpHash(userOp, address(entryPoint));
    }

    function getUserOpHash(
        UserOperation memory _userOp,
        address _entryPointAddr
    ) public view returns (bytes32) {
        return this._getUserOpHash(_userOp, _entryPointAddr);
    }

    function _getUserOpHash(
        UserOperation calldata _userOp,
        address _entryPointAddr
    ) public view returns (bytes32) {
        return keccak256(
            abi.encode(_userOp.hash(), _entryPointAddr, block.chainid)
        );
    }
}
