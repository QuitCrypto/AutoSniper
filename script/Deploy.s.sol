// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {AutoSniper} from "../src/AutoSniper.sol";

interface ImmutableCreate2Factory {
    function safeCreate2(bytes32 salt, bytes calldata initCode) external payable returns (address deploymentAddress);
}

contract Deploy is Script {
    ImmutableCreate2Factory immutable factory = ImmutableCreate2Factory(0x0000000000FFe8B47B3e2130213B802212439497);
    bytes initCode = type(AutoSniper).creationCode;
    bytes32 salt = 0x0000000000000000000000000000000000000000000000000000050014b4ddd3;

    function run() external {
        vm.startBroadcast();

        address sniperAddress = factory.safeCreate2(salt, initCode);
        AutoSniper sniper = AutoSniper(payable(sniperAddress));
        console2.log(address(sniper));

        vm.stopBroadcast();
    }
}