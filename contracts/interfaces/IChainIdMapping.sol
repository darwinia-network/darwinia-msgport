// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

pragma solidity ^0.8.0;

// TODO: mapping or if else
interface IChainIdMapping {
    error MsgportChainIdNotFound(uint64 msgportChainId);
    error LowLevelChainIdNotFound(bytes lowLevelChainId);

    function down(
        uint64 msgportChainId
    ) external view returns (bytes memory lowLevelChainId);

    function up(
        bytes memory lowLevelChainId
    ) external view returns (uint64 msgportChainId);
}
