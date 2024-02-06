# Waallet Contract

## Setup

### Setup `.env.testnet`

Copy from `.env.testnet.example` and fill the fields:

```bash
cp .env.testnet.example .env.testnet
```

If you leave fields empty, it will use following values as default (which is the passkey under `test/keystore`):

```env
PASSKEY_CREDENTIAL_ID="9h5F3DgLSjSMdnVOadmhCw"
PASSKEY_X=67299174900712686363169673082376821529726602378544032702281553676098545184711
PASSKEY_Y=104273800132786176334597151467609377740095818152192999025225464410568038480397
```

### Run testnet

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
| PasskeyAccount        | **_Depending on PASSKEY env variables_**   | Balance: 100 ether            |
| VerifyingPaymaster    | 0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6 | EntryPoint deposit: 100 ether |

> If you use default passkey, the PasskeyAccount address would be `0xf30a89a6a3836e2b270650822e3f3cebff3b7497`.

The owner of these contracts is `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`, which is the first address derived from testing mnemonic `test test test test test test test test test test test junk`, and it has unlimited balance of ether.

Clean resources for testnet:

```bash
make testnet-down
```
