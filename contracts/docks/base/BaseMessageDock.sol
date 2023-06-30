// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/IMessageDock.sol";
import "../../interfaces/IMessagePort.sol";
import "../../interfaces/IChainIdMapping.sol";

abstract contract BaseMessageDock is IMessageDock{
    struct OutboundLane {
        uint64 toChainId;
        address toDockAddress;
    }

    struct InboundLane {
        uint64 fromChainId;
        address fromDockAddress;
    }

    // tgtChainId => OutboundLane
    mapping(uint64 => OutboundLane) public outboundLanes;
    // srcChainId => srcDockAddress => InboundLane
    mapping(uint64 => InboundLane) public inboundLanes;

    address public localLevelMessagingContractAddress;
    IMessagePort public immutable LOCAL_MSGPORT;

    constructor(
        address _localMsgportAddress,
        address _localLevelMessagingContractAddress
    ) {
        LOCAL_MSGPORT = IMessagePort(_localMsgportAddress);
        localLevelMessagingContractAddress = _localLevelMessagingContractAddress;
    }

    function getLocalChainId() public view returns (uint64) {
        return LOCAL_MSGPORT.getLocalChainId();
    }

    function outboundLaneExists(
        uint64 _toChainId
    ) public view virtual returns (bool) {
        return outboundLanes[_toChainId].toDockAddress != address(0);
    }

    function _addOutboundLaneInternal(
        uint64 _toChainId,
        address _toDockAddress
    ) internal virtual {
        require(
            outboundLaneExists(_toChainId) == false,
            "outboundLane already exists"
        );
        outboundLanes[_toChainId] = OutboundLane({
            toChainId: _toChainId,
            toDockAddress: _toDockAddress
        });
    }

    function inboundLaneExists(
        uint64 _fromChainId
    ) public view virtual returns (bool) {
        return inboundLanes[_fromChainId].fromDockAddress != address(0);
    }

    function _addInboundLaneInternal(
        uint64 _fromChainId,
        address _fromDockAddress
    ) internal virtual {
        require(
            inboundLaneExists(_fromChainId) == false,
            "inboundLane already exists"
        );
        inboundLanes[_fromChainId] = InboundLane({
            fromChainId: _fromChainId,
            fromDockAddress: _fromDockAddress
        });
    }

    function _callRemoteRecv(
        address _fromDappAddress,
        OutboundLane memory _outboundLane,
        address _toDappAddress,
        bytes memory _messagePayload,
        bytes memory _params
    ) internal virtual;

    function send(
        address _fromDappAddress,
        uint64 _toChainId,
        address _toDappAddress,
        bytes memory _payload,
        bytes memory _params
    ) public payable virtual {
        // check this is called by local msgport
        _requireCalledByMsgport();

        _callRemoteRecv(
            _fromDappAddress,
            outboundLanes[_toChainId],
            _toDappAddress,
            _payload,
            _params
        );
    }

    function _approveToRecv(
        address _fromDappAddress,
        InboundLane memory _inboundLane,
        address _toDappAddress,
        bytes memory _messagePayload
    ) internal virtual returns (bool);

    function recv(
        address _fromDappAddress,
        InboundLane memory _inboundLane,
        address _toDappAddress,
        bytes memory _message
    ) public virtual {
        require(
            msg.sender == localLevelMessagingContractAddress,
            "Dock: not called by local level messaging contract"
        );
        require(
            _approveToRecv(
                _fromDappAddress,
                _inboundLane,
                _toDappAddress,
                _message
            ),
            "!permitted"
        );

        // call local msgport to receive message
        LOCAL_MSGPORT.recv(
            _inboundLane.fromChainId,
            _fromDappAddress,
            _toDappAddress,
            _message
        );
    }

    function _requireCalledByMsgport() internal view virtual {
        // check this is called by local msgport
        require(
            msg.sender == address(LOCAL_MSGPORT),
            "not allowed to be called by others except local msgport"
        );
    }
}
