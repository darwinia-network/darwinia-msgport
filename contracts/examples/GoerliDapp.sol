// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

import "../interfaces/IMsgport.sol";

contract GoerliDapp {
    address public gatewayAddress;

    constructor(address _gatewayAddress) {
        gatewayAddress = _gatewayAddress;
    }

    function remoteAdd(address pangolinDapp) external payable {
        bytes memory message = abi.encode(uint256(2));
        IMsgport(gatewayAddress).send{value: msg.value}(
            pangolinDapp,
            message,
            50_000,
            2457757432886
        );
    }
}
