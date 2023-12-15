// SPDX-License-Identifier: UNLICENSED
// Force a specific Solidity version for reproducibility.
pragma solidity ^0.8.13;
import { Test } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { console2 } from "forge-std/console2.sol";

import { IEntryPoint } from "@aa/interfaces/IEntryPoint.sol";
import { UserOperation, UserOperationLib } from "@aa/interfaces/UserOperation.sol";

import { PasskeyAccount, Base64Url } from "src/account/PasskeyAccount.sol";
import { PasskeyAccountFactory } from "src/account/PasskeyAccountFactory.sol";

contract PasskeyAccountTest is Test {
    using UserOperationLib for UserOperation;

    // Get the entryPoint instance from the local node
    IEntryPoint public entryPoint =
        IEntryPoint(0x5FbDB2315678afecb367f032d93F642f64180aa3);
    // Get the entryPoint instance from the mainnet or Sepolia testnet.
    // IEntryPoint public entryPoint =
    //     IEntryPoint(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789);

    uint256 constant INIT_SALT = 0;
    uint256 testPubKeyX =
        70747862190418892867127882358686390299011343716765569792149600111446598813742;
    uint256 testPubKeyY =
        8074007520716788067706863005922410990642913820771605462164697216606521282195;

    PasskeyAccountFactory passkeyAccountFactory =
        new PasskeyAccountFactory(entryPoint);
    PasskeyAccount passkeyAccount;

    function setUp() public {
        passkeyAccount = passkeyAccountFactory.createAccount(
            INIT_SALT,
            testPubKeyX,
            testPubKeyY
        );
    }

    function testWebauthnWithUserOp() public {
        UserOperation memory userOp = createUserOp();
        bytes32 userOpHash = getUserOpHash(userOp); // 0xe6bdbae2879ecdae390c002716048d2f26f2a46b18eb819e21ad82e54a9b9919
        string memory userOpHashBaseUrl = Base64Url.encode(
            abi.encodePacked(userOpHash)
        ); // 5r264oeeza45DAAnFgSNLybypGsY64GeIa2C5UqbmRk
        string memory clientDataJson = string.concat(
            '{"type":"webauthn.get","challenge":"',
            userOpHashBaseUrl,
            '","origin":"http://localhost:5173","crossOrigin":false}'
        );
        console2.logBytes32(userOpHash);
        console2.logString(userOpHashBaseUrl);
        console2.logBytes(bytes(clientDataJson));

        bytes
            memory authenticatorData = hex"49960de5880e8c687434170f6476605b8fe4aeb9a28632c7995cf3ba831d97630500000002";
        uint256 sigR = 79364105459264678106601279046964491687113283247123239538498341605259803159856;
        uint256 sigS = 86939605370254087963327444288006268536903838109586780222890294256709829818906;

        // Secp256r1 curve order
        uint256 n = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551;
        // For malleable signatures, like upper-range s-values, calculate a new s-value.
        if (sigS > n / 2) {
            sigS = n - sigS;
        }
        console2.logUint(sigS);

        // Do not use abi.encodePacked() here.
        userOp.signature = abi.encode(
            authenticatorData,
            true,
            clientDataJson,
            uint256(23),
            uint256(1),
            sigR,
            sigS
        );

        assertEq(passkeyAccount.validateSignature(userOp, userOpHash), 0);
    }

    /*********************************
     *            Helpers            *
     *********************************/

    function createUserOp() internal pure returns (UserOperation memory) {
        return
            UserOperation({
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

    function getUserOpHash(
        UserOperation memory userOp
    ) internal view returns (bytes32) {
        return this._getUserOpHash(userOp, address(entryPoint));
    }

    function _getUserOpHash(
        UserOperation calldata userOp,
        address entryPointAddr
    ) public view returns (bytes32) {
        return
            keccak256(abi.encode(userOp.hash(), entryPointAddr, block.chainid));
    }
}
