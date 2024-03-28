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
authenticator_rpid_hash=${AUTHENTICATOR_RPID_HASH:-"0x507c5c427c4e8f53fd35937b4d6c16c79b8687979d428b91b8bd3ca91396afc3"}

entry_point_address="0x5FbDB2315678afecb367f032d93F642f64180aa3"
simple_account_factory_address="0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
passkey_account_factory_address="0x5FC8d32690cc91D4c39d9d3abcBD16989F875707"
verifying_paymaster_address="0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6"
imAccount_implementation_address="0x610178dA211FEF7D417bC0e6FeD39F05609AD788"
ecdsa_validator_address="0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e"
webauthn_validator_address="0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE"
fallback_handler_address="0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0"
imAccount_factory_address="0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82"
imAccount_salt=0
imAccount_salt_webauthn=1

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

# Deposit to EntryPoint for VerifyingPaymaster
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
echo -e "\033[0;33m[Create imAccount w/ ECDSAValidator]\033[0m"
validator_initializer=$(cast calldata "init(address owner)" ${operator_address})
initializer=$(cast calldata "initialize(address,address,address,bytes calldata)" ${entry_point_address} ${fallback_handler_address} ${ecdsa_validator_address} ${validator_initializer})
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${imAccount_factory_address} "createAccount(bytes memory initializer, uint256 salt)" ${initializer} ${imAccount_salt}

# Get imAccountProxy address
echo -e "\033[0;33m[Get imAccount Address (w/ ECDSAValidator)]\033[0m"
imAccount_address=$(cast call --rpc-url ${rpc_url} ${imAccount_factory_address} "getAddress(uint256 salt)" ${imAccount_salt} | sed -r 's/^[.]*(0x)([0]{24}|)([0-9a-zA-Z]{40})[.]*$/\1\3/g')
echo ${imAccount_address}

# Topup imAccountProxy
echo -e "\033[0;33m[Transfer 100 ETH to imAccount]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${imAccount_address} --value 100ether

# Deploy WebAuthn Validator
echo -e "\033[0;33m[Deploy WebAuthn Validator]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${operator_private_key} lib/imAccount/src/account/validators/WebAuthnValidator.sol:WebAuthnValidator

# Topup Foundry Deployer Signer
FOUNDRY_SIGNER_ADDRESS="0x3fab184622dc19b6109349b94811493bf2a45362"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${FOUNDRY_SIGNER_ADDRESS} --value 100ether

# Deploy Foundry CREATE2 Factory
TRANSACTION=0xf8a58085174876e800830186a08080b853604580600e600039806000f350fe7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf31ba02222222222222222222222222222222222222222222222222222222222222222a02222222222222222222222222222222222222222222222222222222222222222
curl ${rpc_url} -X 'POST' -H 'Content-Type: application/json' --data "{\"jsonrpc\":\"2.0\", \"id\":1, \"method\": \"eth_sendRawTransaction\", \"params\": [\"$TRANSACTION\"]}"

# Deploy P256 Verifier
echo -e "\033[0;33m[Deploy P256 Verifier]\033[0m"
cd /
git clone https://github.com/daimo-eth/p256-verifier.git
cd p256-verifier
git checkout 4287b1714c2457514c97f47f55ff830d310a60cb
forge install
forge script ./script/Deploy.s.sol:DeployScript --rpc-url ${rpc_url} --broadcast --private-key ${operator_private_key}

# Deploy imAccountProxy (Create a new wallet)
echo -e "\033[0;33m[Create imAccount w/ WebAuthnValidator]\033[0m"
validator_initializer=$(cast calldata "init(uint256 ownerX,uint256 ownerY,bytes32 authenticatorRPIDHash)" ${passkey_x} ${passkey_y} ${authenticator_rpid_hash})
initializer=$(cast calldata "initialize(address,address,address,bytes calldata)" ${entry_point_address} ${fallback_handler_address} ${webauthn_validator_address} ${validator_initializer})
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${imAccount_factory_address} "createAccount(bytes memory initializer, uint256 salt)" ${initializer} ${imAccount_salt_webauthn}

# Get imAccountProxy address
echo -e "\033[0;33m[Get imAccount Address (w/ WebAuthnValidator)]\033[0m"
imAccount_address=$(cast call --rpc-url ${rpc_url} ${imAccount_factory_address} "getAddress(uint256 salt)" ${imAccount_salt_webauthn} | sed -r 's/^[.]*(0x)([0]{24}|)([0-9a-zA-Z]{40})[.]*$/\1\3/g')
echo ${imAccount_address}

# Topup imAccountProxy
echo -e "\033[0;33m[Transfer 100 ETH to imAccount]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${imAccount_address} --value 100ether
