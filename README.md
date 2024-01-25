# Waallet Contract

## Setup

Run testnet:

```bash
make testnet-up
```

This testnet has following pre-deployed contracts:

| Contract              | Address                                    | Note                          |
| --------------------- | ------------------------------------------ | ----------------------------- |
| EntryPoint            | 0x5FbDB2315678afecb367f032d93F642f64180aa3 |                               |
| SimpleAccountFactory  | 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 |                               |
| SimpleAccount         | 0x661b4a3909b486a3da520403ecc78f7a7b683c63 | Balance: 100 ether            |
| Counter               | 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9 |                               |
| PasskeyAccountFactory | 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707 |                               |
| PasskeyAccount        | 0xf30a89a6a3836e2b270650822e3f3cebff3b7497 | Balance: 100 ether            |
| VerifyingPaymaster    | 0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6 | EntryPoint deposit: 100 ether |

The owner of these contracts is `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`, which is the first address derived from testing mnemonic `test test test test test test test test test test test junk`, and it has unlimited balance of ether.

Clean resources for testnet:

```bash
make testnet-down
```

## Appendix: Deploy and verify PasskeyAccountFactory on Sepolia testnet

### Deploy PasskeyAccountFactory contract

- Edit [.env](.env.example) and run the following command.

```shell
source .env

forge create --rpc-url ${NODE_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --use "0.8.23" "src/account/PasskeyAccountFactory.sol:PasskeyAccountFactory" --constructor-args ${ENTRYPOINT_ADDRESS}
```

- Output sample

```shell
[⠒] Compiling...
[⠢] Compiling 4 files with 0.8.23
[⠆] Solc 0.8.23 finished in 2.04s
Compiler run successful!
Deployer: 0x982A41a1F3bC1F8bdB71F11751F3a71691794AfA
Deployed to: 0x4F0e62B7294D26b223a2cffc02BE5D072528c0De
Transaction hash: 0xcf3c71f9b71fff6f7f45dbc3a512db667e10ab6eb272a700dfe1ab32aef0958c
```

### Verify PasskeyAccountFactory contract

- Replace `<YOUR_PASSKEY_ACCOUNT_FACTORY_ADDRESS>` with your deployed PasskeyAccountFactory address.

```shell
forge verify-contract --watch --chain "sepolia" --verifier "etherscan" --etherscan-api-key ${ETHERSCAN_API_KEY} --compiler-version "0.8.23" --constructor-args $(cast abi-encode "constructor(address)" ${ENTRYPOINT_ADDRESS}) "<YOUR_PASSKEY_ACCOUNT_FACTORY_ADDRESS>" "src/account/PasskeyAccountFactory.sol:PasskeyAccountFactory"
```

- Output sample

```shell
Start verifying contract `0x4F0e62B7294D26b223a2cffc02BE5D072528c0De` deployed on sepolia

Submitting verification for [src/account/PasskeyAccountFactory.sol:PasskeyAccountFactory] 0x4F0e62B7294D26b223a2cffc02BE5D072528c0De.
Submitted contract for verification:
        Response: `OK`
        GUID: `u27yc7avgdwdce827ptgvhwtbat1daqzrwh362xp2zganicbrw`
        URL:
        https://sepolia.etherscan.io/address/0x4f0e62b7294d26b223a2cffc02be5d072528c0de
Contract verification status:
Response: `NOTOK`
Details: `Pending in queue`
Contract verification status:
Response: `OK`
Details: `Pass - Verified`
Contract successfully verified
```
