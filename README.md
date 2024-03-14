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

| Contract                         | Address                                    | Note                          |
| -------------------------------- | ------------------------------------------ | ----------------------------- |
| EntryPoint                       | 0x5FbDB2315678afecb367f032d93F642f64180aa3 |                               |
| SimpleAccountFactory             | 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 |                               |
| SimpleAccount                    | 0x9d2bcde83261a7fa850b6b24fd6a9a81e9599d25 | Balance: 100 ether            |
| Counter                          | 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9 |                               |
| PasskeyAccountFactory            | 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707 |                               |
| PasskeyAccount                   | **_Depending on PASSKEY env variables_**   | Balance: 100 ether            |
| VerifyingPaymaster               | 0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6 | EntryPoint deposit: 100 ether |
| imAccount Implementation         | 0x610178dA211FEF7D417bC0e6FeD39F05609AD788 |                               |
| ECDSAValidator                   | 0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e |     
| WebAuthnValidator                   | 0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE |                              |
| FallbackHandler                  | 0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0 |                               |
| imAccountFactory                 | 0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82 |                               |
| imAccountProxy (Wallet Contract) | 0xedf78a47be65e9206064e3f99902a969ff58ee93 | Balance: 100 ether            |

> If you use default passkey, the PasskeyAccount address would be `0x0117c0f95ab2d5473f7bbf51cce922353d822905`.

The owner of these contracts is `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`, which is the first address derived from testing mnemonic `test test test test test test test test test test test junk`, and it has unlimited balance of ether.

> Please make sure the contracts in the submodules(`lib`) are added into `src/Artifacts.sol` for being compiled.

Clean resources for testnet:

```bash
make testnet-down
```

## Local Contract Testing

```
$ forge test
```