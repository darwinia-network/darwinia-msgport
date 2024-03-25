// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {stdJson} from "forge-std/StdJson.sol";
import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {Common} from "create3-deploy/script/Common.s.sol";
import {ScriptTools} from "create3-deploy/script/ScriptTools.sol";

import "../../src/ports/ORMPUpgradeablePort.sol";

interface III {
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
    function pendingOwner() external view returns (address);
}

contract DeployORMPUPort is Common {
    using stdJson for string;
    using ScriptTools for string;

    address ORMP;
    address ADDR;
    bytes32 SALT;

    string c3;
    string config;
    string instanceId;
    string outputName;
    address deployer;
    address dao;

    function name() public pure override returns (string memory) {
        return "DeployORMPUPort";
    }

    function setUp() public override {
        super.setUp();

        instanceId = vm.envOr("INSTANCE_ID", string("deploy_ormp_port.c"));
        outputName = "deploy_ormp_port.a";
        config = ScriptTools.readInput(instanceId);
        c3 = ScriptTools.readInput("../c3");
        ORMP = c3.readAddress(".ORMP_ADDR");
        ADDR = c3.readAddress(".ORMPUPORT_ADDR");
        SALT = c3.readBytes32(".ORMPUPORT_SALT");

        deployer = config.readAddress(".DEPLOYER");
        dao = config.readAddress(".DAO");
    }

    function run() public {
        require(deployer == msg.sender, "!deployer");

        deploy();
        // setConfig();

        ScriptTools.exportContract(outputName, "DAO", dao);
        ScriptTools.exportContract(outputName, "ORMP_PORT", ADDR);
    }

    function deploy() public broadcast returns (address) {
        string memory name_ = config.readString(".metadata.name");
        bytes memory byteCode = type(ORMPUpgradeablePort).creationCode;
        bytes memory initCode = bytes.concat(byteCode, abi.encode(deployer, ORMP, name_));
        address port = _deploy3(SALT, initCode);
        require(port == ADDR, "!addr");
        require(III(ADDR).owner() == deployer);
        console.log("ORMPUpgradeablePort deployed: %s", port);
        return port;
    }

    function setConfig() public broadcast {
        III(ADDR).transferOwnership(dao);
        require(III(ADDR).pendingOwner() == dao, "!dao");
        // TODO:: dao.acceptOwnership()
    }
}
