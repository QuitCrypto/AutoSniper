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
    bytes32 salt = 0x0000000000000000000000000000000000000000febd6dd69b3a5531c3584048;

    address[] marketplaces;

    function run() external {
        marketplaces.push(0xB258CA5559b11cD702F363796522b04D7722Ea56); // new blend
        marketplaces.push(0xb2ecfE4E4D61f8790bbb9DE2D1259B9e2410CEA5); // blur v2
        marketplaces.push(0x29469395eAf6f95920E59F858042f0e28D98a20B); // old blend
        marketplaces.push(0x00000000000000ADc04C56Bf30aC9d3c0aAF14dC); // seaport
        marketplaces.push(0x0000000000E655fAe4d56241588680F86E3b2377); // looksrare
        marketplaces.push(0x000000000000Ad05Ccc4F10045630fb830B95127); // blur (old)
        marketplaces.push(0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3); // X2Y2

        vm.startBroadcast();

        address sniperAddress = factory.safeCreate2(salt, initCode);
        AutoSniper sniper = AutoSniper(payable(sniperAddress));
        console2.log(address(sniper));

        AutoSniper oldSniper = AutoSniper(payable(0x0000000001474228ae1223661ef7Ab0d89773B0A));
        oldSniper.setMigrationAddress(address(sniper));
        sniper.configureMarkets(marketplaces, true);

        vm.stopBroadcast();
    }
}