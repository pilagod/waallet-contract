// SPDX-License-Identifier: UNLICENSED
// Force a specific Solidity version for reproducibility.
pragma solidity ^0.8.13;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { EntryPoint } from
    "@account-abstraction/0.7/contracts/core/EntryPoint.sol";
import { IEntryPoint } from
    "@account-abstraction/0.7/contracts/interfaces/IEntryPoint.sol";
import { PackedUserOperation } from
    "@account-abstraction/0.7/contracts/interfaces/PackedUserOperation.sol";
import { UserOperationLib } from
    "@account-abstraction/0.7/contracts/core/UserOperationLib.sol";

import { PasskeyAccount, Base64Url } from "src/account/0.7/PasskeyAccount.sol";
import { PasskeyAccountFactory } from
    "src/account/0.7/PasskeyAccountFactory.sol";

contract PasskeyAccountTest is Test {
    using UserOperationLib for PackedUserOperation;

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
        passkeyAccountFactory = new PasskeyAccountFactory(entryPoint);
        passkeyAccount =
            passkeyAccountFactory.createAccount(credId, pubKeyX, pubKeyY, salt);
    }

    function testWebauthnWithUserOp() public view {
        console2.logAddress(address(passkeyAccount));
        PackedUserOperation memory userOp = this.createUserOp();
        bytes32 userOpHash = getUserOpHash(userOp); // 0x80b82c1ac799ee1724fcae5e3f80d22c5a92a868e3e4479148ad568db50fd6a1
        console2.logBytes32(userOpHash);
        string memory userOpHashBaseUrl =
            Base64Url.encode(abi.encodePacked(userOpHash)); // gLgsGseZ7hck_K5eP4DSLFqSqGjj5EeRSK1WjbUP1qE
        console2.logString(userOpHashBaseUrl);
        console2.logString(userOpHashBaseUrl);
        console2.logString(userOpHashBaseUrl);
        string memory clientDataJson = string.concat(
            '{"type":"webauthn.get","challenge":"',
            userOpHashBaseUrl,
            '","origin":"https://webauthn.passwordless.id","crossOrigin":false}'
        );
        console2.logBytes32(userOpHash);
        console2.logString(userOpHashBaseUrl);
        console2.logBytes(bytes(clientDataJson));

        bytes memory authenticatorData =
            hex"4fb20856f24a6ae7dafc2781090ac8477ae6e2bd072660236cc614c6fb7c2ea01d00000000";
        uint256 sigR =
            43777763158794140938568405442257097307265824726437265921818183423749900982475;
        uint256 sigS =
            33307018633662411339576384710157170944124495385049361320569752306379371449137;

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

        // Secp256r1 curve order
        uint256 n =
            0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551;
        // For malleable signatures, like upper-range s-values, calculate a new s-value.
        if (sigS > n / 2) {
            sigS = n - sigS;
        }
        console2.logUint(sigS);

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
    function createUserOp() public pure returns (PackedUserOperation memory) {
        return PackedUserOperation({
            sender: address(0),
            nonce: 0,
            initCode: bytes(""),
            callData: bytes(""),
            accountGasLimits: bytes32(uint256(999999)),
            preVerificationGas: 0,
            gasFees: bytes32(uint256(1 gwei)),
            paymasterAndData: bytes(""),
            signature: bytes("")
        });
    }

    function getUserOpHash(PackedUserOperation memory userOp)
        public
        view
        returns (bytes32)
    {
        return this._getUserOpHash(userOp, address(entryPoint));
    }

    function getUserOpHash(
        PackedUserOperation memory _userOp,
        address _entryPointAddr
    ) public view returns (bytes32) {
        return this._getUserOpHash(_userOp, _entryPointAddr);
    }

    function _getUserOpHash(
        PackedUserOperation calldata _userOp,
        address _entryPointAddr
    ) public view returns (bytes32) {
        return keccak256(
            abi.encode(_userOp.hash(), _entryPointAddr, block.chainid)
        );
    }
}