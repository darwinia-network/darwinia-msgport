// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {stdJson} from "forge-std/StdJson.sol";
import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {Common} from "create3-deploy/script/Common.s.sol";
import {ScriptTools} from "create3-deploy/script/ScriptTools.sol";

import "../../src/PortRegistry.sol";
import "../../src/PortRegistryProxy.sol";

interface III {
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
    function pendingOwner() external view returns (address);
}

contract DeployPortRegistry is Common {
    using stdJson for string;
    using ScriptTools for string;

    address ADDR;
    bytes32 SALT;

    string c3;
    string config;
    string instanceId;
    string outputName;
    address deployer;
    address dao;

    function name() public pure override returns (string memory) {
        return "DeployPortRegistry";
    }

    function setUp() public override {
        super.setUp();

        instanceId = vm.envOr("INSTANCE_ID", string("deploy_port_registry.c"));
        outputName = "deploy_port_registry.a";
        config = ScriptTools.readInput(instanceId);
        c3 = ScriptTools.readInput("../c3");
        ADDR = c3.readAddress(".PORTREGISTRY_ADDR");
        SALT = c3.readBytes32(".PORTREGISTRY_SALT");

        deployer = config.readAddress(".DEPLOYER");
        dao = config.readAddress(".DAO");
    }

    function run() public {
        require(deployer == msg.sender, "!deployer");

        deploy();
        // setConfig();

        ScriptTools.exportContract(outputName, "DAO", dao);
        ScriptTools.exportContract(outputName, "PORT_REGISTRY", ADDR);
    }

    function deploy() public broadcast returns (address) {
        PortRegistry logic = new PortRegistry();

        bytes memory byteCode = type(PortRegistryProxy).creationCode;
        bytes memory initData = abi.encodeWithSelector(PortRegistry.initialize.selector, deployer);
        bytes memory initCode = bytes.concat(byteCode, abi.encode(address(logic), initData));
        address registry = _deploy3(SALT, initCode);
        require(registry == ADDR, "!addr");
        require(III(ADDR).owner() == deployer);
        console.log("PortRegistry deployed: %s", ADDR);
        return ADDR;
    }

    function setConfig() public broadcast {
        III(ADDR).transferOwnership(dao);
        require(III(ADDR).pendingOwner() == dao, "!dao");
        // TODO:: dao.acceptOwnership()
    }
}
