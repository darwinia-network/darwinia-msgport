#!/usr/bin/env bash

set -eo pipefail

# Deploy port registry on testnet
# forge script script/deploy/DeployPortRegistry.s.sol:DeployPortRegistry --chain-id 421614   --slow --broadcast --verify --legacy --skip-simulation
# forge script script/deploy/DeployPortRegistry.s.sol:DeployPortRegistry --chain-id 11155111 --broadcast --verify --legacy
# forge script script/deploy/DeployPortRegistry.s.sol:DeployPortRegistry --chain-id 43       --broadcast --verify 

# Deploy multi port on testnet
# forge script script/deploy/DeployMultiPort.s.sol:DeployMultiPort --chain-id 421614   --slow --broadcast --verify --legacy --skip-simulation
# forge script script/deploy/DeployMultiPort.s.sol:DeployMultiPort --chain-id 11155111 --broadcast --verify --legacy
# forge script script/deploy/DeployMultiPort.s.sol:DeployMultiPort --chain-id 43       --broadcast --verify 

# Deploy safe msgport module on testnet
# forge script script/deploy/DeploySafeMsgportModule.s.sol:DeploySafeMsgportModule --chain-id 421614   --slow --broadcast --verify --legacy --skip-simulation
# forge script script/deploy/DeploySafeMsgportModule.s.sol:DeploySafeMsgportModule --chain-id 11155111 --broadcast --verify --legacy
# forge script script/deploy/DeploySafeMsgportModule.s.sol:DeploySafeMsgportModule --chain-id 43       --broadcast --verify 

# Deploy xaccount factory on testnet
# forge script script/deploy/DeployXAccountFactory.s.sol:DeployXAccountFactory --chain-id 421614   --slow --broadcast --verify --legacy --skip-simulation
# forge script script/deploy/DeployXAccountFactory.s.sol:DeployXAccountFactory --chain-id 11155111 --broadcast --verify --legacy
# forge script script/deploy/DeployXAccountFactory.s.sol:DeployXAccountFactory --chain-id 43       --broadcast --verify 

# Deploy ormp port on testnet
# forge script script/deploy/DeployORMPPort.s.sol:DeployORMPPort --chain-id 43       --broadcast --verify --legacy --skip-simulation
# forge script script/deploy/DeployORMPPort.s.sol:DeployORMPPort --chain-id 421614   --broadcast --verify --legacy --skip-simulation
# forge script script/deploy/DeployORMPPort.s.sol:DeployORMPPort --chain-id 11155111 --broadcast --verify --legacy

# Deploy ormp-u port on testnet
forge script script/deploy/DeployORMPUPort.s.sol:DeployORMPUPort --chain-id 43       --broadcast --verify --legacy 
forge script script/deploy/DeployORMPUPort.s.sol:DeployORMPUPort --chain-id 421614   --broadcast --verify --legacy --skip-simulation
forge script script/deploy/DeployORMPUPort.s.sol:DeployORMPUPort --chain-id 11155111 --broadcast --verify --legacy

# forge script script/deploy/DeployORMPPort.s.sol:DeployORMPPort --chain-id 1     --broadcast --verify --slow
# forge script script/deploy/DeployORMPPort.s.sol:DeployORMPPort --chain-id 44    --broadcast --verify --slow
# forge script script/deploy/DeployORMPPort.s.sol:DeployORMPPort --chain-id 46    --broadcast --verify --slow
# forge script script/deploy/DeployORMPPort.s.sol:DeployORMPPort --chain-id 137   --broadcast --verify
# forge script script/deploy/DeployORMPPort.s.sol:DeployORMPPort --chain-id 42161 --broadcast --verify --slow --legacy --skip-simulation
# forge script script/deploy/DeployORMPPort.s.sol:DeployORMPPort --chain-id 81457 --broadcast --verify --legacy --with-gas-price 1060000
