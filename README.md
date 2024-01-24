# Waallet Contract

## Setup

Run testnet:

```bash
make testnet-up
```

This testnet has following pre-deployed contracts:

| Contract              | Address                                    | Note               |
| --------------------- | ------------------------------------------ | ------------------ |
| EntryPoint            | 0x5FbDB2315678afecb367f032d93F642f64180aa3 |                    |
| SimpleAccountFactory  | 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 |                    |
| SimpleAccount         | 0x1cee485cc83c5a17692904ff441a115fb223788e | Balance: 100 ether |
| Counter               | 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9 |                    |
| PasskeyAccountFactory | 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707 |                    |
| PasskeyAccount        | 0x3c93bc637f7630b2d4ad51f4a02b786e81ff1498 | Balance: 100 ether |
| VerifyingPaymaster    | 0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6 |                    |

The owner of these contracts is `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`, which is the first address derived from testing mnemonic `test test test test test test test test test test test junk`, and it has unlimited balance of ether.

Clean resources for testnet:

```bash
make testnet-down
```
