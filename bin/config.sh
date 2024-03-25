#!/usr/bin/env bash

set -eo pipefail

get_uri() {
  local cid; cid=${1:?}
  cid=$(ipfs cid format -v 1 -b base32 $cid)
  uri="ipfs://$cid"
  echo $uri
}

# export PORT_KEY="ORMPPORT_ADDR"
# uri=$(get_uri "QmWpJRDW55oEPxcvKPbCg8p31odC2CnDJLqeT9MFn3peYi")
# forge script script/config/PortConfig.s.sol:PortConfig --sig "run(uint256[],string)" "[421614,11155111]" $uri --chain-id 43       --broadcast
# forge script script/config/PortConfig.s.sol:PortConfig --sig "run(uint256[],string)" "[11155111,44]"     $uri --chain-id 421614   --broadcast --skip-simulation --legacy
# forge script script/config/PortConfig.s.sol:PortConfig --sig "run(uint256[],string)" "[44,421614]"       $uri --chain-id 11155111 --broadcast

export PORT_KEY="ORMPUPORT_ADDR"
uri=$(get_uri "QmZB2RQ6nfWPq4a42FuPQAasSRFgqHFGgPqRNxEWAi7HEd")
# forge script script/config/PortConfig.s.sol:PortConfig --sig "run(uint256[],string)" "[421614,11155111]" $uri --chain-id 43       --broadcast -g 200
# forge script script/config/PortConfig.s.sol:PortConfig --sig "run(uint256[],string)" "[11155111,44]"     $uri --chain-id 421614   --broadcast --skip-simulation
# forge script script/config/PortConfig.s.sol:PortConfig --sig "run(uint256[],string)" "[44,421614]"       $uri --chain-id 11155111 --broadcast

# export PORT_KEY="MULTIPORT_ADDR"
# uri=$(get_uri "QmQsKZG4SSbqZ12a1VpZRsURrHbRe5mVbZZQ7GmLs42ZRN")
# forge script script/config/PortConfig.s.sol:PortConfig --sig "run(uint256[],string)" "[421614,11155111]" $uri --chain-id 43       --broadcast -g 200
# forge script script/config/PortConfig.s.sol:PortConfig --sig "run(uint256[],string)" "[11155111,44]"     $uri --chain-id 421614   --broadcast --skip-simulation --legacy
# forge script script/config/PortConfig.s.sol:PortConfig --sig "run(uint256[],string)" "[44,421614]"       $uri --chain-id 11155111 --broadcast
#
# forge script script/config/MultiPortConfig.s.sol:MultiPortConfig --chain-id 43       --broadcast -g 200
# forge script script/config/MultiPortConfig.s.sol:MultiPortConfig --chain-id 421614   --broadcast --skip-simulation --legacy
# forge script script/config/MultiPortConfig.s.sol:MultiPortConfig --chain-id 11155111 --broadcast

# export PORT_KEY="XACCOUNTFACTORY_ADDR"
# uri=$(get_uri "QmahfNo9m9TqHUxARhug93Ubzn3HVutfQ9bDAxWq9ksJhy")
# forge script script/config/PortConfig.s.sol:PortConfig --sig "run(uint256[],string)" "[]" $uri --chain-id 43       --broadcast -g 200
# forge script script/config/PortConfig.s.sol:PortConfig --sig "run(uint256[],string)" "[]" $uri --chain-id 421614   --broadcast --skip-simulation --legacy
# forge script script/config/PortConfig.s.sol:PortConfig --sig "run(uint256[],string)" "[]" $uri --chain-id 11155111 --broadcast


# forge script script/config/PortConfig.s.sol:PortConfig --sig "run(uint256[],string)" "[42161,1,44]" $uri --chain-id 46    --broadcast
# forge script script/config/PortConfig.s.sol:PortConfig --sig "run(uint256[],string)" "[46]"         $uri --chain-id 44    --broadcast
# forge script script/config/PortConfig.s.sol:PortConfig --sig "run(uint256[],string)" "[46,42161]"   $uri --chain-id 1     --broadcast
# forge script script/config/PortConfig.s.sol:PortConfig --sig "run(uint256[],string)" "[1,46]"       $uri --chain-id 42161 --broadcast --skip-simulation --legacy

# forge script script/config/PortConfig.s.sol:PortConfig --sig "run(uint256[],string)" "[46]" $uri --chain-id 137    --broadcast --with-gas-price 150000000000
# forge script script/config/PortConfig.s.sol:PortConfig --sig "run(uint256[],string)" "[137]" $uri --chain-id 46    --broadcast
# forge script script/config/PortConfig.s.sol:PortConfig --sig "run(uint256[],string)" "[42161]" $uri --chain-id 81457 --broadcast --legacy --with-gas-price 1060000
