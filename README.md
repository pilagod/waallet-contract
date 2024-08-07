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

#### Periphery contracts

| Contract   | Address                                    |
| ---------- | ------------------------------------------ |
| Counter    | 0x8464135c8F25Da09e49BC8782676a84730C318bC |
| Test Token | 0x71C95911E9a5D330f4D621842EC243EE1343292e |

#### Account abstraction v0.6.0 contracts

| Contract              | Address                                    | Note                        |
| --------------------- | ------------------------------------------ | --------------------------- |
| EntryPoint            | 0x663F3ad617193148711d28f5334eE4Ed07016602 |                             |
| SimpleAccountFactory  | 0x2E983A1Ba5e8b38AAAeC4B440B9dDcFBf72E15d1 |                             |
| SimpleAccount         | 0x7Fa35750bF7e98891019460b0B3194bE27E86859 | Balance: 100 ETH, 100 TEST  |
| PasskeyAccountFactory | 0xBC9129Dc0487fc2E169941C75aABC539f208fb01 |                             |
| PasskeyAccount        | **_Depends on PASSKEY env variables_**     | Balance: 100 ETH, 100 TEST  |
| VerifyingPaymaster    | 0xF6168876932289D073567f347121A267095f3DD6 | EntryPoint deposit: 100 ETH |

> If you use default passkey, the PasskeyAccount address would be `0x62c45C04e3Be191E88836852dAFF7B6CE8e6aCF9`.

#### Account abstraction v0.7.0 contracts

| Contract              | Address                                    | Note                        |
| --------------------- | ------------------------------------------ | --------------------------- |
| EntryPoint            | 0x057ef64E23666F000b34aE31332854aCBd1c8544 |                             |
| SimpleAccountFactory  | 0x261D8c5e9742e6f7f1076Fa1F560894524e19cad |                             |
| SimpleAccount         | 0xD0dA07666BA2139aa6fF7A450A8596291a6cE471 | Balance: 100 ETH, 100 TEST  |
| PasskeyAccountFactory | 0xCba6b9A951749B8735C603e7fFC5151849248772 |                             |
| PasskeyAccount        | **_Depends on PASSKEY env variables_**     | Balance: 100 ETH, 100 TEST  |
| VerifyingPaymaster    | 0xcf27F781841484d5CF7e155b44954D7224caF1dD | EntryPoint deposit: 100 ETH |

> If you use default passkey, the PasskeyAccount address would be `0xa83e7ae8d81F8F5EBa94dfB45b836bdb4785bfC2`.

> [!NOTE]
> These contracts are mainly owned by `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`.

For management purpose, we use deployer 1 (`0x70997970C51812dc3A010C7d01b50e0d17dc79C8`) to deploy [periphery contracts](#periphery-contracts). Deployer 2 (`0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC`) deploys [account abstraction v0.6.0 contracts](#account-abstraction-v060-contracts). Deployer 3 (`0x90F79bf6EB2c4f870365E785982E1f101E93b906`) deploys [account abstraction v0.7.0 contracts](#account-abstraction-v070-contracts). Contract owner and deployers are derived from the first four addresses of the mnemonic `test test test test test test test test test test test junk`, and the owner (`0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`) has unlimited balance of ether.

> Please make sure the contracts in the submodules(`lib`) are added into `src/artifacts/{0.6,0.7}/Artifacts.sol` for being compiled.

Clean resources for testnet:

```bash
make testnet-down
```

## Local Contract Testing

```
$ forge test
```
