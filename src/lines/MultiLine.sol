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

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./base/BaseMessageLine.sol";
import "./base/LineLookup.sol";
import "../interfaces/ILineRegistry.sol";
import "../interfaces/ILineMetadata.sol";
import "../interfaces/IMessageLine.sol";
import "../user/Application.sol";

/// @title MultiLine
/// @notice Send message by multi message line.
contract MultiLine is Ownable2Step, Application, BaseMessageLine, LineLookup {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev RemoteCallArgs
    /// @param params Params correspond with the trusted lines.
    /// @param fees Fees correspond with the trusted lines.
    struct RemoteCallArgs {
        bytes[] params;
        uint256[] fees;
    }

    struct MultiSendArgs {
        uint256 toChainId;
        address toDapp;
        bytes message;
        bytes[] params;
        uint256[] fees;
    }

    struct LineMsg {
        uint256 fromChainId;
        uint256 toChainId;
        address fromDapp;
        address toDapp;
        uint256 nonce;
        uint256 expiration;
        bytes message;
    }

    uint256 public nonce;
    uint256 public threshold;
    uint256 public expiration;
    EnumerableSet.AddressSet private _trustedLines;

    mapping(bytes32 lineMsgId => bool done) public doneOf;
    mapping(bytes32 lineMsgId => uint256 deliveryCount) public countOf;
    // protect msg repeat by underwood
    mapping(bytes32 lineMsgId => mapping(address line => bool isDeliveried)) public deliverifyOf;

    event SetThreshold(uint256 threshold);
    event SetExpiration(uint256 expiration);
    event LineMessageSent(bytes32 indexed lineMsgId, LineMsg lineMsg);
    event LineMessageConfirmation(bytes32 indexed lineMsgId, string name);
    event LineMessageExpired(bytes32 indexed lineMsgId);
    event LineMessageExecution(bytes32 indexed lineMsgId);

    constructor(address dao, uint256 threshold_, string memory name) BaseMessageLine(name) {
        _transferOwnership(dao);
        _setThreshold(threshold_);
    }

    function setURI(string calldata uri) external onlyOwner {
        _setURI(uri);
    }

    function setThreshold(uint256 threshold_) external onlyOwner {
        _setThreshold(threshold_);
    }

    function _setThreshold(uint256 threshold_) internal {
        require(threshold_ > 0, "!threshold");
        threshold = threshold_;
        emit SetThreshold(threshold_);
    }

    function setExpiration(uint256 expiration_) external onlyOwner {
        expiration = expiration_;
        emit SetExpiration(expiration_);
    }

    function addTrustedLine(address line) external onlyOwner {
        require(_trustedLines.add(line), "!add");
    }

    function rmTrustedLine(address line) external onlyOwner {
        require(_trustedLines.remove(line), "!rm");
    }

    function trustedLines() public view returns (address[] memory) {
        return _trustedLines.values();
    }

    function trustedLineCount() public view returns (uint256) {
        return _trustedLines.length();
    }

    function isTrustedLine(address line) public view returns (bool) {
        return _trustedLines.contains(line);
    }

    function setToLine(uint256 toChainId, address toLineAddress) external onlyOwner {
        _setToLine(toChainId, toLineAddress);
    }

    function setFromLine(uint256 fromChainId, address fromLineAddress) external onlyOwner {
        _setFromLine(fromChainId, fromLineAddress);
    }

    function _toLine(uint256 toChainId) internal view returns (address l) {
        l = toLineLookup[toChainId];
        require(l != address(0), "!toLine");
    }

    function _fromLine(uint256 fromChainId) internal view returns (address) {
        return fromLineLookup[fromChainId];
    }

    function _send(address, uint256 toChainId, address toDapp, bytes calldata message, bytes calldata params)
        internal
        override
    {
        RemoteCallArgs memory args = abi.decode(params, (RemoteCallArgs));
        multiSend(MultiSendArgs(toChainId, toDapp, message, args.params, args.fees));
    }

    function multiSend(MultiSendArgs memory args) public payable {
        uint256 len = trustedLineCount();
        require(args.toChainId != LOCAL_CHAINID(), "!toChainId");
        require(len >= threshold, "!len");
        require(len == args.params.length, "!len");
        require(len == args.fees.length, "!len");

        ++nonce;

        address fromDapp = msg.sender;
        LineMsg memory lineMsg = LineMsg({
            fromChainId: LOCAL_CHAINID(),
            toChainId: args.toChainId,
            fromDapp: fromDapp,
            toDapp: args.toDapp,
            nonce: nonce,
            expiration: block.timestamp + expiration,
            message: args.message
        });
        bytes memory encoded = abi.encodeWithSelector(MultiLine.multiRecv.selector, lineMsg);
        bytes32 lineMsgId = hash(lineMsg);

        _multiSend(args, encoded);
        emit LineMessageSent(lineMsgId, lineMsg);
    }

    function _multiSend(MultiSendArgs memory args, bytes memory encoded) internal {
        address[] memory lines = trustedLines();
        uint256 len = lines.length;
        uint256 totalFee = 0;
        for (uint256 i = 0; i < len; i++) {
            uint256 fee = args.fees[i];
            address line = lines[i];
            require(isTrustedLine(line), "!trusted");
            IMessageLine(line).send{value: fee}(args.toChainId, _toLine(args.toChainId), encoded, args.params[i]);
            totalFee += fee;
        }

        require(totalFee == msg.value, "!fees");
    }

    function multiRecv(LineMsg calldata lineMsg) external payable {
        address line = _msgLine();
        require(isTrustedLine(line), "!trusted");
        uint256 fromChainId = _fromChainId();
        require(LOCAL_CHAINID() == lineMsg.toChainId, "!toChainId");
        require(fromChainId == lineMsg.fromChainId, "!fromChainId");
        require(fromChainId != LOCAL_CHAINID(), "!fromChainId");
        require(_xmsgSender() == _fromLine(fromChainId), "!xmsgSender");
        bytes32 lineMsgId = hash(lineMsg);
        require(deliverifyOf[lineMsgId][line] == false, "deliveried");
        deliverifyOf[lineMsgId][line] = true;
        ++countOf[lineMsgId];

        emit LineMessageConfirmation(lineMsgId, ILineMetadata(line).name());

        if (block.timestamp > lineMsg.expiration) {
            emit LineMessageExpired(lineMsgId);
            return;
        }

        require(doneOf[lineMsgId] == false, "done");
        if (countOf[lineMsgId] >= threshold) {
            doneOf[lineMsgId] = true;
            _recv(lineMsg.fromChainId, lineMsg.fromDapp, lineMsg.toDapp, lineMsg.message);
            emit LineMessageExecution(lineMsgId);
        }
    }

    function hash(LineMsg memory lineMsg) public pure returns (bytes32) {
        return keccak256(abi.encode(lineMsg));
    }
}
