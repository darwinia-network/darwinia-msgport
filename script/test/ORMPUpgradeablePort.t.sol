// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Chains} from "create3-deploy/script/Chains.sol";
import "ORMP/src/ORMP.sol";
import "ORMP/src/interfaces/IORMP.sol";
import "ORMP/src/UserConfig.sol";

import "../../src/ports/ORMPUpgradeablePort.sol";
import "../../src/ports/base/FromPortLookup.sol";

contract ORMPUpgradeablePortTest is Test {
    using Chains for uint256;

    ORMPUpgradeablePort ormpPort;
    address dao;
    address ormpProtocol;

    function setUp() public {
        uint256 chainId = Chains.Darwinia;
        vm.createSelectFork(chainId.toChainName());
        dao = address(0x1);
        ormpProtocol = vm.envOr("ORMP_ADDRESS", 0x00000000001523057a05d6293C1e5171eE33eE0A);
        ormpPort = new ORMPUpgradeablePort(dao, vm.envOr("ORMP_ADDRESS", ormpProtocol), "ORMP");
    }

    function testSetUri() public {
        string memory testUri = "https://test.uri";
        vm.prank(dao);
        ormpPort.setURI(testUri);
        assertEq(ormpPort.uri(), testUri);
        // Cannot
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        vm.prank(address(0));
        ormpPort.setURI("https://test.uri");
    }

    function testSetAppConfig() public {
        vm.prank(dao);
        ormpPort.setAppConfig(ormpProtocol, address(0x2), address(0x3));
        UC memory uc = IORMP(vm.envOr("ORMP_ADDRESS", address(ormpProtocol))).getAppConfig(address(ormpPort));
        assertEq(uc.oracle, address(0x2));
        assertEq(uc.relayer, address(0x3));
        // Cannot
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        vm.prank(address(0));
        ormpPort.setAppConfig(ormpProtocol, address(0x2), address(0x3));
    }

    function testSetPort() public {
        // From port
        vm.prank(dao);
        ormpPort.setFromPort(1, address(0x1));
        vm.prank(dao);
        ormpPort.setFromPort(2, address(0x2));
        assertEq(PortLookup(ormpPort).fromPortLookup(1), address(0x1));
        assertEq(PortLookup(ormpPort).fromPortLookup(2), address(0x2));
        // To port
        vm.prank(dao);
        ormpPort.setToPort(3, address(0x3));
        vm.prank(dao);
        ormpPort.setToPort(4, address(0x4));
        assertEq(PortLookup(ormpPort).toPortLookup(3), address(0x3));
        assertEq(PortLookup(ormpPort).toPortLookup(4), address(0x4));
        // Cannot
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ormpPort.setFromPort(5, address(0x5));
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        ormpPort.setFromPort(6, address(0x6));
    }

    function testSend() public {
        uint256 toChainId = 42161;
        vm.prank(dao);
        ormpPort.setToPort(toChainId, address(0x1));
        address toDapp = address(0x1837ff30801F1793563451101350A5f5e14a0a1a);
        address refund = address(0x9F33a4809aA708d7a399fedBa514e0A0d15EfA85);
        bytes memory message = bytes(
            "0xd8e68172000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000021234000000000000000000000000000000000000000000000000000000000000"
        );
        bytes memory params = bytes("0x");
        bytes memory adapterParams = abi.encode(500000, refund, params);
        uint256 fee = ormpPort.fee(toChainId, toDapp, message, adapterParams);
        ormpPort.send{value: fee}(toChainId, toDapp, message, adapterParams);
    }
}
