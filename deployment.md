## 1. Deploy and verify PasskeyAccount

### Deploy PasskeyAccountFactory contract

- Edit the `.env.deployment` file by copying from `.env.deployment.example` and then run the following command.

```shell
source .env.deployment

PASSKEY_ACCOUNT_FACTORY_ADDRESS=$(forge create --rpc-url ${NODE_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --use ${COMPILER_VERSION} "src/0.6/account/PasskeyAccountFactory.sol:PasskeyAccountFactory" --constructor-args ${ENTRYPOINT_ADDRESS} | sed -nr 's/^Deployed to: (0x[0-9a-zA-Z]{40})[.]*$/\1/p')
```

### Verify PasskeyAccountFactory contract

```shell
forge verify-contract --watch --chain ${CHAIN_ID} --verifier "etherscan" --etherscan-api-key ${ETHERSCAN_API_KEY} --compiler-version ${COMPILER_VERSION} --constructor-args $(cast abi-encode "constructor(address)" ${ENTRYPOINT_ADDRESS}) ${PASSKEY_ACCOUNT_FACTORY_ADDRESS} "src/0.6/account/PasskeyAccountFactory.sol:PasskeyAccountFactory"
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
PASSKEY_ACCOUNT_IMPLEMENTATION_ADDRESS=$(cast call --rpc-url ${NODE_RPC_URL} ${PASSKEY_ACCOUNT_FACTORY_ADDRESS} "accountImplementation()" | sed -r 's/^[.]*(0x)([0]{24})?([0-9a-zA-Z]{40})[.]*$/\1\3/g')

P256_VERIFIER_ADDRESS=$(cast call --rpc-url ${NODE_RPC_URL} ${PASSKEY_ACCOUNT_FACTORY_ADDRESS} "p256Verifier()" | sed -r 's/^[.]*(0x)([0]{24})?([0-9a-zA-Z]{40})[.]*$/\1\3/g')

forge verify-contract --watch --chain ${CHAIN_ID} --verifier "etherscan" --etherscan-api-key ${ETHERSCAN_API_KEY} --compiler-version ${COMPILER_VERSION} --constructor-args $(cast abi-encode "constructor(address,address)" ${ENTRYPOINT_ADDRESS} ${P256_VERIFIER_ADDRESS}) ${PASSKEY_ACCOUNT_IMPLEMENTATION_ADDRESS} "src/0.6/account/PasskeyAccount.sol:PasskeyAccount"
```

### Deploy PasskeyAccount contract via PasskeyAccountFactory

```shell
cast send --rpc-url ${NODE_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} ${PASSKEY_ACCOUNT_FACTORY_ADDRESS} "createAccount(string calldata credId,uint256 pubKeyX,uint256 pubKeyY,uint256 salt)" ${PASSKEY_CREDENTIAL_ID} ${PASSKEY_X} ${PASSKEY_Y} ${SALT}
```

### Verify PasskeyAccount contract

- 1. Run the command below.

```shell
PASSKEY_ACCOUNT_ADDRESS=$(cast call --rpc-url ${NODE_RPC_URL} ${PASSKEY_ACCOUNT_FACTORY_ADDRESS} "getAddress(string calldata credId,uint256 pubKeyX,uint256 pubKeyY,uint256 salt)" ${PASSKEY_CREDENTIAL_ID} ${PASSKEY_X} ${PASSKEY_Y} ${SALT} | sed -r 's/^[.]*(0x)([0]{24})?([0-9a-zA-Z]{40})[.]*$/\1\3/g')

echo "Verification contract: ${PASSKEY_ACCOUNT_ADDRESS}" && echo "Implementation contract: ${PASSKEY_ACCOUNT_IMPLEMENTATION_ADDRESS}"
```

- 2. Copy the displayed verification contract address and visit the contract page on Etherscan; Here is a sample link:: [https://sepolia.etherscan.io/address/0x5c5d3afdaafdfb4ad974a28eda9bbf4c91c043a6#code](https://sepolia.etherscan.io/address/0x5c5d3afdaafdfb4ad974a28eda9bbf4c91c043a6#code).

```shell
Verification contract: 0x5c5d3afdaafdfb4ad974a28eda9bbf4c91c043a6
Implementation contract: 0xb22adc80082e3ad52b64138f5677c9f5f46dad1c
```

- 3. Click `Is this a proxy?` and `Verify`. Ensure the displayed implementation contract matches the sample output. Click `Save` to complete PasskeyAccount verification.

- 4. If necessary, you can also verify PasskeyAccount (ERC1967Proxy) contract.

```shell
forge verify-contract --watch --chain ${CHAIN_ID} --verifier "etherscan" --etherscan-api-key ${ETHERSCAN_API_KEY} --compiler-version ${COMPILER_VERSION} --constructor-args $(cast abi-encode "constructor(address,bytes)" ${PASSKEY_ACCOUNT_IMPLEMENTATION_ADDRESS} $(cast calldata "initialize(string,uint256,uint256)" ${PASSKEY_CREDENTIAL_ID} ${PASSKEY_X} ${PASSKEY_Y})) ${PASSKEY_ACCOUNT_ADDRESS} "lib/0.6/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy"
```

## 2. Deploy and verify SimpleAccount

### Deploy SimpleAccountFactory contract

- Edit the `.env.deployment` file by copying from `.env.deployment.example` and then run the following command.

```shell
source .env.deployment

SIMPLE_ACCOUNT_FACTORY_ADDRESS=$(forge create --rpc-url ${NODE_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --use ${COMPILER_VERSION} "lib/0.6/account-abstraction/contracts/samples/SimpleAccountFactory.sol:SimpleAccountFactory" --constructor-args ${ENTRYPOINT_ADDRESS} | sed -nr 's/^Deployed to: (0x[0-9a-zA-Z]{40})[.]*$/\1/p')
```

### Verify SimpleAccountFactory contract

```shell
forge verify-contract --watch --chain ${CHAIN_ID} --verifier "etherscan" --etherscan-api-key ${ETHERSCAN_API_KEY} --compiler-version ${COMPILER_VERSION} --constructor-args $(cast abi-encode "constructor(address)" ${ENTRYPOINT_ADDRESS}) ${SIMPLE_ACCOUNT_FACTORY_ADDRESS} "lib/0.6/account-abstraction/contracts/samples/SimpleAccountFactory.sol:SimpleAccountFactory"
```

### Verify SimpleAccount implementation contract

```shell
SIMPLE_ACCOUNT_IMPLEMENTATION_ADDRESS=$(cast call --rpc-url ${NODE_RPC_URL} ${SIMPLE_ACCOUNT_FACTORY_ADDRESS} "accountImplementation()" | sed -r 's/^[.]*(0x)([0]{24})?([0-9a-zA-Z]{40})[.]*$/\1\3/g')

forge verify-contract --watch --chain ${CHAIN_ID} --verifier "etherscan" --etherscan-api-key ${ETHERSCAN_API_KEY} --compiler-version ${COMPILER_VERSION} --constructor-args $(cast abi-encode "constructor(address)" ${ENTRYPOINT_ADDRESS}) ${SIMPLE_ACCOUNT_IMPLEMENTATION_ADDRESS} "lib/0.6/account-abstraction/contracts/samples/SimpleAccount.sol:SimpleAccount"
```

### Deploy SimpleAccount contract via SimpleAccountFactory

```shell
cast send --rpc-url ${NODE_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} ${SIMPLE_ACCOUNT_FACTORY_ADDRESS} "createAccount(address owner,uint256 salt)" ${SIMPLE_ACCOUNT_OWNER_ADDRESS} ${SALT}
```

### Verify SimpleAccount contract

- 1. Run the command below.

```shell
SIMPLE_ACCOUNT_ADDRESS=$(cast call --rpc-url ${NODE_RPC_URL} ${SIMPLE_ACCOUNT_FACTORY_ADDRESS} "getAddress(address owner,uint256 salt)" ${SIMPLE_ACCOUNT_OWNER_ADDRESS} ${SALT} | sed -r 's/^[.]*(0x)([0]{24})?([0-9a-zA-Z]{40})[.]*$/\1\3/g')

echo "Verification contract: ${SIMPLE_ACCOUNT_ADDRESS}" && echo "Implementation contract: ${SIMPLE_ACCOUNT_IMPLEMENTATION_ADDRESS}"
```

- 2. Copy the displayed verification contract address and visit the contract page on Etherscan.

- 3. Click `Is this a proxy?` and `Verify`. Ensure the displayed implementation contract matches the sample output. Click `Save` to complete SimpleAccount verification.

- 4. If necessary, you can also verify SimpleAccount (ERC1967Proxy) contract.

```shell
forge verify-contract --watch --chain ${CHAIN_ID} --verifier "etherscan" --etherscan-api-key ${ETHERSCAN_API_KEY} --compiler-version ${COMPILER_VERSION} --constructor-args $(cast abi-encode "constructor(address,bytes)" ${SIMPLE_ACCOUNT_IMPLEMENTATION_ADDRESS} $(cast calldata "initialize(address)" ${SIMPLE_ACCOUNT_OWNER_ADDRESS})) ${SIMPLE_ACCOUNT_ADDRESS} "lib/0.6/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy"
```

## 3. Deploy and verify VerifyingPaymaster

### Deploy VerifyingPaymaster contract

- Edit the `.env.deployment` file by copying from `.env.deployment.example` and then run the following command.

```shell
source .env.deployment

VERIFYING_PAYMASTER_ADDRESS=$(forge create --rpc-url ${NODE_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --use ${COMPILER_VERSION} "lib/0.6/account-abstraction/contracts/samples/VerifyingPaymaster.sol:VerifyingPaymaster" --constructor-args ${ENTRYPOINT_ADDRESS} ${VERIFYING_PAYMASTER_OWNER_ADDRESS} | sed -nr 's/^Deployed to: (0x[0-9a-zA-Z]{40})[.]*$/\1/p')
```

### Verify VerifyingPaymaster contract

```shell
forge verify-contract --watch --chain ${CHAIN_ID} --verifier "etherscan" --etherscan-api-key ${ETHERSCAN_API_KEY} --compiler-version ${COMPILER_VERSION} --constructor-args $(cast abi-encode "constructor(address,address)" ${ENTRYPOINT_ADDRESS} ${VERIFYING_PAYMASTER_OWNER_ADDRESS}) ${VERIFYING_PAYMASTER_ADDRESS} "lib/0.6/account-abstraction/contracts/samples/VerifyingPaymaster.sol:VerifyingPaymaster"
```

### Deposit to EntryPoint for VerifyingPaymaster

```shell
VALUE=0.1ether

# Deposit for VerifyingPaymaster
cast send --rpc-url ${NODE_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} ${ENTRYPOINT_ADDRESS} --value ${VALUE} "depositTo(address account)" ${VERIFYING_PAYMASTER_ADDRESS}

# Check VerifyingPaymaster deposit amount.
cast from-wei $(cast to-dec $(cast call --rpc-url ${NODE_RPC_URL} ${ENTRYPOINT_ADDRESS} "balanceOf(address account)" ${VERIFYING_PAYMASTER_ADDRESS}))
```
