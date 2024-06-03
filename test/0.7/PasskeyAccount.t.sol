// SPDX-License-Identifier: UNLICENSED
// Force a specific Solidity version for reproducibility.
pragma solidity ^0.8.13;

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";

import { IEntryPoint } from "@aa7/interfaces/IEntryPoint.sol";
import { PackedUserOperation } from "@aa7/interfaces/PackedUserOperation.sol";
import { UserOperationLib } from "@aa7/core/UserOperationLib.sol";

import { PasskeyAccount, Base64Url } from "src/0.7/account/PasskeyAccount.sol";
import { PasskeyAccountFactory } from
    "src/0.7/account/PasskeyAccountFactory.sol";

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
        // Align the entryPoint address with the one on the Gethnode and Mainnet
        bytes memory entryPointBytecode =
            vm.getCode("Artifacts.sol:EntryPoint7");
        vm.etch(entryPointAddr, entryPointBytecode);
        entryPoint = IEntryPoint(entryPointAddr);

        // Deploy the PasskeyAccountFactory and PasskeyAccount
        passkeyAccountFactory = new PasskeyAccountFactory(entryPoint);
        passkeyAccount =
            passkeyAccountFactory.createAccount(credId, pubKeyX, pubKeyY, salt);
    }

    function testWebauthnWithUserOp() public {
        console2.logAddress(address(passkeyAccount));
        PackedUserOperation memory userOp = this.createUserOp();
        bytes32 userOpHash = getUserOpHash(userOp); // 0x2c6097713f185acb9cf9fc75ca012004575ed8a168912adefeb856ac6ee31061
        string memory userOpHashBaseUrl =
            Base64Url.encode(abi.encodePacked(userOpHash)); // gLgsGseZ7hck_K5eP4DSLFqSqGjj5EeRSK1WjbUP1qE
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
            100407585440395893095398173404906105781938870920221233750192630618247111829711;
        uint256 sigS =
            4820039710502118529461298576647450319742112775936218771711378789258075473652;

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
