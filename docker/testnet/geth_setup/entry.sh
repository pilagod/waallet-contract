#!/bin/sh

apk --no-cache add curl

rpc_url="http://geth:8545"

# Setup signer for blocks
curl -d '{"id":1,"jsonrpc":"2.0","method":"clique_propose","params":["0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",true]}' -H "Content-Type: application/json" -X POST ${rpc_url}

operator_address="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
operator_private_key="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

# Deploy EntryPoint
echo -e "\033[0;33m[Deploy EntryPoint]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${operator_private_key} lib/account-abstraction/contracts/core/EntryPoint.sol:EntryPoint
entry_point_address="0x5FbDB2315678afecb367f032d93F642f64180aa3"

# Deploy SimpleAccountFactory
echo -e "\033[0;33m[Deploy SimpleAccountFactory]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${operator_private_key} lib/account-abstraction/contracts/samples/SimpleAccountFactory.sol:SimpleAccountFactory --constructor-args ${entry_point_address}
simple_account_factory_address="0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"

# Deploy SimpleAccount
echo -e "\033[0;33m[Create SimpleAccount]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${simple_account_factory_address} "createAccount(address owner,uint256 salt)" ${operator_address} 0

# Get SimpleAccount address
echo -e "\033[0;33m[Get SimpleAccount address]\033[0m"
simple_account_address=$(cast call --rpc-url ${rpc_url} ${simple_account_factory_address} "getAddress(address owner,uint256 salt)" ${operator_address} 0 | sed -r 's/^[.]*(0x)([0]{24}|)([0-9a-zA-Z]{40})[.]*$/\1\3/g')
echo ${simple_account_address}

# Topup SimpleAccount
echo -e "\033[0;33m[Transfer 100 ETH to SimpleAccount]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${simple_account_address} --value 100ether

# Deploy Counter
echo -e "\033[0;33m[Deploy Counter]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${operator_private_key} src/Counter.sol:Counter

# Deploy PasskeyAccountFactory
echo -e "\033[0;33m[Deploy PasskeyAccountFactory]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${operator_private_key} src/account/PasskeyAccountFactory.sol:PasskeyAccountFactory --constructor-args ${entry_point_address}
passkey_account_factory_address="0x5FC8d32690cc91D4c39d9d3abcBD16989F875707"

# Deploy PasskeyAccount
echo -e "\033[0;33m[Create PasskeyAccount]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${passkey_account_factory_address} "createAccount(string calldata credId,uint256 pubKeyX,uint256 pubKeyY,uint256 salt)" "9h5F3DgLSjSMdnVOadmhCw" 67299174900712686363169673082376821529726602378544032702281553676098545184711 104273800132786176334597151467609377740095818152192999025225464410568038480397 0

# Get PasskeyAccount address
echo -e "\033[0;33m[Get PasskeyAccount address]\033[0m"
passkey_account_address=$(cast call --rpc-url ${rpc_url} ${passkey_account_factory_address} "getAddress(string calldata credId,uint256 pubKeyX,uint256 pubKeyY,uint256 salt)" "9h5F3DgLSjSMdnVOadmhCw" 67299174900712686363169673082376821529726602378544032702281553676098545184711 104273800132786176334597151467609377740095818152192999025225464410568038480397 0 | sed -r 's/^[.]*(0x)([0]{24}|)([0-9a-zA-Z]{40})[.]*$/\1\3/g')
echo ${passkey_account_address}

# Topup PasskeyAccount
echo -e "\033[0;33m[Transfer 100 ETH to PasskeyAccount]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${passkey_account_address} --value 100ether

# Deploy VerifyingPaymaster
echo -e "\033[0;33m[Deploy VerifyingPaymaster]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${operator_private_key} lib/account-abstraction/contracts/samples/VerifyingPaymaster.sol:VerifyingPaymaster --constructor-args ${entry_point_address} ${operator_address}
verifying_paymaster_address="0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6"

# Deposit to EntryPoint for PasskeyAccount
echo -e "\033[0;33m[Deposit 100 ETH to EntryPoint for VerifyingPaymaster]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${entry_point_address} --value 100ether "depositTo(address account)" ${verifying_paymaster_address}
