// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./interfaces/IMessagePort.sol";
import "./interfaces/IMessageReceiver.sol";
import "./interfaces/BaseMessageDock.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract MessagePort is IMessagePort, Ownable2Step {
    uint64 public localChainId;

    // remoteChainId => localDockAddress[]
    mapping(uint64 => address[]) public localDockAddressesByToChainId;

    constructor(uint64 _localChainId) {
        localChainId = _localChainId;
    }

    receive() external payable {}

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getLocalChainId() external view returns (uint64) {
        return localChainId;
    }

    function getLocalDockAddressesByToChainId(
        uint64 _toChainId
    ) external view returns (address[] memory) {
        return localDockAddressesByToChainId[_toChainId];
    }

    function addLocalDock(
        uint64 _remoteChainId,
        address _localDockAddress
    ) external onlyOwner {
        require(
            !localDockExists(_remoteChainId, _localDockAddress),
            "Dock already exists"
        );

        localDockAddressesByToChainId[_remoteChainId].push(_localDockAddress);
    }

    function localDockExists(
        uint64 _remoteChainId,
        address _localDockAddress
    ) public view returns (bool) {
        address[] memory localDockAddresses = localDockAddressesByToChainId[
            _remoteChainId
        ];
        bool exists = false;
        for (uint i = 0; i < localDockAddresses.length; i++) {
            if (localDockAddresses[i] == _localDockAddress) {
                exists = true;
                break;
            }
        }
        return exists;
    }

    // called by Dapp.
    function send(
        address _throughLocalDockAddress,
        uint64 _toChainId,
        address _toDappAddress,
        bytes memory _messagePayload,
        bytes memory _params
    ) external payable returns (uint256) {
        // check if local dock exists
        require(
            localDockExists(_toChainId, _throughLocalDockAddress),
            "Local dock not exists"
        );

        BaseMessageDock dock = BaseMessageDock(_throughLocalDockAddress);

        dock.send{value: msg.value}(
            msg.sender, // fromDappAddress
            _toChainId,
            _toDappAddress,
            _messagePayload,
            _params
        );

        return dock.getOutboundLaneNonce(_toChainId);
    }

    // called by dock.
    //
    // catch the error if user's recv function failed with uncaught error.
    // store the message and error for the user to do something like retry.
    function recv(
        uint64 _fromChainId,
        address _fromDappAddress,
        address _toDappAddress,
        bytes memory _messagePayload,
        uint256 _nonce
    ) external {
        require(
            localDockExists(_fromChainId, msg.sender),
            "Local dock not exists"
        );

        try
            IMessageReceiver(_toDappAddress).recv(
                _fromChainId,
                _fromDappAddress,
                _messagePayload,
                _nonce
            )
        {} catch Error(string memory reason) {
            emit DappError(
                _fromChainId,
                _fromDappAddress,
                _toDappAddress,
                _messagePayload,
                reason
            );
        } catch (bytes memory reason) {
            emit DappError(
                _fromChainId,
                _fromDappAddress,
                _toDappAddress,
                _messagePayload,
                string(reason)
            );
        }
    }
}