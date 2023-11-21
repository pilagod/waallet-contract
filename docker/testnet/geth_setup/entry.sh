#!/bin/sh

apk --no-cache add curl

# Setup signer for blocks
curl -d '{"id":1,"jsonrpc":"2.0","method":"clique_propose","params":["0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",true]}' -H "Content-Type: application/json" -X POST http://geth:8545

# Deploy EntryPoint
forge create --rpc-url http://geth:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 lib/account-abstraction/contracts/core/EntryPoint.sol:EntryPoint; \
# Deploy SimpleAccountFactory
forge create --rpc-url http://geth:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 lib/account-abstraction/contracts/samples/SimpleAccountFactory.sol:SimpleAccountFactory --constructor-args 0x5FbDB2315678afecb367f032d93F642f64180aa3; \
# Deploy SimpleAccount
cast send --rpc-url http://geth:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "createAccount(address owner,uint256 salt)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 0; \
# Topup SimpleAccount
cast send --rpc-url http://geth:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 0x661b4a3909b486a3da520403ecc78f7a7b683c63 --value 100ether; \
# Deploy Counter
forge create --rpc-url http://geth:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 src/Counter.sol:Counter
