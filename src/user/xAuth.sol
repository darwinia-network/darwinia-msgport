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

import "../user/Application.sol";
import "../interfaces/ILineRegistry.sol";

abstract contract xAuth is Application {
    function xOwner() public virtual returns (uint256, address);
    function registry() public virtual returns (address);

    function _checkXAuth() internal virtual {
        address line = _msgLine();
        uint256 fromChainId = _fromChainId();
        (uint256 chainId, address owner) = xOwner();
        require(fromChainId != block.chainid, "!fromChainId");
        require(ILineRegistry(registry()).isTrustedLine(line), "!line");
        require(fromChainId == chainId, "!xOwner");
        require(_xmsgSender() == owner, "!xOwner");
    }
}