// This file is part of Darwinia.
// Copyright (C) 2018-2023 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.17;

import {OApp, Origin, MessagingFee} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "./base/BaseMessagePort.sol";
import "./base/FromPortLookup.sol";
import "../chain-id-mappings/LayerZeroChainIdMapping.sol";

contract LayerZeroV2Port is Ownable2Step, BaseMessagePort, FromPortLookup, LayerZeroChainIdMapping, OApp {
    constructor(
        address dao,
        address lzEndpoint,
        string memory name,
        uint256[] memory chainIds,
        uint16[] memory lzChainIds
    ) BaseMessagePort(name) OApp(lzEndpoint, dao) LayerZeroChainIdMapping(chainIds, lzChainIds) {
        _transferOwnership(dao);
    }

    function _transferOwnership(address newOwner) internal override(Ownable, Ownable2Step) {
        super._transferOwnership(newOwner);
    }

    function transferOwnership(address newOwner) public virtual override(Ownable, Ownable2Step) onlyOwner {
        super.transferOwnership(newOwner);
    }

    function setChainIdMap(uint256 chainId, uint16 lzChainId) external onlyOwner {
        _setChainIdMap(chainId, lzChainId);
    }

    function setFromPort(uint256 fromChainId, address fromPortAddress) external onlyOwner {
        _setFromPort(fromChainId, fromPortAddress);
    }

    function fromPortLookup(uint256 fromChainId) public view override returns (address) {
        uint16 lzChainId = down(fromChainId);
        return bytesToAddress(this.getTrustedRemoteAddress(lzChainId));
    }

    function bytesToAddress(bytes memory addressBytes) internal pure returns (address) {
        return address(bytes20(bytes(addressBytes)));
    }

    function _setFromPort(uint256 fromChainId, address fromPort) internal override {
        uint16 lzChainId = down(fromChainId);
        bytes memory path = abi.encodePacked(fromPort, address(this));
        trustedRemoteLookup[lzChainId] = path;
        emit SetFromPort(fromChainId, fromPort);
        emit SetTrustedRemote(lzChainId, path);
        emit SetTrustedRemoteAddress(lzChainId, abi.encodePacked(fromPort));
    }

    function _send(address fromDapp, uint256 toChainId, address toDapp, bytes calldata message, bytes calldata params)
        internal
        override
    {
        (address refund, bytes memory options) = abi.decode(params, (address, bytes));
        uint32 dstEid = down(toChainId);

        // build layer zero message
        bytes memory layerZeroMessage = abi.encode(fromDapp, toDapp, message);

        _lzSend(
            dstEid, // Destination chain's endpoint ID.
            layerZeroMessage, // Encoded message payload being sent.
            options, // Message execution options (e.g., gas to use on destination).
            MessagingFee(msg.value, 0), // Fee struct containing native gas and ZRO token.
            payable(msg.sender) // The refund address in case the send call reverts.
        );
    }

    function _storeFailedMessage(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes memory payload,
        bytes memory reason
    ) internal override {
        emit MessageFailed(srcChainId, srcAddress, nonce, payload, reason);
    }

    function retryMessage(uint16, bytes calldata, uint64, bytes calldata) public payable override {
        revert("!retry");
    }

    function clear(uint16 srcChainId, bytes calldata srcAddress) external {
        ILayerZeroEndpoint(lzEndpoint).forceResumeReceive(srcChainId, srcAddress);
    }

    function _lzReceive(
        Origin calldata origin, // struct containing info about the message sender
        bytes32 guid, // global packet identifier
        bytes calldata payload, // encoded message payload being received
        address executor, // the Executor address.
        bytes calldata extraData // arbitrary data appended by the Executor
    ) internal override {
        (address fromDapp, address toDapp, bytes memory message) = abi.decode(payload, (address, address, bytes));
        _recv(up(origin.srcEid), fromDapp, toDapp, message);
    }

    function fee(uint256 toChainId, address toDapp, bytes calldata message, bytes calldata params)
        external
        view
        override
        returns (uint256)
    {
        uint32 dstEid = down(toChainId);
        (, bytes memory options) = abi.decode(params, (address, bytes));
        bytes memory layerZeroMessage = abi.encode(msg.sender, toDapp, message);
        MessageFee memory fee = _quote(dstEid, layerZeroMessage, options, false);
        return fee.nativeFee;
    }
}
