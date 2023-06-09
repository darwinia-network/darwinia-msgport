// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./base/BaseMessageLine.sol";
import "../utils/Utils.sol";
import "../chain-id-mappings/LayerZeroChainIdMapping.sol";
import "../utils/GNSPSBytesLib.sol";
import "@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol";

contract LayerZeroLine is
    BaseMessageLine,
    NonblockingLzApp,
    LayerZeroChainIdMapping
{
    using GNSPSBytesLib for bytes;

    IChainIdMapping public chainIdMapping;

    constructor(
        address _localMsgportAddress,
        address _lzEndpoingAddress,
        address _chainIdMapping
    )
        BaseMessageLine(_localMsgportAddress, _lzEndpoingAddress)
        NonblockingLzApp(_lzEndpoingAddress)
    {
        chainIdMapping = IChainIdMapping(_chainIdMapping);
    }

    function setChainIdMapping(address _chainIdConverter) external onlyOwner {
        chainIdMapping = IChainIdMapping(_chainIdConverter);
    }

    function newOutboundLane(
        uint64 _toChainId,
        address _toLineAddress
    ) external onlyOwner {
        _addOutboundLaneInternal(_toChainId, _toLineAddress);
    }

    function newInboundLane(
        uint64 _fromChainId,
        address _fromLineAddress
    ) external onlyOwner {
        _addInboundLaneInternal(_fromChainId, _fromLineAddress);
    }

    function chainIdUp(uint16 _chainId) public view returns (uint64) {
        return chainIdMapping.up(Utils.uint16ToBytes(_chainId));
    }

    function chainIdDown(uint64 _chainId) public view returns (uint16) {
        return Utils.bytesToUint16(chainIdMapping.down(_chainId));
    }

    function _callRemoteRecv(
        address _fromDappAddress,
        OutboundLane memory _outboundLane,
        address _toDappAddress,
        bytes memory _messagePayload,
        bytes memory _params
    ) internal override {
        // set remote line address
        uint16 remoteChainId = chainIdDown(_outboundLane.toChainId);

        // build layer zero message
        bytes memory layerZeroMessage = abi.encode(
            _fromDappAddress,
            _toDappAddress,
            _messagePayload
        );

        _lzSend(
            remoteChainId,
            layerZeroMessage,
            payable(msg.sender), // refund to msgport
            address(0x0), // zro payment address
            _params, // adapter params
            msg.value
        );
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 /*_nonce*/,
        bytes memory _payload
    ) internal virtual override {
        uint64 srcChainId = chainIdUp(_srcChainId);
        address srcLineAddress = Utils.bytesToAddress(_srcAddress);

        (
            address fromDappAddress,
            address toDappAddress,
            bytes memory messagePayload
        ) = abi.decode(_payload, (address, address, bytes));

        InboundLane memory inboundLane = inboundLanes[srcChainId];
        require(
            inboundLane.fromLineAddress == srcLineAddress,
            "invalid source line address"
        );

        recv(fromDappAddress, inboundLane, toDappAddress, messagePayload);
    }
}
