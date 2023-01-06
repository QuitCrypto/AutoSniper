// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/AutoSniper.sol";

interface IAutoSniper {
    function fulfillOrder(SniperOrder calldata order, uint256 wethAmount) external;
    function configureMarket(address marketplace, bool status) external;
    function deposit(address sniper) external payable;
    function sniperBalances(address sniper) external view returns (uint256);
    function owner() external view returns (address);
}

contract AutoSniperTest is Test {
    AutoSniper sniper;
    address seaport = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
    address looksrare = 0xD112466471b5438C1ca2D218694200e49d81D047;
    address quit = 0x5C04911bA3a457De6FA0357b339220e4E034e8F7;
    address contractAddress = 0x73dE86945Ba818dC2035BA662E7b7E599Eb807e8;
    uint256 tokenId = 27;
    address fulfiller = address(5);
    uint256 amount = 30000000000000000;
    // IAutoSniper sniper;

    address[] marketplaces;
    address[] nfts;

    SniperOrder order = SniperOrder(
        quit,
        looksrare,
        amount,
        5000000000000000,
        ItemType(2),
        hex"b4e4b2960000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005674f1ef67c1d26a4a37da8e4e44f4203f3b72ce000000000000000000000000000000000000000000000000006a94d74f430000000000000000000000000000000000000000000000000000000000000000001b000000000000000000000000000000000000000000000000000000000000264800000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000045a76bba2ab8bcf1e8e7e7f52c2d7f3d8fc952d800000000000000000000000073de86945ba818dc2035ba662e7b7e599eb807e8000000000000000000000000000000000000000000000000006a94d74f430000000000000000000000000000000000000000000000000000000000000000001b00000000000000000000000000000000000000000000000000000000000000010000000000000000000000006acbeb7f6e225fbc0d1cee27a40adc49e7277e57000000000000000000000000b4fbf271143f4fbf7b91a5ded31805e42b2208d600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000063b73d970000000000000000000000000000000000000000000000000000000063dec86500000000000000000000000000000000000000000000000000000000000026480000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001c3acb17f2b40f709665a0e76b77b31d35c1f79318ae8297c0239c3868e23595da4da41b10f74acf57e4c389ab40742220f61189e8548dd0405c3aeeea48e833f50000000000000000000000000000000000000000000000000000000000000000",
        contractAddress,
        tokenId
    );

    function setUp() public {
        sniper = new AutoSniper(fulfiller);
        sniper.configureMarket(seaport, true);
        sniper.configureMarket(looksrare, true);
        sniper.deposit{value: 500000000000000000}(quit);
        assertEq(sniper.sniperBalances(quit), 500000000000000000);
    }

    function testFulfillerModifier() public {
        vm.expectRevert(CallerNotFulfiller.selector);
        sniper.fulfillOrder(order, 0);

        hoax(fulfiller);
        sniper.fulfillOrder(order, 0);
    }

    function testExecute() public {
        hoax(fulfiller);
        sniper.fulfillOrder(order, 0);
    }

    function testWethSubsidy() public {
        uint256 balance = sniper.sniperBalances(quit);
        hoax(quit);
        sniper.withdraw(balance);
        assertEq(sniper.sniperBalances(quit), 0);
        IWETH weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        hoax(quit);
        weth.deposit{value: balance}();
        assertEq(weth.balanceOf(quit), balance);

        hoax(quit);
        weth.approve(address(sniper), balance);

        hoax(fulfiller);
        sniper.fulfillOrder(order, balance);
        assertEq(weth.balanceOf(quit), 0);
    }

    function testMarketplaceBoolean() public {
        hoax(quit);
        sniper.setUserAllowedMarketplaces(true, true, marketplaces);

        vm.expectRevert(MarketplaceNotAllowed.selector);
        testExecute();

        hoax(quit);
        sniper.setUserAllowedMarketplaces(false, true, marketplaces);
        testExecute();
    }

    function testMarketplaceArray() public {
        hoax(quit);
        sniper.setUserAllowedMarketplaces(true, true, marketplaces);

        vm.expectRevert(MarketplaceNotAllowed.selector);
        testExecute();
        marketplaces.push(seaport);
        hoax(quit);
        sniper.setUserAllowedMarketplaces(true, true, marketplaces);
        testExecute();
    }

    function testMaxTip() public {
        hoax(quit);
        vm.expectRevert(TipBelowMinimum.selector);
        sniper.setUserMaxTip(0.003 ether);

        hoax(quit);
        sniper.setUserMaxTip(0.005 ether);

        vm.expectRevert(MaxTipExceeded.selector);
        testExecute();

        hoax(quit);
        sniper.setUserMaxTip(5 ether);
        testExecute();
    }

    function testNftBoolean() public {
        hoax(quit);
        sniper.setUserAllowedNfts(true, true, nfts);

        vm.expectRevert(TokenContractNotAllowed.selector);
        testExecute();

        hoax(quit);
        sniper.setUserAllowedNfts(false, true, nfts);
        testExecute();
    }

    function testNftArray() public {
        hoax(quit);
        sniper.setUserAllowedNfts(true, true, nfts);

        vm.expectRevert(TokenContractNotAllowed.selector);
        testExecute();
        nfts.push(contractAddress);
        hoax(quit);
        sniper.setUserAllowedNfts(true, true, nfts);
        testExecute();
    }
}
