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

# Bundler
bundler_v0_6_address="0x4b39F7b0624b9dB86AD293686bc38B903142dbBc"
bundler_v0_7_address="0x71b4a2d9B91726bdb5849D928967A1654D7F3de7"

# Topup bundlers
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${bundler_v0_6_address} --value 100ether
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${bundler_v0_7_address} --value 100ether

# For deploying periphery contracts
deployer_1_address="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
deployer_1_private_key="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"

# For deploying account abstraction v0.6.0 contracts
deployer_2_address="0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"
deployer_2_private_key="0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"

# For deploying account abstraction v0.7.0 contracts
deployer_3_address="0x90F79bf6EB2c4f870365E785982E1f101E93b906"
deployer_3_private_key="0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6"

# Topup deployers
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${deployer_1_address} --value 100ether
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${deployer_2_address} --value 100ether
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${deployer_3_address} --value 100ether

passkey_credential_id=${PASSKEY_CREDENTIAL_ID:-"9h5F3DgLSjSMdnVOadmhCw"}
passkey_x=${PASSKEY_X:-67299174900712686363169673082376821529726602378544032702281553676098545184711}
passkey_y=${PASSKEY_Y:-104273800132786176334597151467609377740095818152192999025225464410568038480397}

# Constants
zero_address=0x0000000000000000000000000000000000000000

##############################
# Deploy periphery contracts #
##############################

echo -e "\033[0;33m[Deploy periphery contracts]\033[0m"

counter_address="0x8464135c8F25Da09e49BC8782676a84730C318bC"
test_token_address="0x71C95911E9a5D330f4D621842EC243EE1343292e"
weth_address="0x948B3c65b89DF0B4894ABE91E6D02FE579834F8F"
mock_oracle_address="0x712516e61C8B383dF4A63CFe83d7701Bce54B03e"
mock_uniswap_v3_swap_router_address="0xbCF26943C0197d2eE0E5D05c716Be60cc2761508"

# Deploy Counter
echo -e "\033[0;33m[Deploy Counter]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${deployer_1_private_key} src/Counter.sol:Counter

# Deploy Test Token
echo -e "\033[0;33m[Deploy Test Token]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${deployer_1_private_key} src/token/ERC20Mintable.sol:ERC20Mintable --constructor-args "Test Token" "TEST"

# Deploy WETH
echo -e "\033[0;33m[Deploy WETH]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${deployer_1_private_key} src/token/WETH.sol:WETH

# Deploy Mock Oracle
echo -e "\033[0;33m[Deploy Mock Oracle]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${deployer_1_private_key} src/mock/MockOracle.sol:MockOracle --constructor-args ${test_token_address}

# Deploy Mock Uniswap v3 Swap Router
echo -e "\033[0;33m[Deploy Mock Uniswap v3 Swap Router]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${deployer_1_private_key} src/mock/MockUniswapV3SwapRouter.sol:MockUniswapV3SwapRouter --constructor-args ${weth_address}

# Deposit WETH to Mock Uniswap v3 Swap Router
echo -e "\033[0;33m[Deposit 100 WETH to Mock Uniswap v3 Swap Router]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${weth_address} --value 100ether
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${weth_address} "transfer(address dst, uint256 wad)" ${mock_uniswap_v3_swap_router_address} 100ether

###############################################
# Deploy account abstraction v0.6.0 contracts #
###############################################

echo -e "\033[0;33m[Deploy account abstraction v0.6.0 contracts]\033[0m"

entry_point_address_v0_6="0x663F3ad617193148711d28f5334eE4Ed07016602"
simple_account_factory_address_v0_6="0x2E983A1Ba5e8b38AAAeC4B440B9dDcFBf72E15d1"
simple_account_address_v0_6="0x7Fa35750bF7e98891019460b0B3194bE27E86859"
passkey_account_factory_address_v0_6="0xBC9129Dc0487fc2E169941C75aABC539f208fb01"
verifying_paymaster_address_v0_6="0xF6168876932289D073567f347121A267095f3DD6"

# Deploy EntryPoint v0.6
echo -e "\033[0;33m[Deploy EntryPoint v0.6]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${deployer_2_private_key} lib/account-abstraction/0.6/contracts/core/EntryPoint.sol:EntryPoint

# Deploy SimpleAccountFactory v0.6
echo -e "\033[0;33m[Deploy SimpleAccountFactory v0.6]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${deployer_2_private_key} lib/account-abstraction/0.6/contracts/samples/SimpleAccountFactory.sol:SimpleAccountFactory --constructor-args ${entry_point_address_v0_6}

# Deploy SimpleAccount v0.6
echo -e "\033[0;33m[Create SimpleAccount v0.6]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${deployer_2_private_key} ${simple_account_factory_address_v0_6} "createAccount(address owner,uint256 salt)" ${operator_address} 0

# Get SimpleAccount v0.6 address
echo -e "\033[0;33m[Get SimpleAccount v0.6 address]\033[0m"
echo $(cast call --rpc-url ${rpc_url} ${simple_account_factory_address_v0_6} "getAddress(address owner,uint256 salt)" ${operator_address} 0 | sed -r 's/^[.]*(0x)([0]{24}|)([0-9a-zA-Z]{40})[.]*$/\1\3/g')

# Topup SimpleAccount v0.6
echo -e "\033[0;33m[Transfer 100 ETH to SimpleAccount v0.6]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${simple_account_address_v0_6} --value 100ether

# Mint Test Token for SimpleAccount v0.6
echo -e "\033[0;33m[Mint 100 Test Token for SimpleAccount v0.6]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${test_token_address} "mint(address to, uint256 value)" ${simple_account_address_v0_6} 100ether

# Deploy PasskeyAccountFactory v0.6
echo -e "\033[0;33m[Deploy PasskeyAccountFactory v0.6]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${deployer_2_private_key} src/account/0.6/PasskeyAccountFactory.sol:PasskeyAccountFactory --constructor-args ${entry_point_address_v0_6} ${zero_address}

# Deploy PasskeyAccount v0.6
echo -e "\033[0;33m[Create PasskeyAccount v0.6]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${deployer_2_private_key} ${passkey_account_factory_address_v0_6} "createAccount(string calldata credId,uint256 pubKeyX,uint256 pubKeyY,uint256 salt)" ${passkey_credential_id} ${passkey_x} ${passkey_y} 0

# Get PasskeyAccount v0.6 address
echo -e "\033[0;33m[Get PasskeyAccount v0.6 address]\033[0m"
passkey_account_address_v0_6=$(cast call --rpc-url ${rpc_url} ${passkey_account_factory_address_v0_6} "getAddress(string calldata credId,uint256 pubKeyX,uint256 pubKeyY,uint256 salt)" ${passkey_credential_id} ${passkey_x} ${passkey_y} 0 | sed -r 's/^[.]*(0x)([0]{24}|)([0-9a-zA-Z]{40})[.]*$/\1\3/g')
echo ${passkey_account_address_v0_6}

# Topup PasskeyAccount v0.6
echo -e "\033[0;33m[Transfer 100 ETH to PasskeyAccount v0.6]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${passkey_account_address_v0_6} --value 100ether

# Mint Test Token for PasskeyAccount v0.6
echo -e "\033[0;33m[Mint 100 Test Token for PasskeyAccount v0.6]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${test_token_address} "mint(address to, uint256 value)" ${passkey_account_address_v0_6} 100ether

# Deploy VerifyingPaymaster v0.6
echo -e "\033[0;33m[Deploy VerifyingPaymaster v0.6]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${deployer_2_private_key} lib/account-abstraction/0.6/contracts/samples/VerifyingPaymaster.sol:VerifyingPaymaster --constructor-args ${entry_point_address_v0_6} ${operator_address}

# Deposit to EntryPoint for VerifyingPaymaster v0.6
echo -e "\033[0;33m[Deposit 100 ETH to EntryPoint for VerifyingPaymaster v0.6]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${entry_point_address_v0_6} --value 100ether "depositTo(address account)" ${verifying_paymaster_address_v0_6}

###############################################
# Deploy account abstraction v0.7.0 contracts #
###############################################

echo -e "\033[0;33m[Deploy account abstraction v0.7.0 contracts]\033[0m"

entry_point_address_v0_7="0x057ef64E23666F000b34aE31332854aCBd1c8544"
simple_account_factory_address_v0_7="0x261D8c5e9742e6f7f1076Fa1F560894524e19cad"
simple_account_address_v0_7="0xD0dA07666BA2139aa6fF7A450A8596291a6cE471"
passkey_account_factory_address_v0_7="0xCba6b9A951749B8735C603e7fFC5151849248772"
verifying_paymaster_address_v0_7="0xcf27F781841484d5CF7e155b44954D7224caF1dD"
token_paymaster_address_v0_7="0x673cD70FA883394a1f3DEb3221937Ceb7C2618D7"

# Deploy EntryPoint v0.7
echo -e "\033[0;33m[Deploy EntryPoint v0.7]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${deployer_3_private_key} lib/account-abstraction/0.7/contracts/core/EntryPoint.sol:EntryPoint

# Deploy SimpleAccountFactory v0.7
echo -e "\033[0;33m[Deploy SimpleAccountFactory v0.7]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${deployer_3_private_key} lib/account-abstraction/0.7/contracts/samples/SimpleAccountFactory.sol:SimpleAccountFactory --constructor-args ${entry_point_address_v0_7}

# Deploy SimpleAccount v0.7
echo -e "\033[0;33m[Create SimpleAccount v0.7]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${deployer_3_private_key} ${simple_account_factory_address_v0_7} "createAccount(address owner,uint256 salt)" ${operator_address} 0

# Get SimpleAccount v0.7 address
echo -e "\033[0;33m[Get SimpleAccount v0.7 address]\033[0m"
echo $(cast call --rpc-url ${rpc_url} ${simple_account_factory_address_v0_7} "getAddress(address owner,uint256 salt)" ${operator_address} 0 | sed -r 's/^[.]*(0x)([0]{24}|)([0-9a-zA-Z]{40})[.]*$/\1\3/g')

# Topup SimpleAccount v0.7
echo -e "\033[0;33m[Transfer 100 ETH to SimpleAccount v0.7]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${simple_account_address_v0_7} --value 100ether

# Mint Test Token for SimpleAccount v0.7
echo -e "\033[0;33m[Mint 100 Test Token for SimpleAccount v0.7]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${test_token_address} "mint(address to, uint256 value)" ${simple_account_address_v0_7} 100ether

# Deploy PasskeyAccountFactory v0.7
echo -e "\033[0;33m[Deploy PasskeyAccountFactory v0.7]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${deployer_3_private_key} src/account/0.7/PasskeyAccountFactory.sol:PasskeyAccountFactory --constructor-args ${entry_point_address_v0_7} ${zero_address}

# Deploy PasskeyAccount v0.7
echo -e "\033[0;33m[Create PasskeyAccount v0.7]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${deployer_3_private_key} ${passkey_account_factory_address_v0_7} "createAccount(string calldata credId,uint256 pubKeyX,uint256 pubKeyY,uint256 salt)" ${passkey_credential_id} ${passkey_x} ${passkey_y} 0

# Get PasskeyAccount v0.7 address
echo -e "\033[0;33m[Get PasskeyAccount v0.7 address]\033[0m"
passkey_account_address_v0_7=$(cast call --rpc-url ${rpc_url} ${passkey_account_factory_address_v0_7} "getAddress(string calldata credId,uint256 pubKeyX,uint256 pubKeyY,uint256 salt)" ${passkey_credential_id} ${passkey_x} ${passkey_y} 0 | sed -r 's/^[.]*(0x)([0]{24}|)([0-9a-zA-Z]{40})[.]*$/\1\3/g')
echo ${passkey_account_address_v0_7}

# Topup PasskeyAccount v0.7
echo -e "\033[0;33m[Transfer 100 ETH to PasskeyAccount v0.7]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${passkey_account_address_v0_7} --value 100ether

# Mint Test Token for PasskeyAccount v0.7
echo -e "\033[0;33m[Mint 100 Test Token for PasskeyAccount v0.7]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${test_token_address} "mint(address to, uint256 value)" ${passkey_account_address_v0_7} 100ether

# Deploy VerifyingPaymaster v0.7
echo -e "\033[0;33m[Deploy VerifyingPaymaster v0.7]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${deployer_3_private_key} lib/account-abstraction/0.7/contracts/samples/VerifyingPaymaster.sol:VerifyingPaymaster --constructor-args ${entry_point_address_v0_7} ${operator_address}

# Deposit to EntryPoint for VerifyingPaymaster v0.7
echo -e "\033[0;33m[Deposit 100 ETH to EntryPoint for VerifyingPaymaster v0.7]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${entry_point_address_v0_7} --value 100ether "depositTo(address account)" ${verifying_paymaster_address_v0_7}

# Deploy TokenPaymaster v0.7
echo -e "\033[0;33m[Deploy TokenPaymaster v0.7]\033[0m"
forge create --rpc-url ${rpc_url} --private-key ${deployer_3_private_key} lib/account-abstraction/0.7/contracts/samples/TokenPaymaster.sol:TokenPaymaster --constructor-args ${test_token_address} ${entry_point_address_v0_7} ${weth_address} ${mock_uniswap_v3_swap_router_address} "($(echo "1.1 * 10^26" | bc | cut -d'.' -f1),$((100*10**18)),100000,86400)" "(0,100,${mock_oracle_address},${zero_address},true,false,false,0)" "(1,0,0)" ${operator_address}

# Deposit to EntryPoint for VerifyingPaymaster v0.7
echo -e "\033[0;33m[Deposit 100 ETH to EntryPoint for TokenPaymaster v0.7]\033[0m"
cast send --rpc-url ${rpc_url} --private-key ${operator_private_key} ${entry_point_address_v0_7} --value 100ether "depositTo(address account)" ${token_paymaster_address_v0_7}
