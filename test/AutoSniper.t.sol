// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/AutoSniper.sol";

interface IAutoSniper {
    function fulfillOrder(SniperOrder calldata order, uint256 wethAmount) external;
    function configureMarket(address marketplace, bool status) external;
    function deposit(address sniper) external payable;
    function sniperBalances(address sniper) external view returns (uint256);
    function owner() external view returns (address);
    function withdraw(uint256 amount) external;
    function setUserAllowedMarketplaces(bool guardEnabled, bool marketplaceAllowed, address[] calldata marketplaces) external;
    function setUserMaxTip(uint256 maxTipInWei) external;
    function setUserAllowedNfts(bool guardEnabled, bool nftAllowed, address[] calldata nfts) external;
}

contract AutoSniperTest is Test {
    // AutoSniper sniper;
    address seaport = 0x00000000000001ad428e4906aE43D8F9852d0dD6;
    address looksrare = 0xD112466471b5438C1ca2D218694200e49d81D047;
    address x2y2 = 0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3;
    address blur = 0x000000000000Ad05Ccc4F10045630fb830B95127;
    address quit = 0xC218D847a18E521Ae08F49F7c43882b6d1963c60;
    address AUTOSNIPER_CONTRACT_ADDRESS = 0x3d326Db044A62cA554498a883B0E90a473db3C8B;
    IAutoSniper deployedSniper = IAutoSniper(AUTOSNIPER_CONTRACT_ADDRESS);
    address contractAddress = 0x59Ad67e9c6a84e602BC73B3A606F731CC6dF210d;
    uint256 tokenId = 8728;
    address fulfiller = 0x816B65bd147df5C2566d2C9828815E85ff6055c6;
    address WETH_CONTRACT_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 amount = 490000000000000000;
    uint256 tip = 6000000000000000;
    uint256 coinbaseTip = 6000000000000000;
    Claim[] claims;
    bytes hexData = hex'000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000675c9c89ef1c00000000000000000000000000038b53b1476d784f1c8392e76c99e6560a60cd30a000000000000000000000000004c00500000ad104d7dbd00e3ae0a5c00560c0000000000000000000000000059ad67e9c6a84e602bc73b3a606f731cc6df210d0000000000000000000000000000000000000000000000000000000000002218000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000064042ba200000000000000000000000000000000000000000000000000000000640820220000000000000000000000000000000000000000000000000000000000000000360c6ebe00000000000000000000000000000000000000009a36337101ac7b5f0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f00000000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f00000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000024000000000000000000000000000000000000000000000000000000000000002a0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000570a9ec4ff4000000000000000000000000000ea803944e87142d44b945b3f5a0639f442ba361b000000000000000000000000000000000000000000000000000000000000006383c628a6578d7d8dc0a622eb7da0f370ff1f33ff9364efdfa88451720f35423fe8274e4e836d7d0d028cd911ac6e554a1711be1eb4bfd692e0aa29ba3016222500000170ba582795775332f8e3a7a21d108694edc7bc785fefcb32d77f0c97c4a1fa110000000000000000000000000000000000000000000000000000000000';
    bytes blurHexData = hex'9a1fc3a7000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000003e000000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000000000000000000000000000000000000000001c16de0b74d27e5e8cd06c1dc6f2390ab7e1c4af86659978775bcbf652dfc46d525a5eac5b832c911dfc93b3d66ffe99450f2a1bdfe92c65462a04140589de533b000000000000000000000000000000000000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff82a0000000000000000000000000cfea8e38ad74ab181c20988166b8d74f8da22ef900000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000dab4a563819e8fd93dba3b25bc349500000000000000000000000059ad67e9c6a84e602bc73b3a606f731cc6df210d000000000000000000000000000000000000000000000000000000000000227a000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aac096cf84680000000000000000000000000000000000000000000000000000000000064015cd50000000000000000000000000000000000000000000000000000000064016ae500000000000000000000000000000000000000000000000000000000000001a000000000000000000000000000000000805b4f09abc80d82f5808880c0f7b1860000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000001f4000000000000000000000000ea803944e87142d44b945b3f5a0639f442ba361b000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000001b9d918f14a7a94186c0b65536a5ec3bf120db959cf6f90b8c726d103f6450253463f0813e18162752580e25c5d5b7bd537edf8e2572bb68a6a12225482d67102500000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff82a00000000000000000000000003d326db044a62ca554498a883b0e90a473db3c8b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dab4a563819e8fd93dba3b25bc349500000000000000000000000059ad67e9c6a84e602bc73b3a606f731cc6df210d000000000000000000000000000000000000000000000000000000000000227a000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aac096cf84680000000000000000000000000000000000000000000000000000000000064015cd60000000000000000000000000000000000000000000000000000000064016e9700000000000000000000000000000000000000000000000000000000000001a00000000000000000000000000000000076a30cd72f4eabaf1e26effd108ffe4300000000000000000000000000000000000000000000000000000000000001c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000001bd499f0ca67afd2094558e0b629c9375c37a3e35a6f579a542e8e3f27778e1de137adae378f935edae6f985c7d2d0d6f0e1ce63d91230b397dd44aa308d7bf1d4';
    uint256 blurPrice = 0.769 ether;
    address blurTokenAddress = 0x59Ad67e9c6a84e602BC73B3A606F731CC6dF210d;
    uint256 blurTokenId = 8826;

    address[] globalMarketplaces;
    address[] userMarketplaces;
    address[] nfts;

    Claim claim = Claim(
        ItemType(2),
        0xc5B52253f5225835cc81C52cdb3d6A22bc3B0c93,
        9039,
        hex'1ff847bd00000000000000000000000000000000000000000000000000000000000002ee000000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000005'
    );

    SniperOrder order = SniperOrder(
        quit,
        seaport,
        amount,
        tip,
        // coinbaseTip,
        ItemType(2),
        hexData,
        contractAddress,
        tokenId
    );

    SniperOrder blurOrder = SniperOrder(
        quit,
        blur,
        blurPrice,
        tip,
        // coinbaseTip,
        ItemType(2),
        blurHexData,
        blurTokenAddress,
        blurTokenId
    );


    function setUp() public {
        // sniper = new AutoSniper(fulfiller, WETH_CONTRACT_ADDRESS);
        // startHoax(sniper.owner());
        // globalMarketplaces.push(seaport);
        // globalMarketplaces.push(looksrare);
        // globalMarketplaces.push(blur);
        // globalMarketplaces.push(x2y2);
        // sniper.configureMarkets(globalMarketplaces, true);

        // vm.stopPrank();
        // uint256 balance = sniper.sniperBalances(quit);
        // hoax(quit);
        // sniper.withdraw(balance);
        // sniper.deposit{value: 5 ether}(quit);
        // assertEq(sniper.sniperBalances(quit), 5 ether);
    }

    // function testBlurDirect() public {
    //     vm.deal(fulfiller, 100 ether);
    //     hoax(fulfiller);
    //     (bool success, ) = blur.call{value: blurPrice}(blurHexData);
    //     assertTrue(success);
    // }

    // function testBlurThroughContract() public {
    //     vm.deal(fulfiller, 100 ether);
    //     deployedSniper.deposit{value: 50 ether}(quit);
    //     hoax(deployedSniper.owner());
    //     deployedSniper.configureMarket(blur, true);
    //     hoax(fulfiller);
    //     deployedSniper.fulfillOrder(blurOrder, 0);
    // }

//     function testFulfillerModifier() public {
//         vm.expectRevert(CallerNotFulfiller.selector);
//         sniper.fulfillOrder(order, claims, 0);

//         hoax(fulfiller);
//         sniper.fulfillOrder(order, claims, 0);
//     }

    // function testExecute() public {
    //     hoax(fulfiller);
    //     sniper.fulfillOrder(order, claims, 0);
    // }

    function testExecuteOnDeployed() public {
        hoax(fulfiller);
        deployedSniper.fulfillOrder(order, 0);
    }

//     function testExecuteAndClaim() public {
//         hoax(fulfiller);
//         claims.push(claim);
//         sniper.fulfillOrder(order, claims, 0);
//     }

//     function testRefundOnOverpay() public {
//         uint256 balanceBefore = sniper.sniperBalances(quit);
//         testExecute();
//         assertEq(balanceBefore - sniper.sniperBalances(quit), amount + tip + coinbaseTip);
//     }

//     function testWethSubsidy() public {
//         uint256 balance = sniper.sniperBalances(quit);
//         hoax(quit);
//         sniper.withdraw(balance);
//         assertEq(sniper.sniperBalances(quit), 0);
//         IWETH weth = IWETH(WETH_CONTRACT_ADDRESS);
//         hoax(quit);
//         weth.deposit{value: balance}();
//         assertEq(weth.balanceOf(quit), balance);

//         hoax(quit);
//         weth.approve(address(sniper), balance);

//         hoax(fulfiller);
//         sniper.fulfillOrder(order, claims, balance);
//         assertEq(weth.balanceOf(quit), 0);
//     }

//     function testMarketplaceBoolean() public {
//         hoax(quit);
//         sniper.setUserAllowedMarketplaces(true, true, userMarketplaces);

//         vm.expectRevert(MarketplaceNotAllowed.selector);
//         testExecute();

//         hoax(quit);
//         sniper.setUserAllowedMarketplaces(false, true, userMarketplaces);
//         testExecute();
//     }

//     function testMarketplaceArray() public {
//         hoax(quit);
//         sniper.setUserAllowedMarketplaces(true, true, userMarketplaces);

//         vm.expectRevert(MarketplaceNotAllowed.selector);
//         testExecute();
//         userMarketplaces.push(seaport);
//         hoax(quit);
//         sniper.setUserAllowedMarketplaces(true, true, userMarketplaces);
//         testExecute();
//     }

//     function testMaxTip() public {
//         hoax(quit);
//         vm.expectRevert(TipBelowMinimum.selector);
//         sniper.setUserMaxTip(0.003 ether);

//         hoax(quit);
//         sniper.setUserMaxTip(0.005 ether);

//         vm.expectRevert(MaxTipExceeded.selector);
//         testExecute();

//         hoax(quit);
//         sniper.setUserMaxTip(5 ether);
//         testExecute();
//     }

//     function testNftBoolean() public {
//         hoax(quit);
//         sniper.setUserAllowedNfts(true, true, nfts);

//         vm.expectRevert(TokenContractNotAllowed.selector);
//         testExecute();

//         hoax(quit);
//         sniper.setUserAllowedNfts(false, true, nfts);
//         testExecute();
//     }

//     function testNftArray() public {
//         hoax(quit);
//         sniper.setUserAllowedNfts(true, true, nfts);

//         vm.expectRevert(TokenContractNotAllowed.selector);
//         testExecute();
//         nfts.push(contractAddress);
//         hoax(quit);
//         sniper.setUserAllowedNfts(true, true, nfts);
//         testExecute();
//     }
}
