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

pragma solidity 0.8.17;

import "./base/BaseMessagePort.sol";
import "./base/PortLookup.sol";
import "ORMP/src/interfaces/IORMP.sol";
import "ORMP/src/user/AppBase.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract ORMPUpgradeablePort is Ownable2Step, AppBase, BaseMessagePort, PortLookup {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public ormp;

    EnumerableSet.AddressSet internal historyORMPSet;

    event SetORMP(address previousORMP, address currentORMP);
    event HistoryORMPAdded(address ormp);
    event HistoryORMPDeleted(address ormp);

    modifier onlyORMP() override {
        require(historyORMPSet.contains(msg.sender), "!ormps");
        _;
    }

    constructor(address dao, address ormp_, string memory name) BaseMessagePort(name) {
        _transferOwnership(dao);
        ormp = ormp_;
        historyORMPSet.add(ormp_);
    }

    /// @notice How to migrate to new ORMP contract.
    /// 1. setORMP to new ORMP contract.
    /// 2. delete previousORMP after relay on-flight message.
    function setORMP(address ormp_) external onlyOwner {
        address previousORMP = ormp;
        ormp = ormp_;
        require(historyORMPSet.add(ormp_), "!add");
        emit SetORMP(previousORMP, ormp_);
        emit HistoryORMPAdded(ormp_);
    }

    function delORMP(address ormp_) external onlyOwner {
        require(ormp != ormp_, "sender");
        require(historyORMPSet.remove(ormp_), "!del");
        emit HistoryORMPDeleted(ormp_);
    }

    function setAppConfig(address ormp_, address oracle, address relayer) external onlyOwner {
        require(historyORMPSet.contains(ormp_), "!exist");
        IORMP(ormp_).setAppConfig(oracle, relayer);
    }

    function setURI(string calldata uri) external onlyOwner {
        _setURI(uri);
    }

    function setToPort(uint256 _toChainId, address _toPortAddress) external onlyOwner {
        _setToPort(_toChainId, _toPortAddress);
    }

    function setFromPort(uint256 _fromChainId, address _fromPortAddress) external onlyOwner {
        _setFromPort(_fromChainId, _fromPortAddress);
    }

    function historyORMPLength() public view returns (uint256) {
        return historyORMPSet.length();
    }

    function historyORMPs() public view returns (address[] memory) {
        return historyORMPSet.values();
    }

    function historyORMPAt(uint256 index) public view returns (address) {
        return historyORMPSet.at(index);
    }

    function historyORMPContains(address ormp_) public view returns (bool) {
        return historyORMPSet.contains(ormp_);
    }

    function _send(address fromDapp, uint256 toChainId, address toDapp, bytes calldata message, bytes calldata params)
        internal
        override
    {
        (uint256 gasLimit, address refund, bytes memory ormpParams) = abi.decode(params, (uint256, address, bytes));
        bytes memory encoded = abi.encodeWithSelector(this.recv.selector, fromDapp, toDapp, message);
        IORMP(ormp).send{value: msg.value}(toChainId, _checkedToPort(toChainId), gasLimit, encoded, refund, ormpParams);
    }

    function recv(address fromDapp, address toDapp, bytes calldata message) public payable virtual onlyORMP {
        uint256 fromChainId = _fromChainId();
        require(_xmsgSender() == _checkedFromPort(fromChainId), "!auth");
        _recv(fromChainId, fromDapp, toDapp, message);
    }

    function fee(uint256 toChainId, address toDapp, bytes calldata message, bytes calldata params)
        external
        view
        override
        returns (uint256)
    {
        (uint256 gasLimit,, bytes memory ormpParams) = abi.decode(params, (uint256, address, bytes));
        bytes memory encoded = abi.encodeWithSelector(this.recv.selector, msg.sender, toDapp, message);
        return IORMP(ormp).fee(toChainId, address(this), gasLimit, encoded, ormpParams);
    }
}
