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
    address contractAddress = 0x38C6C7B9a65Bfe7150FE493a678669a9E5B7652E;
    uint256 tokenId = 0;
    address fulfiller = address(5);
    uint256 amount = 30000000000000000;
    uint256 tip = 6000000000000000;
    // IAutoSniper sniper;

    address[] marketplaces;
    address[] nfts;

    SniperOrder order = SniperOrder(
        quit,
        seaport,
        amount,
        tip,
        ItemType(3),
        hex"e7acab24000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000005800000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f00000000000000000000000000005615deb798bb3e4dfa0139dfa1b3d433cc23b72f00000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000001f4000000000000000000000000000000000000000000000000000000000000046000000000000000000000000000000000000000000000000000000000000004e00000000000000000000000007607a6ec8d35623031f0f02257fd0d53337c092f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000063bc0dce0000000000000000000000000000000000000000000000000000000063e4ec4e0000000000000000000000000000000000000000000000000000000000000000360c6ebe00000000000000000000000000000000000000005f6de71986fc204a0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000300000000000000000000000038c6c7b9a65bfe7150fe493a678669a9e5b7652e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001f400000000000000000000000000000000000000000000000000000000000001f400000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000616c0cce733e0000000000000000000000000000000000000000000000000000616c0cce733e0000000000000000000000000007607a6ec8d35623031f0f02257fd0d53337c092f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000027f7d0bdb920000000000000000000000000000000000000000000000000000027f7d0bdb920000000000000000000000000000000a26b00c1f0df003000390027140000faa719000000000000000000000000000000000000000000000000000000000000004135c29bed404ca043af87a343560d187776b45618ebaac82dc1e8f9f6e12f22025157bd3e8db25fda111488153eb2471db073c7ee3be7d3862e42b4a74664f2f61b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
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

    function testRefundOnOverpay() public {
        uint256 balanceBefore = sniper.sniperBalances(quit);
        testExecute();
        assertEq(balanceBefore - sniper.sniperBalances(quit), 0.0009 ether + tip);
    }

    function testWethSubsidy() public {
        uint256 balance = sniper.sniperBalances(quit);
        hoax(quit);
        sniper.withdraw(balance);
        assertEq(sniper.sniperBalances(quit), 0);
        IWETH weth = IWETH(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);
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
