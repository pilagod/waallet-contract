// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Create2 } from "@openzeppelin4/contracts/utils/Create2.sol";
import { ERC1967Proxy } from
    "@openzeppelin4/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IEntryPoint } from "@aa6/interfaces/IEntryPoint.sol";
import { PasskeyAccount } from "./PasskeyAccount.sol";
import { P256_VERIFIER_CREATION_CODE } from "../utils/P256Constants.sol";

/* solhint-disable no-inline-assembly */

/**
 * Based on SimpleAccountFactory.
 * Cannot be a subclass since both constructor and createAccount depend on the
 * constructor and initializer of the actual account contract.
 */
contract PasskeyAccountFactory {
    address public immutable p256Verifier;
    PasskeyAccount public immutable accountImplementation;
    IEntryPoint public entryPoint;

    constructor(IEntryPoint _entryPoint) {
        entryPoint = _entryPoint;
        p256Verifier =
            Create2.deploy(0, bytes32(0), P256_VERIFIER_CREATION_CODE);
        accountImplementation = new PasskeyAccount(_entryPoint, p256Verifier);
    }

    /**
     * create an account, and return its address.
     * returns the address even if the account is already deployed.
     * Note that during UserOperation execution, this method is called only if the account is not deployed.
     * This method returns an existing account address so that entryPoint.getSenderAddress() would work even after account creation
     */
    function createAccount(
        string calldata credId,
        uint256 pubKeyX,
        uint256 pubKeyY,
        uint256 salt
    ) external returns (PasskeyAccount) {
        address addr = getAddress(credId, pubKeyX, pubKeyY, salt);
        uint256 codeSize = addr.code.length;
        if (codeSize > 0) {
            return PasskeyAccount(payable(addr));
        }
        return PasskeyAccount(
            payable(
                new ERC1967Proxy{ salt: bytes32(salt) }(
                    address(accountImplementation),
                    abi.encodeCall(
                        PasskeyAccount.initialize, (credId, pubKeyX, pubKeyY)
                    )
                )
            )
        );
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     */
    function getAddress(
        string calldata credId,
        uint256 pubKeyX,
        uint256 pubKeyY,
        uint256 salt
    ) public view returns (address) {
        return Create2.computeAddress(
            bytes32(salt),
            keccak256(
                abi.encodePacked(
                    type(ERC1967Proxy).creationCode,
                    abi.encode(
                        address(accountImplementation),
                        abi.encodeCall(
                            PasskeyAccount.initialize,
                            (credId, pubKeyX, pubKeyY)
                        )
                    )
                )
            )
        );
    }
}
