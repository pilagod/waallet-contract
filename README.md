# Waallet Contract

## Setup

### Setup Foundry packages

```
$ forge install
```

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

- Deployer 1: Non-account abstraction contracts

| Contract | Address                                    |
| -------- | ------------------------------------------ |
| Counter  | 0x8464135c8F25Da09e49BC8782676a84730C318bC |

- Deployer 2: Account abstraction v0.6.0 contracts

| Contract              | Address                                    | Note                        |
| --------------------- | ------------------------------------------ | --------------------------- |
| EntryPoint            | 0x663F3ad617193148711d28f5334eE4Ed07016602 |                             |
| SimpleAccountFactory  | 0x2E983A1Ba5e8b38AAAeC4B440B9dDcFBf72E15d1 |                             |
| SimpleAccount         | 0x9ad6228ca7382ab770c8bb25aa55c4fe503605bc | Balance: 100 ETH            |
| PasskeyAccountFactory | 0xBC9129Dc0487fc2E169941C75aABC539f208fb01 |                             |
| PasskeyAccount        | **_Depends on PASSKEY env variables_**     | Balance: 100 ETH            |
| VerifyingPaymaster    | 0xF6168876932289D073567f347121A267095f3DD6 | EntryPoint deposit: 100 ETH |

> If you use default passkey, the PasskeyAccount address would be `0x054dab9bd2bc70133aa58ae953967ec4765eee4f`.

These contracts are mainly owned by `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`. For easier management, deployer 1 (`0x70997970C51812dc3A010C7d01b50e0d17dc79C8`) handles Counter and non-account abstraction contracts. Deployer 2 (`0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC`) handles account abstraction v0.6.0 contracts. Deployer 3 (`0x90F79bf6EB2c4f870365E785982E1f101E93b906`) handles account abstraction v0.7.0 contracts. Owner and deployers are the first four addresses from the mnemonic `test test test test test test test test test test test junk`, and the first address has unlimited balance of ether.

> Please make sure the contracts in the submodules(`lib`) are added into `src/artifacts/0.6/Artifacts.sol` or `src/artifacts/0.6/Artifacts.sol` for being compiled.

Clean resources for testnet:

```bash
make testnet-down
```

## Local Contract Testing

```
$ forge test
```
