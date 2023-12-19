#!/bin/sh

apk --no-cache add curl

# Setup signer for blocks
curl -d '{"id":1,"jsonrpc":"2.0","method":"clique_propose","params":["0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",true]}' -H "Content-Type: application/json" -X POST http://geth:8545

# Deploy EntryPoint
echo -e "\033[0;33m[Deploy EntryPoint]\033[0m"; \
forge create --rpc-url http://geth:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 lib/account-abstraction/contracts/core/EntryPoint.sol:EntryPoint; \
# Deploy SimpleAccountFactory
echo -e "\033[0;33m[Deploy SimpleAccountFactory]\033[0m"; \
forge create --rpc-url http://geth:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 lib/account-abstraction/contracts/samples/SimpleAccountFactory.sol:SimpleAccountFactory --constructor-args 0x5FbDB2315678afecb367f032d93F642f64180aa3; \
# Deploy SimpleAccount
echo -e "\033[0;33m[Create SimpleAccount]\033[0m"; \
cast send --rpc-url http://geth:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "createAccount(address owner,uint256 salt)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 0; \
# Get SimpleAccount address
echo -e "\033[0;33m[Get SimpleAccount address]\033[0m"; \
cast call --rpc-url http://geth:8545 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "getAddress(address owner,uint256 salt)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 0; \
# Topup SimpleAccount
echo -e "\033[0;33m[Transfer 100 ETH to SimpleAccount]\033[0m"; \
cast send --rpc-url http://geth:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 0x1cee485cc83c5a17692904ff441a115fb223788e --value 100ether; \
# Deploy Counter
echo -e "\033[0;33m[Deploy Counter]\033[0m"; \
forge create --rpc-url http://geth:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 src/Counter.sol:Counter; \
# Deploy PasskeyAccountFactory
echo -e "\033[0;33m[Deploy PasskeyAccountFactory]\033[0m"; \
forge create --rpc-url http://geth:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 src/account/PasskeyAccountFactory.sol:PasskeyAccountFactory --constructor-args 0x5FbDB2315678afecb367f032d93F642f64180aa3; \
# Deploy PasskeyAccount
echo -e "\033[0;33m[Create PasskeyAccount]\033[0m"; \
cast send --rpc-url http://geth:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707 "createAccount(string calldata credId,uint256 pubKeyX,uint256 pubKeyY,uint256 salt)" "f61e45dc-380b-4a34-8c76-754e69d9a10b" 67299174900712686363169673082376821529726602378544032702281553676098545184711 104273800132786176334597151467609377740095818152192999025225464410568038480397 0; \
# Get PasskeyAccount address
echo -e "\033[0;33m[Get PasskeyAccount address]\033[0m"; \
cast call --rpc-url http://geth:8545 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707 "getAddress(string calldata credId,uint256 pubKeyX,uint256 pubKeyY,uint256 salt)" "f61e45dc-380b-4a34-8c76-754e69d9a10b" 67299174900712686363169673082376821529726602378544032702281553676098545184711 104273800132786176334597151467609377740095818152192999025225464410568038480397 0; \
# Topup PasskeyAccount
echo -e "\033[0;33m[Transfer 100 ETH to PasskeyAccount]\033[0m"; \
cast send --rpc-url http://geth:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 0x59c710cfa907a92de6d29971c7c20a5e080b3b43 --value 100ether; \
# Get balance of PasskeyAccount
echo -e "\033[0;33m[Get balance of PasskeyAccount]\033[0m"; \
cast balance --rpc-url http://geth:8545 0x59c710cfa907a92de6d29971c7c20a5e080b3b43
