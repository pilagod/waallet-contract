// SPDX-License-Identifier: UNLICENSED
// Force a specific Solidity version for reproducibility.
pragma solidity ^0.8.13;

import { Test } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { console2 } from "forge-std/console2.sol";

import { EntryPoint } from "@aa/core/EntryPoint.sol";
import { IEntryPoint } from "@aa/interfaces/IEntryPoint.sol";
import {
    UserOperation, UserOperationLib
} from "@aa/interfaces/UserOperation.sol";

import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

import { PasskeyAccount, Base64Url } from "src/account/PasskeyAccount.sol";
import { PasskeyAccountFactory } from "src/account/PasskeyAccountFactory.sol";

contract PasskeyAccountTest is Test {
    using UserOperationLib for UserOperation;

    address constant entryPointMainnetAddr =
        0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;
    address constant entryPointGethAddr =
        0x5FbDB2315678afecb367f032d93F642f64180aa3;
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
            vm.getCode("EntryPoint.sol:EntryPoint");
        address entryPointAnotherAddr =
            Create2.deploy(0, bytes32(uint256(2)), entryPointBytecode);
        vm.etch(entryPointGethAddr, entryPointAnotherAddr.code);
        vm.etch(entryPointMainnetAddr, entryPointAnotherAddr.code);

        entryPoint = IEntryPoint(entryPointGethAddr);
        // entryPoint = IEntryPoint(entryPointMainnetAddr);

        // Deploy the PasskeyAccountFactory and PasskeyAccount
        passkeyAccountFactory = new PasskeyAccountFactory(entryPoint);
        passkeyAccount =
            passkeyAccountFactory.createAccount(credId, pubKeyX, pubKeyY, salt);
    }

    function testWebauthnWithUserOp() public {
        console2.logAddress(address(passkeyAccount));
        UserOperation memory userOp = this.createUserOp();
        // userOpHash:
        // Gethnode: 0xe6bdbae2879ecdae390c002716048d2f26f2a46b18eb819e21ad82e54a9b9919
        // Mainnet: 0x08c60ab9d9f2622bb8ce884b67f553d45900518362aed8356f058acae92357ea
        bytes32 userOpHash = getUserOpHash(userOp);
        // userOpHashBaseUrl:
        // Gethnode: 5r264oeeza45DAAnFgSNLybypGsY64GeIa2C5UqbmRk
        // Mainnet: CMYKudnyYiu4zohLZ_VT1FkAUYNirtg1bwWKyukjV-o
        string memory userOpHashBaseUrl =
            Base64Url.encode(abi.encodePacked(userOpHash));
        string memory clientDataJson = string.concat(
            '{"type":"webauthn.get","challenge":"',
            userOpHashBaseUrl,
            '","origin":"https://webauthn.passwordless.id","crossOrigin":false}'
        );
        console2.logBytes32(userOpHash);
        console2.logString(userOpHashBaseUrl);
        console2.logBytes(bytes(clientDataJson));

        bytes memory authenticatorData =
            hex"4fb20856f24a6ae7dafc2781090ac8477ae6e2bd072660236cc614c6fb7c2ea00500000001";
        // Test on Gethnode
        uint256 sigR =
            79989742396362963594147811038759420161389526291519568381973513208052666825670;
        // Test on Mainnet
        // uint256 sigR =
        //     16215626638256481224653703245698929562911260975214586003164815393541753303091;
        // Test on Gethnode
        uint256 sigS =
            60564441634584281332486487842777985011692936482102942812772457824444148629022;
        // Test on Mainnet
        // uint256 sigS =
        //     61693218141101862504114397997996460070590847077334214339447822237545340717822;

        userOp.signature = abi.encode(
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
        UserOperation memory userOp,
        address entryPointAddr
    ) public view returns (bytes32) {
        return this._getUserOpHash(userOp, entryPointAddr);
    }

    function _getUserOpHash(
        UserOperation calldata userOp,
        address entryPointAddr
    ) public view returns (bytes32) {
        return
            keccak256(abi.encode(userOp.hash(), entryPointAddr, block.chainid));
    }
}
