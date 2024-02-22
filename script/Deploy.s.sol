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
    bytes32 salt = 0xd6309d958328352620b8856c0b08bd64c82244d2acc4c2380244e509848dd111;

    function run() external {
        console2.logBytes32(keccak256(initCode));
        vm.startBroadcast(0xD6309D958328352620B8856c0b08Bd64C82244d2);

        address sniperAddress = factory.safeCreate2(salt, initCode);
        AutoSniper sniper = AutoSniper(payable(sniperAddress));
        console2.log(address(sniper));

        vm.stopBroadcast();
    }
}
