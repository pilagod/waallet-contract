// SPDX-License-Identifier: UNLICENSED
// Force a specific Solidity version for reproducibility.
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console2} from "forge-std/console2.sol";

import {IEntryPoint} from "@aa/interfaces/IEntryPoint.sol";
import {UserOperation, UserOperationLib} from "@aa/interfaces/UserOperation.sol";

import {PasskeyAccount, Base64Url} from "src/account/PasskeyAccount.sol";
import {PasskeyAccountFactory} from "src/account/PasskeyAccountFactory.sol";

contract PasskeyAccountTest is Test {
    using UserOperationLib for UserOperation;

    // Get the entryPoint instance from the local node
    IEntryPoint public entryPoint = IEntryPoint(0x5FbDB2315678afecb367f032d93F642f64180aa3);
    // Get the entryPoint instance from the mainnet or Sepolia testnet.
    // IEntryPoint public entryPoint =
    //     IEntryPoint(0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789);

    string constant testCredId = "SsXJcMCtCFAY-v5SOnuyD7p3wZ-Vgmigd2S9qIu8fZE";
    uint256 constant testPubKeyX = 45350939242947319465541081481587742776218222217118268954655717869512694523738;
    uint256 constant testPubKeyY = 46971273219734637107918601418670912287394323851286117401543534995054486983562;
    uint256 constant testSalt = 0;

    PasskeyAccountFactory passkeyAccountFactory = new PasskeyAccountFactory(entryPoint);
    PasskeyAccount passkeyAccount;

    function setUp() public {
        passkeyAccount = passkeyAccountFactory.createAccount(testCredId, testPubKeyX, testPubKeyY, testSalt);
    }

    function testWebauthnWithUserOp() public {
        console2.logAddress(address(passkeyAccount));
        UserOperation memory userOp = this.createUserOp();
        bytes32 userOpHash = getUserOpHash(userOp); // 0xe6bdbae2879ecdae390c002716048d2f26f2a46b18eb819e21ad82e54a9b9919
        string memory userOpHashBaseUrl = Base64Url.encode(abi.encodePacked(userOpHash)); // 5r264oeeza45DAAnFgSNLybypGsY64GeIa2C5UqbmRk
        string memory clientDataJson = string.concat(
            '{"type":"webauthn.get","challenge":"',
            userOpHashBaseUrl,
            '","origin":"http://localhost:5173","crossOrigin":false}'
        );
        console2.logBytes32(userOpHash);
        console2.logString(userOpHashBaseUrl);
        console2.logBytes(bytes(clientDataJson));

        bytes memory authenticatorData = hex"49960de5880e8c687434170f6476605b8fe4aeb9a28632c7995cf3ba831d97630500000000";
        uint256 sigR = 38422482115550154894411571250661239767708856192151538825148794304321693230302;
        uint256 sigS = 97210562961367985780808537729291992843247382980949801149567651394887789649977;

        // Do not use abi.encodePacked() here.
        userOp.signature = abi.encode(authenticatorData, true, clientDataJson, uint256(23), uint256(1), sigR, sigS);
        // Validate signature failed
        assertEq(passkeyAccount.validateSignature(userOp, userOpHash), 1);

        // Secp256r1 curve order
        uint256 n = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551;
        // For malleable signatures, like upper-range s-values, calculate a new s-value.
        if (sigS > n / 2) {
            sigS = n - sigS;
        }
        console2.logUint(sigS);

        userOp.signature = abi.encode(authenticatorData, true, clientDataJson, uint256(23), uint256(1), sigR, sigS);
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

    function getUserOpHash(UserOperation memory userOp) public view returns (bytes32) {
        return this._getUserOpHash(userOp, address(entryPoint));
    }

    function getUserOpHash(UserOperation memory userOp, address entryPointAddr) public view returns (bytes32) {
        return this._getUserOpHash(userOp, entryPointAddr);
    }

    function _getUserOpHash(UserOperation calldata userOp, address entryPointAddr) public view returns (bytes32) {
        return keccak256(abi.encode(userOp.hash(), entryPointAddr, block.chainid));
    }
}
