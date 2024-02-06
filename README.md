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

## Appendix 1: Deploy and verify PasskeyAccount

### Deploy PasskeyAccountFactory contract

- Edit the `.env.deployment` file by copying from `.env.deployment.example` and then run the following command.

```shell
source .env.deployment

forge create --rpc-url ${NODE_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --use ${COMPILER_VERSION} "src/account/PasskeyAccountFactory.sol:PasskeyAccountFactory" --constructor-args ${ENTRYPOINT_ADDRESS}
```

- Output sample

```shell
[⠒] Compiling...
No files changed, compilation skipped
Compiler run successful!
Deployer: 0x982A41a1F3bC1F8bdB71F11751F3a71691794AfA
Deployed to: 0x4d21849008fa59F36971A2611746F080b9B79220
Transaction hash: 0x7a6d29b281aaef31e5d7ae5080b8800614f4f053b63fbb83a0d870807197b252
```

### Verify PasskeyAccountFactory contract

- Replace `<YOUR_PASSKEY_ACCOUNT_FACTORY_ADDRESS>` with your deployed PasskeyAccountFactory address (e.g., 0x4d21849008fa59F36971A2611746F080b9B79220).

```shell
PASSKEY_ACCOUNT_FACTORY_ADDRESS="<YOUR_PASSKEY_ACCOUNT_FACTORY_ADDRESS>"

forge verify-contract --watch --chain ${NETWORK_NAME} --verifier "etherscan" --etherscan-api-key ${ETHERSCAN_API_KEY} --compiler-version ${COMPILER_VERSION} --constructor-args $(cast abi-encode "constructor(address)" ${ENTRYPOINT_ADDRESS}) ${PASSKEY_ACCOUNT_FACTORY_ADDRESS} "src/account/PasskeyAccountFactory.sol:PasskeyAccountFactory"
```

- Output sample

```shell
Start verifying contract `0x4d21849008fa59F36971A2611746F080b9B79220` deployed on sepolia

Submitting verification for [src/account/PasskeyAccountFactory.sol:PasskeyAccountFactory] 0x4d21849008fa59F36971A2611746F080b9B79220.
Submitted contract for verification:
        Response: `OK`
        GUID: `tqw8mnuhqwuigkkp9vwzgu89qespbkma6umeszbmjlvcjmvj1i`
        URL: https://sepolia.etherscan.io/address/0x4d21849008fa59f36971a2611746f080b9b79220
Contract verification status:
Response: `OK`
Details: `Pass - Verified`
Contract successfully verified
```

### Verify PasskeyAccount implementation contract

```shell
PASSKEY_ACCOUNT_IMPLEMENTATION_ADDRESS=$(cast call --rpc-url ${NODE_RPC_URL} ${PASSKEY_ACCOUNT_FACTORY_ADDRESS} "accountImplementation()" | sed -r 's/^[.]*(0x)([0]{24})?([0-9a-zA-Z]{40})[.]*$/\1\3/g') && echo ${PASSKEY_ACCOUNT_IMPLEMENTATION_ADDRESS}

P256_VERIFIER_ADDRESS=$(cast call --rpc-url ${NODE_RPC_URL} ${PASSKEY_ACCOUNT_FACTORY_ADDRESS} "p256Verifier()" | sed -r 's/^[.]*(0x)([0]{24})?([0-9a-zA-Z]{40})[.]*$/\1\3/g') && echo ${P256_VERIFIER_ADDRESS}

forge verify-contract --watch --chain ${NETWORK_NAME} --verifier "etherscan" --etherscan-api-key ${ETHERSCAN_API_KEY} --compiler-version ${COMPILER_VERSION} --constructor-args $(cast abi-encode "constructor(address,address)" ${ENTRYPOINT_ADDRESS} ${P256_VERIFIER_ADDRESS}) ${PASSKEY_ACCOUNT_IMPLEMENTATION_ADDRESS} "src/account/PasskeyAccount.sol:PasskeyAccount"
```

### Deploy PasskeyAccount contract via PasskeyAccountFactory

```shell
cast send --rpc-url ${NODE_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} ${PASSKEY_ACCOUNT_FACTORY_ADDRESS} "createAccount(string calldata credId,uint256 pubKeyX,uint256 pubKeyY,uint256 salt)" ${PASSKEY_CREDENTIAL_ID} ${PASSKEY_X} ${PASSKEY_Y} ${SALT}
```

### Verify PasskeyAccount contract

- 1. Run the command below.

```shell
PASSKEY_ACCOUNT_ADDRESS=$(cast call --rpc-url ${NODE_RPC_URL} ${PASSKEY_ACCOUNT_FACTORY_ADDRESS} "getAddress(string calldata credId,uint256 pubKeyX,uint256 pubKeyY,uint256 salt)" ${PASSKEY_CREDENTIAL_ID} ${PASSKEY_X} ${PASSKEY_Y} ${SALT} | sed -r 's/^[.]*(0x)([0]{24})?([0-9a-zA-Z]{40})[.]*$/\1\3/g') && echo ${PASSKEY_ACCOUNT_ADDRESS}

echo "Verification link: https://${NETWORK_NAME}.etherscan.io/address/${PASSKEY_ACCOUNT_ADDRESS}#code" && echo "Implementation contract: ${PASSKEY_ACCOUNT_IMPLEMENTATION_ADDRESS}"
```

- 2. Open the displayed verification link; here is a sample output.

```shell
Verification link: https://sepolia.etherscan.io/address/0x5c5d3afdaafdfb4ad974a28eda9bbf4c91c043a6#code
Implementation contract: 0xb22adc80082e3ad52b64138f5677c9f5f46dad1c
```

- 3. Click `Is this a proxy?` and `Verify`. Ensure the displayed implementation contract matches the sample output. Click `Save` to complete PasskeyAccount verification.

- 4. If necessary, you can also verify PasskeyAccount (ERC1967Proxy) contract.

```shell
forge verify-contract --watch --chain ${NETWORK_NAME} --verifier "etherscan" --etherscan-api-key ${ETHERSCAN_API_KEY} --compiler-version ${COMPILER_VERSION} --constructor-args $(cast abi-encode "constructor(address,bytes)" ${PASSKEY_ACCOUNT_IMPLEMENTATION_ADDRESS} $(cast calldata "initialize(string,uint256,uint256)" ${PASSKEY_CREDENTIAL_ID} ${PASSKEY_X} ${PASSKEY_Y})) ${PASSKEY_ACCOUNT_ADDRESS} "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy"
```

## Appendix 2: Deploy and verify SimpleAccount

### Deploy SimpleAccountFactory contract

- Edit the `.env.deployment` file by copying from `.env.deployment.example` and then run the following command.

```shell
source .env.deployment

forge create --rpc-url ${NODE_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --use ${COMPILER_VERSION} "lib/account-abstraction/contracts/samples/SimpleAccountFactory.sol:SimpleAccountFactory" --constructor-args ${ENTRYPOINT_ADDRESS}
```

### Verify SimpleAccountFactory contract

- Replace `<YOUR_SIMPLE_ACCOUNT_FACTORY_ADDRESS>` with your deployed SimpleAccountFactory address.

```shell
SIMPLE_ACCOUNT_FACTORY_ADDRESS="<YOUR_SIMPLE_ACCOUNT_FACTORY_ADDRESS>"

forge verify-contract --watch --chain ${NETWORK_NAME} --verifier "etherscan" --etherscan-api-key ${ETHERSCAN_API_KEY} --compiler-version ${COMPILER_VERSION} --constructor-args $(cast abi-encode "constructor(address)" ${ENTRYPOINT_ADDRESS}) ${SIMPLE_ACCOUNT_FACTORY_ADDRESS} "lib/account-abstraction/contracts/samples/SimpleAccountFactory.sol:SimpleAccountFactory"
```

### Verify SimpleAccount implementation contract

```shell
SIMPLE_ACCOUNT_IMPLEMENTATION_ADDRESS=$(cast call --rpc-url ${NODE_RPC_URL} ${SIMPLE_ACCOUNT_FACTORY_ADDRESS} "accountImplementation()" | sed -r 's/^[.]*(0x)([0]{24})?([0-9a-zA-Z]{40})[.]*$/\1\3/g') && echo ${SIMPLE_ACCOUNT_IMPLEMENTATION_ADDRESS}

forge verify-contract --watch --chain ${NETWORK_NAME} --verifier "etherscan" --etherscan-api-key ${ETHERSCAN_API_KEY} --compiler-version ${COMPILER_VERSION} --constructor-args $(cast abi-encode "constructor(address)" ${ENTRYPOINT_ADDRESS}) ${SIMPLE_ACCOUNT_IMPLEMENTATION_ADDRESS} "lib/account-abstraction/contracts/samples/SimpleAccount.sol:SimpleAccount"
```

### Deploy SimpleAccount contract via SimpleAccountFactory

```shell
cast send --rpc-url ${NODE_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} ${SIMPLE_ACCOUNT_FACTORY_ADDRESS} "createAccount(address owner,uint256 salt)" ${SIMPLE_ACCOUNT_OWNER_ADDRESS} ${SALT}
```

### Verify SimpleAccount contract

- 1. Run the command below.

```shell
SIMPLE_ACCOUNT_ADDRESS=$(cast call --rpc-url ${NODE_RPC_URL} ${SIMPLE_ACCOUNT_FACTORY_ADDRESS} "getAddress(address owner,uint256 salt)" ${SIMPLE_ACCOUNT_OWNER_ADDRESS} ${SALT} | sed -r 's/^[.]*(0x)([0]{24})?([0-9a-zA-Z]{40})[.]*$/\1\3/g') && echo ${SIMPLE_ACCOUNT_ADDRESS}

echo "Verification link: https://${NETWORK_NAME}.etherscan.io/address/${SIMPLE_ACCOUNT_ADDRESS}#code" && echo "Implementation contract: ${SIMPLE_ACCOUNT_IMPLEMENTATION_ADDRESS}"
```

- 2. Open the displayed verification link

- 3. Click `Is this a proxy?` and `Verify`. Ensure the displayed implementation contract matches the sample output. Click `Save` to complete SimpleAccount verification.

- 4. If necessary, you can also verify SimpleAccount (ERC1967Proxy) contract.

```shell
forge verify-contract --watch --chain ${NETWORK_NAME} --verifier "etherscan" --etherscan-api-key ${ETHERSCAN_API_KEY} --compiler-version ${COMPILER_VERSION} --constructor-args $(cast abi-encode "constructor(address,bytes)" ${SIMPLE_ACCOUNT_IMPLEMENTATION_ADDRESS} $(cast calldata "initialize(address)" ${SIMPLE_ACCOUNT_OWNER_ADDRESS})) ${SIMPLE_ACCOUNT_ADDRESS} "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy"
```
