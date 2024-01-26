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

## Appendix: Deploy and verify PasskeyAccount on Sepolia testnet

### Deploy and verify PasskeyAccountFactory contract

- Edit the `.env.deployment` file by copying from `.env.deployment.example` and then run the following command.

```shell
source .env.deployment

forge create --rpc-url ${NODE_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} --use "0.8.23" "src/account/PasskeyAccountFactory.sol:PasskeyAccountFactory" --constructor-args ${ENTRYPOINT_ADDRESS}
```

- Output sample

```shell
[⠢] Compiling...
[⠘] Compiling 68 files with 0.8.23
[⠆] Solc 0.8.23 finished in 5.73s
Compiler run successful!
Deployer: 0x982A41a1F3bC1F8bdB71F11751F3a71691794AfA
Deployed to: 0x4d21849008fa59F36971A2611746F080b9B79220
Transaction hash: 0x7a6d29b281aaef31e5d7ae5080b8800614f4f053b63fbb83a0d870807197b252
```

### Verify PasskeyAccountFactory contract

- Replace `<YOUR_PASSKEY_ACCOUNT_FACTORY_ADDRESS>` with your deployed PasskeyAccountFactory address.

```shell
PASSKEY_ACCOUNT_FACTORY_ADDRESS="<YOUR_PASSKEY_ACCOUNT_FACTORY_ADDRESS>"

forge verify-contract --watch --chain "sepolia" --verifier "etherscan" --etherscan-api-key ${ETHERSCAN_API_KEY} --compiler-version "0.8.23" --constructor-args $(cast abi-encode "constructor(address)" ${ENTRYPOINT_ADDRESS}) ${PASSKEY_ACCOUNT_FACTORY_ADDRESS} "src/account/PasskeyAccountFactory.sol:PasskeyAccountFactory"
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
Response: `NOTOK`
Details: `Pending in queue`
Contract verification status:
Response: `OK`
Details: `Pass - Verified`
Contract successfully verified
```

### Deploy PasskeyAccount contract via PasskeyAccountFactory

```shell
cast send --rpc-url ${NODE_RPC_URL} --private-key ${DEPLOYER_PRIVATE_KEY} ${PASSKEY_ACCOUNT_FACTORY_ADDRESS} "createAccount(string calldata credId,uint256 pubKeyX,uint256 pubKeyY,uint256 salt)" ${PASSKEY_CREDENTIAL_ID} ${PASSKEY_X} ${PASSKEY_Y} 0
```

- Output sample

```shell
blockHash               0x49414a3a6590fd28f6f466088075d4fde43d139bfe29200660fe370f9fed75a6
blockNumber             5150531
contractAddress
cumulativeGasUsed       4727525
effectiveGasPrice       18803770411
from                    0x982A41a1F3bC1F8bdB71F11751F3a71691794AfA
gasUsed                 226007
logs                    [{"address":"0x5c5d3afdaafdfb4ad974a28eda9bbf4c91c043a6","topics":["0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b","0x000000000000000000000000b22adc80082e3ad52b64138f5677c9f5f46dad1c"],"data":"0x","blockHash":"0x49414a3a6590fd28f6f466088075d4fde43d139bfe29200660fe370f9fed75a6","blockNumber":"0x4e9743","transactionHash":"0x7b2521dd386a75ca0d5f0620ac178fe2b698d9cd25286ee8ec65711c3347827a","transactionIndex":"0x2d","logIndex":"0x1f","removed":false},{"address":"0x5c5d3afdaafdfb4ad974a28eda9bbf4c91c043a6","topics":["0x47e55c76e7a6f1fd8996a1da8008c1ea29699cca35e7bcd057f2dec313b6e5de","0x0000000000000000000000005ff137d4b0fdcd49dca30c7cf57e578a026d2789","0x0000000000000000000000000000000000000000000000000000000000000000"],"data":"0x","blockHash":"0x49414a3a6590fd28f6f466088075d4fde43d139bfe29200660fe370f9fed75a6","blockNumber":"0x4e9743","transactionHash":"0x7b2521dd386a75ca0d5f0620ac178fe2b698d9cd25286ee8ec65711c3347827a","transactionIndex":"0x2d","logIndex":"0x20","removed":false},{"address":"0x5c5d3afdaafdfb4ad974a28eda9bbf4c91c043a6","topics":["0x8ae27faf4b95af921373662fd17ed711470868fc6877eb3371630f2d692042f6"],"data":"0x0000000000000000000000000000000000000000000000000000000000000060a6139ede645de64436d535c8ec410fd495d2425a3d7adb9eabd91550c04ea73afe20776883bab6df9d1da03448283192bf7b0ed641a6c5a03d419d27fd89b64b000000000000000000000000000000000000000000000000000000000000001b6c754b6c47673657704c37346a7063767635354d4e787a4c64476b0000000000","blockHash":"0x49414a3a6590fd28f6f466088075d4fde43d139bfe29200660fe370f9fed75a6","blockNumber":"0x4e9743","transactionHash":"0x7b2521dd386a75ca0d5f0620ac178fe2b698d9cd25286ee8ec65711c3347827a","transactionIndex":"0x2d","logIndex":"0x21","removed":false},{"address":"0x5c5d3afdaafdfb4ad974a28eda9bbf4c91c043a6","topics":["0x7f26b83ff96e1f2b6a682f133852f6798a09c465da95921460cefb3847402498"],"data":"0x0000000000000000000000000000000000000000000000000000000000000001","blockHash":"0x49414a3a6590fd28f6f466088075d4fde43d139bfe29200660fe370f9fed75a6","blockNumber":"0x4e9743","transactionHash":"0x7b2521dd386a75ca0d5f0620ac178fe2b698d9cd25286ee8ec65711c3347827a","transactionIndex":"0x2d","logIndex":"0x22","removed":false}]
logsBloom               0x0000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000008000000000000000001008000000000000000000000000000000000000000a0000000400000000000000000000000040000000000200000000000000000008000000000000000040008000000040000000000000000000000000000000000000000000000000800000000000000000000004000000000000000000000004000000000008000000000000020000000000000000200000000000000000000c0000000000000000000000000000000020000000000000100000000000000000000800000000000000000000000000000000
root
status                  1
transactionHash         0x7b2521dd386a75ca0d5f0620ac178fe2b698d9cd25286ee8ec65711c3347827a
transactionIndex        45
type                    2
to                      0x4d21…9220
```

### Verify PasskeyAccount implementation contract

```shell
PASSKEY_ACCOUNT_IMPLEMENTATION_ADDRESS=$(cast call --rpc-url ${NODE_RPC_URL} ${PASSKEY_ACCOUNT_FACTORY_ADDRESS} "accountImplementation()" | sed -r 's/^[.]*(0x)([0]{24})?([0-9a-zA-Z]{40})[.]*$/\1\3/g')

P256_VERIFIER_ADDRESS=$(cast call --rpc-url ${NODE_RPC_URL} ${PASSKEY_ACCOUNT_FACTORY_ADDRESS} "p256Verifier()" | sed -r 's/^[.]*(0x)([0]{24})?([0-9a-zA-Z]{40})[.]*$/\1\3/g')

forge verify-contract --watch --chain "sepolia" --verifier "etherscan" --etherscan-api-key ${ETHERSCAN_API_KEY} --compiler-version "0.8.23" --constructor-args $(cast abi-encode "constructor(address,address)" ${ENTRYPOINT_ADDRESS} ${P256_VERIFIER_ADDRESS}) ${PASSKEY_ACCOUNT_IMPLEMENTATION_ADDRESS} "src/account/PasskeyAccount.sol:PasskeyAccount"
```

- Output sample

```shell
Start verifying contract `0xB22ADc80082e3aD52b64138F5677c9F5F46DaD1c` deployed on sepolia

Submitting verification for [src/account/PasskeyAccount.sol:PasskeyAccount] 0xB22ADc80082e3aD52b64138F5677c9F5F46DaD1c.
Submitted contract for verification:
        Response: `OK`
        GUID: `3p1tajqx8lsq8vr2p6vkgsl4etaucn3saquaubtsrfjdu37mst`
        URL: https://sepolia.etherscan.io/address/0xb22adc80082e3ad52b64138f5677c9f5f46dad1c
Contract verification status:
Response: `NOTOK`
Details: `Pending in queue`
Contract verification status:
Response: `OK`
Details: `Pass - Verified`
Contract successfully verified
```

### Verify PasskeyAccount contract

- 1. Run the command below.

```shell
PASSKEY_ACCOUNT_ADDRESS=$(cast call --rpc-url ${NODE_RPC_URL} ${PASSKEY_ACCOUNT_FACTORY_ADDRESS} "getAddress(string calldata credId,uint256 pubKeyX,uint256 pubKeyY,uint256 salt)" ${PASSKEY_CREDENTIAL_ID} ${PASSKEY_X} ${PASSKEY_Y} 0 | sed -r 's/^[.]*(0x)([0]{24})?([0-9a-zA-Z]{40})[.]*$/\1\3/g')

echo "Verify: https://sepolia.etherscan.io/address/${PASSKEY_ACCOUNT_ADDRESS}#code" && echo "Implementation: ${PASSKEY_ACCOUNT_IMPLEMENTATION_ADDRESS}"
```

- 2. Open the displayed link, here is a sample output.

```shell
Verify: https://sepolia.etherscan.io/address/0x5c5d3afdaafdfb4ad974a28eda9bbf4c91c043a6#code
Implementation: 0xb22adc80082e3ad52b64138f5677c9f5f46dad1c
```

- 3. Click `Is this a proxy?` and `Verify`. Ensure the displayed implementation contract matches the sample output. Click `Save` to complete PasskeyAccount verification.

- 4. If necessary, you can also verify PasskeyAccount (ERC1967Proxy) contract.

```shell
forge verify-contract --watch --chain "sepolia" --verifier "etherscan" --etherscan-api-key ${ETHERSCAN_API_KEY} --compiler-version "0.8.23" --constructor-args $(cast abi-encode "constructor(address,bytes)" ${PASSKEY_ACCOUNT_IMPLEMENTATION_ADDRESS} $(cast calldata "initialize(string,uint256,uint256)" ${PASSKEY_CREDENTIAL_ID} ${PASSKEY_X} ${PASSKEY_Y})) ${PASSKEY_ACCOUNT_ADDRESS} "lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy"
```

- Output sample

```shell
Start verifying contract `0x5c5d3aFdaAfdFb4aD974a28eDA9bBf4C91C043a6` deployed on sepolia

Submitting verification for [lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy] 0x5c5d3aFdaAfdFb4aD974a28eDA9bBf4C91C043a6.
Submitted contract for verification:
        Response: `OK`
        GUID: `vxrnbpnypxyyyka25hjydpa2gigrxwqrhvzusnkzfpb82dynny`
        URL: https://sepolia.etherscan.io/address/0x5c5d3afdaafdfb4ad974a28eda9bbf4c91c043a6
Contract verification status:
Response: `NOTOK`
Details: `Pending in queue`
Contract verification status:
Response: `OK`
Details: `Pass - Verified`
Contract successfully verified
```
