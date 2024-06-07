#!/bin/sh

apk update && apk --no-cache add bash curl coreutils

rpc_url="http://geth:8545"

/script/wait.sh geth:8545 -t 60 || {
    echo "wait for ${rpc_url} failed";
    exit 1; 
}

# Setup signer for blocks
curl -d '{"id":1,"jsonrpc":"2.0","method":"clique_propose","params":["0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",true]}' -H "Content-Type: application/json" -X POST ${rpc_url}

# Contract operator
operator_address="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
operator_private_key="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

# For deploying periphery contracts
deployer_1_address="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
deployer_1_private_key="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
# For deploying account abstraction v0.6.0 contracts
deployer_2_address="0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"
deployer_2_private_key="0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"
# For deploying account abstraction v0.7.0 contracts
deployer_3_address="0x90F79bf6EB2c4f870365E785982E1f101E93b906"
deployer_3_private_key="0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6"

# Topup deployer
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${deployer_1_address} --value 100ether
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${deployer_2_address} --value 100ether
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${deployer_3_address} --value 100ether

passkey_credential_id=${PASSKEY_CREDENTIAL_ID:-"9h5F3DgLSjSMdnVOadmhCw"}
passkey_x=${PASSKEY_X:-67299174900712686363169673082376821529726602378544032702281553676098545184711}
passkey_y=${PASSKEY_Y:-104273800132786176334597151467609377740095818152192999025225464410568038480397}

entry_point_address="0x663F3ad617193148711d28f5334eE4Ed07016602"
simple_account_factory_address="0x2E983A1Ba5e8b38AAAeC4B440B9dDcFBf72E15d1"
passkey_account_factory_address="0xBC9129Dc0487fc2E169941C75aABC539f208fb01"
verifying_paymaster_address="0xF6168876932289D073567f347121A267095f3DD6"

# Deploy non-account abstraction contracts
echo -e "\033[0;33m[Deploy non-account abstraction contracts]\033[0m"

# Deploy Counter
echo -e "\033[0;33m[Deploy Counter]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${deployer_1_private_key} src/Counter.sol:Counter

# Deploy account abstraction v0.6.0 contracts
echo -e "\033[0;33m[Deploy account abstraction v0.6.0 contracts]\033[0m"

# Deploy EntryPoint
echo -e "\033[0;33m[Deploy EntryPoint]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${deployer_2_private_key} lib/account-abstraction/0.6/contracts/core/EntryPoint.sol:EntryPoint

# Deploy SimpleAccountFactory
echo -e "\033[0;33m[Deploy SimpleAccountFactory]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${deployer_2_private_key} lib/account-abstraction/0.6/contracts/samples/SimpleAccountFactory.sol:SimpleAccountFactory --constructor-args ${entry_point_address}

# Deploy SimpleAccount
echo -e "\033[0;33m[Create SimpleAccount]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${deployer_2_private_key} ${simple_account_factory_address} "createAccount(address owner,uint256 salt)" ${operator_address} 0

# Get SimpleAccount address
echo -e "\033[0;33m[Get SimpleAccount address]\033[0m"
simple_account_address=$(cast call --rpc-url ${rpc_url} ${simple_account_factory_address} "getAddress(address owner,uint256 salt)" ${operator_address} 0 | sed -r 's/^[.]*(0x)([0]{24}|)([0-9a-zA-Z]{40})[.]*$/\1\3/g')
echo ${simple_account_address}

# Topup SimpleAccount
echo -e "\033[0;33m[Transfer 100 ETH to SimpleAccount]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${simple_account_address} --value 100ether

# Deploy PasskeyAccountFactory
echo -e "\033[0;33m[Deploy PasskeyAccountFactory]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${deployer_2_private_key} src/account/0.6/PasskeyAccountFactory.sol:PasskeyAccountFactory --constructor-args ${entry_point_address}

# Deploy PasskeyAccount
echo -e "\033[0;33m[Create PasskeyAccount]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${deployer_2_private_key} ${passkey_account_factory_address} "createAccount(string calldata credId,uint256 pubKeyX,uint256 pubKeyY,uint256 salt)" ${passkey_credential_id} ${passkey_x} ${passkey_y} 0

# Get PasskeyAccount address
echo -e "\033[0;33m[Get PasskeyAccount address]\033[0m"
passkey_account_address=$(cast call --rpc-url ${rpc_url} ${passkey_account_factory_address} "getAddress(string calldata credId,uint256 pubKeyX,uint256 pubKeyY,uint256 salt)" ${passkey_credential_id} ${passkey_x} ${passkey_y} 0 | sed -r 's/^[.]*(0x)([0]{24}|)([0-9a-zA-Z]{40})[.]*$/\1\3/g')
echo ${passkey_account_address}

# Topup PasskeyAccount
echo -e "\033[0;33m[Transfer 100 ETH to PasskeyAccount]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${passkey_account_address} --value 100ether

# Deploy VerifyingPaymaster
echo -e "\033[0;33m[Deploy VerifyingPaymaster]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${deployer_2_private_key} lib/account-abstraction/0.6/contracts/samples/VerifyingPaymaster.sol:VerifyingPaymaster --constructor-args ${entry_point_address} ${operator_address}

# Deposit to EntryPoint for VerifyingPaymaster
echo -e "\033[0;33m[Deposit 100 ETH to EntryPoint for VerifyingPaymaster]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${entry_point_address} --value 100ether "depositTo(address account)" ${verifying_paymaster_address}
