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
forge create --rpc-url http://geth:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 src/Counter.sol:Counter; \
# Deploy PasskeyAccountFactory
echo -e "\033[0;33m[Deploy PasskeyAccountFactory]\033[0m"; \
forge create --rpc-url http://geth:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 src/account/PasskeyAccountFactory.sol:PasskeyAccountFactory --constructor-args 0x5FbDB2315678afecb367f032d93F642f64180aa3; \
# Deploy PasskeyAccount
echo -e "\033[0;33m[Deploy PasskeyAccount]\033[0m"; \
cast send --rpc-url http://geth:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707 "createAccount(string calldata credId,uint256 pubKeyX,uint256 pubKeyY,uint256 salt)" "SsXJcMCtCFAY-v5SOnuyD7p3wZ-Vgmigd2S9qIu8fZE" 45350939242947319465541081481587742776218222217118268954655717869512694523738 46971273219734637107918601418670912287394323851286117401543534995054486983562 0; \
# Get PasskeyAccount address
echo -e "\033[0;33m[PasskeyAccount address]\033[0m"; \
cast call --rpc-url http://geth:8545 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707 "getAddress(string calldata credId,uint256 pubKeyX,uint256 pubKeyY,uint256 salt)" "SsXJcMCtCFAY-v5SOnuyD7p3wZ-Vgmigd2S9qIu8fZE" 45350939242947319465541081481587742776218222217118268954655717869512694523738 46971273219734637107918601418670912287394323851286117401543534995054486983562 0; \
# Topup SimpleAccount
cast send --rpc-url http://geth:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 0x691b0b6350ecf4942bf7cdb3bafcbe4ad4f7bc7e --value 100ether; \
# Get balance of PasskeyAccount
echo -e "\033[0;33m[Balance of PasskeyAccount]\033[0m"; \
cast balance --rpc-url http://geth:8545 0x691b0b6350ecf4942bf7cdb3bafcbe4ad4f7bc7e
