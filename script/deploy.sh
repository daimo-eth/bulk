
# Deploy BundleBulker
forge script script/Deploy.s.sol --sig "deploy()" --fork-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY

# Deploy PerOpInflator
forge script script/Deploy.s.sol --sig "deployPerOpInflator()" --fork-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY

# Deploy example inflator
forge script script/Deploy.s.sol --sig "deployDaimoOpInflator()" --fork-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
