#!/bin/sh

apk --no-cache add curl

rpc_url="http://geth:8545"

# Setup signer for blocks
curl -d '{"id":1,"jsonrpc":"2.0","method":"clique_propose","params":["0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",true]}' -H "Content-Type: application/json" -X POST ${rpc_url}

operator_address="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
operator_private_key="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

passkey_credential_id=${PASSKEY_CREDENTIAL_ID:-"9h5F3DgLSjSMdnVOadmhCw"}
passkey_x=${PASSKEY_X:-67299174900712686363169673082376821529726602378544032702281553676098545184711}
passkey_y=${PASSKEY_Y:-104273800132786176334597151467609377740095818152192999025225464410568038480397}

entry_point_address="0x5FbDB2315678afecb367f032d93F642f64180aa3"
simple_account_factory_address="0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
passkey_account_factory_address="0x5FC8d32690cc91D4c39d9d3abcBD16989F875707"
verifying_paymaster_address="0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6"
imAccount_implementation_address="0x610178dA211FEF7D417bC0e6FeD39F05609AD788"
ecdsa_validator_address="0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e"
fallback_handler_address="0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0"
imAccount_factory_address="0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82"
SALT=0

# Deploy EntryPoint
echo -e "\033[0;33m[Deploy EntryPoint]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${operator_private_key} lib/account-abstraction/contracts/core/EntryPoint.sol:EntryPoint

# Deploy SimpleAccountFactory
echo -e "\033[0;33m[Deploy SimpleAccountFactory]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${operator_private_key} lib/account-abstraction/contracts/samples/SimpleAccountFactory.sol:SimpleAccountFactory --constructor-args ${entry_point_address}

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

# Deploy PasskeyAccount
echo -e "\033[0;33m[Create PasskeyAccount]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${passkey_account_factory_address} "createAccount(string calldata credId,uint256 pubKeyX,uint256 pubKeyY,uint256 salt)" ${passkey_credential_id} ${passkey_x} ${passkey_y} 0

# Get PasskeyAccount address
echo -e "\033[0;33m[Get PasskeyAccount address]\033[0m"
passkey_account_address=$(cast call --rpc-url ${rpc_url} ${passkey_account_factory_address} "getAddress(string calldata credId,uint256 pubKeyX,uint256 pubKeyY,uint256 salt)" ${passkey_credential_id} ${passkey_x} ${passkey_y} 0 | sed -r 's/^[.]*(0x)([0]{24}|)([0-9a-zA-Z]{40})[.]*$/\1\3/g')
echo ${passkey_account_address}

# Topup PasskeyAccount
echo -e "\033[0;33m[Transfer 100 ETH to PasskeyAccount]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${passkey_account_address} --value 100ether

# Deploy VerifyingPaymaster
echo -e "\033[0;33m[Deploy VerifyingPaymaster]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${operator_private_key} lib/account-abstraction/contracts/samples/VerifyingPaymaster.sol:VerifyingPaymaster --constructor-args ${entry_point_address} ${operator_address}

# Deposit to EntryPoint for PasskeyAccount
echo -e "\033[0;33m[Deposit 100 ETH to EntryPoint for VerifyingPaymaster]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${entry_point_address} --value 100ether "depositTo(address account)" ${verifying_paymaster_address}

# Deploy imAccount (implementation contract)
echo -e "\033[0;33m[Deploy imAccount Implementation]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${operator_private_key} lib/imAccount/src/account/imAccount.sol:imAccount

# Deploy ECDSA Validator
echo -e "\033[0;33m[Deploy ECDSA Validator]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${operator_private_key} lib/imAccount/src/account/validators/ECDSAValidator.sol:ECDSAValidator

# Deploy Fallback Handler
echo -e "\033[0;33m[Deploy Fallback Handler]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${operator_private_key} lib/imAccount/src/account/handler/FallbackHandler.sol:FallbackHandler

# Deploy imAccountFactory
echo -e "\033[0;33m[Deploy imAccountFactory]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${operator_private_key} lib/imAccount/src/account/factory/imAccountFactory.sol:imAccountFactory --constructor-args ${operator_address}

# Setup implementation address in imAccountFactory
echo -e "\033[0;33m[Setup Implementation Address]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${imAccount_factory_address} "setImpl(address implAddr)" ${imAccount_implementation_address}

# Deploy imAccountProxy (Create a new wallet)
echo -e "\033[0;33m[Create imAccount]\033[0m"
validator_initializer=$(cast calldata "init(address owner)" ${operator_address})
initializer=$(cast calldata "initialize(address,address,address,bytes calldata)" ${entry_point_address} ${fallback_handler_address} ${ecdsa_validator_address} ${validator_initializer})
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${imAccount_factory_address} "createAccount(bytes memory initializer, uint256 salt)" ${initializer} ${SALT}

# Get imAccountProxy address
echo -e "\033[0;33m[Get imAccount Address]\033[0m"
imAccount_address=$(cast call --rpc-url ${rpc_url} ${imAccount_factory_address} "getAddress(uint256 salt)" ${SALT} | sed -r 's/^[.]*(0x)([0]{24}|)([0-9a-zA-Z]{40})[.]*$/\1\3/g')
echo ${imAccount_address}

# Topup imAccountProxy
echo -e "\033[0;33m[Transfer 100 ETH to imAccount]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${imAccount_address} --value 100ether
