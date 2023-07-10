// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/AutoSniper.sol";
import "./mocks/ClaimableERC721.sol";
import "./mocks/MintableERC721.sol";
import "./mocks/Marketplace.sol";
import "./mocks/Weth.sol";
import {MaliciousCoinbaseWithdraw} from "./mocks/MaliciousCoinbaseWithdraw.sol";
import {MaliciousCoinbaseDeposit} from "./mocks/MaliciousCoinbaseDeposit.sol";

interface IAutoSniper {
    function fulfillOrder(SniperOrder calldata order, uint256 wethAmount) external;
    function configureMarket(address marketplace, bool status) external;
    function deposit(address sniper) external payable;
    function sniperBalances(address sniper) external view returns (uint256);
    function owner() external view returns (address);
    function withdraw(uint256 mockPrice) external;
    function setUserAllowedMarketplaces(bool guardEnabled, bool marketplaceAllowed, address[] calldata marketplaces) external;
    function setUserMaxTip(uint256 maxTipInWei) external;
    function setUserAllowedNfts(bool guardEnabled, bool nftAllowed, address[] calldata nfts) external;
}

contract AutoSniperTest is Test {
    event Snipe(
        SniperOrder order,
        Claim[] claims
    );

    AutoSniper sniper;
    MintableERC721 mock721;
    ClaimableERC721 mockClaimable;
    Marketplace mockMarketplace;
    Weth weth;

    address seaport = 0x00000000000001ad428e4906aE43D8F9852d0dD6;
    address looksrare = 0xD112466471b5438C1ca2D218694200e49d81D047;
    address x2y2 = 0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3;
    address blur = 0x000000000000Ad05Ccc4F10045630fb830B95127;
    address quit = 0xC218D847a18E521Ae08F49F7c43882b6d1963c60;
    address zeroBalanceSniper = address(101);

    address AUTOSNIPER_CONTRACT_ADDRESS = 0x3d326Db044A62cA554498a883B0E90a473db3C8B;
    IAutoSniper deployedSniper = IAutoSniper(AUTOSNIPER_CONTRACT_ADDRESS);
    address fulfiller = 0x7D79Bd0E4B3dC90665A3ed30Aa6C6c06c89D224E;
    address WETH_CONTRACT_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint72 tip = 0.006 ether;
    uint72 coinbaseTip = 0.006 ether;
    Claim[] claims;

    /** MOCK CONTRACT INPUTS */
    address mockContractAddress;
    uint256 mockTokenId = 1;
    uint72 mockPrice = 1 ether;

    bytes hexData = hex'000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000675c9c89ef1c00000000000000000000000000038b53b1476d784f1c8392e76c99e6560a60cd30a000000000000000000000000004c00500000ad104d7dbd00e3ae0a5c00560c0000000000000000000000000059ad67e9c6a84e602bc73b3a606f731cc6df210d0000000000000000000000000000000000000000000000000000000000002218000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000064042ba200000000000000000000000000000000000000000000000000000000640820220000000000000000000000000000000000000000000000000000000000000000360c6ebe00000000000000000000000000000000000000009a36337101ac7b5f0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f00000000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f00000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000024000000000000000000000000000000000000000000000000000000000000002a0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000570a9ec4ff4000000000000000000000000000ea803944e87142d44b945b3f5a0639f442ba361b000000000000000000000000000000000000000000000000000000000000006383c628a6578d7d8dc0a622eb7da0f370ff1f33ff9364efdfa88451720f35423fe8274e4e836d7d0d028cd911ac6e554a1711be1eb4bfd692e0aa29ba3016222500000170ba582795775332f8e3a7a21d108694edc7bc785fefcb32d77f0c97c4a1fa110000000000000000000000000000000000000000000000000000000000';
    address seaportContractAddress = 0x59Ad67e9c6a84e602BC73B3A606F731CC6dF210d;
    uint256 seaportTokenId = 8728;
    uint72 seaportPrice = 490000000000000000;

    bytes blurHexData = hex'9a1fc3a7000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000003e000000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000000000000000000000000000000000000000001c16de0b74d27e5e8cd06c1dc6f2390ab7e1c4af86659978775bcbf652dfc46d525a5eac5b832c911dfc93b3d66ffe99450f2a1bdfe92c65462a04140589de533b000000000000000000000000000000000000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff82a0000000000000000000000000cfea8e38ad74ab181c20988166b8d74f8da22ef900000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000dab4a563819e8fd93dba3b25bc349500000000000000000000000059ad67e9c6a84e602bc73b3a606f731cc6df210d000000000000000000000000000000000000000000000000000000000000227a000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aac096cf84680000000000000000000000000000000000000000000000000000000000064015cd50000000000000000000000000000000000000000000000000000000064016ae500000000000000000000000000000000000000000000000000000000000001a000000000000000000000000000000000805b4f09abc80d82f5808880c0f7b1860000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000001f4000000000000000000000000ea803944e87142d44b945b3f5a0639f442ba361b000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000001b9d918f14a7a94186c0b65536a5ec3bf120db959cf6f90b8c726d103f6450253463f0813e18162752580e25c5d5b7bd537edf8e2572bb68a6a12225482d67102500000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ff82a00000000000000000000000003d326db044a62ca554498a883b0e90a473db3c8b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dab4a563819e8fd93dba3b25bc349500000000000000000000000059ad67e9c6a84e602bc73b3a606f731cc6df210d000000000000000000000000000000000000000000000000000000000000227a000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aac096cf84680000000000000000000000000000000000000000000000000000000000064015cd60000000000000000000000000000000000000000000000000000000064016e9700000000000000000000000000000000000000000000000000000000000001a00000000000000000000000000000000076a30cd72f4eabaf1e26effd108ffe4300000000000000000000000000000000000000000000000000000000000001c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000001bd499f0ca67afd2094558e0b629c9375c37a3e35a6f579a542e8e3f27778e1de137adae378f935edae6f985c7d2d0d6f0e1ce63d91230b397dd44aa308d7bf1d4';
    uint72 blurPrice = 0.769 ether;
    address blurTokenAddress = 0x59Ad67e9c6a84e602BC73B3A606F731CC6dF210d;
    uint256 blurTokenId = 8826;

    address[] globalMarketplaces;
    address[] userMarketplaces;
    address[] nfts;

    address[] addresses;
    bytes[] calls;
    uint256[] values;

    Claim claim;

    SniperOrder order;

    SniperOrder seaportOrder = SniperOrder(
        ItemType(2),
        mockPrice,
        tip,
        coinbaseTip,
        quit,
        seaport,
        seaportContractAddress,
        seaportTokenId,
        hexData
    );

    SniperOrder blurOrder = SniperOrder(
        ItemType(2),
        blurPrice,
        tip,
        coinbaseTip,
        quit,
        blur,
        blurTokenAddress,
        blurTokenId,
        blurHexData
    );

    /** ========================================================== 
     *                         TESTS
     *  ==========================================================
     */
    function setUp() public {
        weth = new Weth();
        sniper = new AutoSniper();
        mock721 = new MintableERC721();
        mockClaimable = new ClaimableERC721();
        mockMarketplace = new Marketplace();
        mockContractAddress = address(mock721);

        mock721.mint(address(mockMarketplace));

        startHoax(sniper.owner());
        globalMarketplaces.push(seaport);
        globalMarketplaces.push(looksrare);
        globalMarketplaces.push(blur);
        globalMarketplaces.push(x2y2);
        globalMarketplaces.push(address(mockMarketplace));
        sniper.configureMarkets(globalMarketplaces, true);

        mockClaimable.setTokenContract(mockContractAddress);

        vm.stopPrank();
        uint256 balance = sniper.sniperBalances(quit);
        hoax(quit);
        sniper.withdraw(balance);
        sniper.deposit{value: 5 ether}(quit);
        assertEq(sniper.sniperBalances(quit), 5 ether);

        order = SniperOrder(
            ItemType(2),
            mockPrice,
            tip,
            coinbaseTip,
            quit,
            address(mockMarketplace),
            mockContractAddress,
            mockTokenId,
            abi.encodeWithSelector(Marketplace.buyErc721.selector, address(mock721), 1)
        );

        claim = Claim(
            ItemType(2),
            address(mockClaimable),
            1,
            abi.encodeWithSelector(ClaimableERC721.claim.selector, 1)
        );
    }

    function testFulfillNonCompliantMarketplaceOrder() public {
        vm.deal(fulfiller, 100 ether);
        startHoax(fulfiller);
        // FULFILL ORDER
        mockMarketplace.buyErc721(address(mock721), mockTokenId);

        // APPROVE NFT TO AUTOSNIPER CONTRACT
        mock721.setApprovalForAll(address(sniper), true);

        // SELL TO SNIPER
        sniper.fulfillNonCompliantMarketplaceOrder(order, claims, 0);

        assertEq(mock721.balanceOf(quit), 1);
    }

    function testFulfillerModifier() public {
        vm.expectRevert(CallerNotFulfiller.selector);
        sniper.fulfillOrder(order, claims, 0);

        hoax(fulfiller);
        sniper.fulfillOrder(order, claims, 0);
    }

    function testExecute() public {
        hoax(fulfiller);
        sniper.fulfillOrder(order, claims, 0);
    }

    function testExecuteAndClaim() public {
        hoax(fulfiller);
        claims.push(claim);
        sniper.fulfillOrder(order, claims, 0);
    }

    function testRefundOnOverpay() public {
        uint256 balanceBefore = sniper.sniperBalances(quit);
        testExecute();
        assertEq(balanceBefore - sniper.sniperBalances(quit), mockPrice + tip + coinbaseTip);
    }

    // function testWethSubsidy() public {
    //     uint256 balance = sniper.sniperBalances(quit);
    //     hoax(quit);
    //     sniper.withdraw(balance);
    //     assertEq(sniper.sniperBalances(quit), 0);
    //     hoax(quit);
    //     weth.deposit{value: balance}();
    //     assertEq(weth.balanceOf(quit), balance);

    //     hoax(quit);
    //     weth.approve(address(sniper), balance);

    //     hoax(fulfiller);
    //     sniper.fulfillOrder(order, claims, balance);
    //     assertEq(weth.balanceOf(quit), 0);
    // }

    function testMarketplaceBoolean() public {
        hoax(quit);
        sniper.setUserAllowedMarketplaces(true, true, userMarketplaces);

        vm.expectRevert(MarketplaceNotAllowed.selector);
        testExecute();

        hoax(quit);
        sniper.setUserAllowedMarketplaces(false, true, userMarketplaces);
        testExecute();
    }

    function testMarketplaceArray() public {
        hoax(quit);
        sniper.setUserAllowedMarketplaces(true, true, userMarketplaces);

        vm.expectRevert(MarketplaceNotAllowed.selector);
        testExecute();
        userMarketplaces.push(address(mockMarketplace));
        hoax(quit);
        sniper.setUserAllowedMarketplaces(true, true, userMarketplaces);
        testExecute();
    }

    function testMaxTip() public {
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
        nfts.push(mockContractAddress);
        hoax(quit);
        sniper.setUserAllowedNfts(true, true, nfts);
        testExecute();
    }

    function testMigrate() public {
        AutoSniper sniperv2 = new AutoSniper();

        hoax(quit);
        vm.expectRevert(MigrationNotEnabled.selector);
        sniper.migrateBalance();

        hoax(sniper.owner());
        sniper.setMigrationAddress(address(sniperv2));

        assertEq(sniper.sniperBalances(quit), 5 ether);
        assertEq(sniperv2.sniperBalances(quit), 0);
        hoax(quit);
        sniper.migrateBalance();

        assertEq(sniper.sniperBalances(quit), 0);
        assertEq(sniperv2.sniperBalances(quit), 5 ether);
    }

    function testSendDirectTipToCoinbase() public {
        vm.coinbase(address(5));
        
        startHoax(fulfiller);

        sniper.sendDirectTipToCoinbase{value: 5 ether}();

        assertEq(address(5).balance, 5 ether);
    }

    function testMaliciousCoinbaseAddressWithdraw() public {
        MaliciousCoinbaseWithdraw coinbase = new MaliciousCoinbaseWithdraw();
        coinbase.setAutosniperAddress(address(sniper));
        sniper.deposit{value: 5 ether}(address(coinbase));
        vm.coinbase(address(coinbase));

        vm.startPrank(fulfiller, fulfiller);

        order = SniperOrder(
            ItemType(2),
            mockPrice,
            tip,
            coinbaseTip,
            address(coinbase),
            address(mockMarketplace),
            mockContractAddress,
            mockTokenId,
            abi.encodeWithSelector(Marketplace.buyErc721.selector, address(mock721), 1)
        );

        vm.expectRevert(FailedToPayValidator.selector);
        sniper.fulfillOrder(order, claims, 0);
    }

    function testMaliciousCoinbaseAddressDeposit() public {
        MaliciousCoinbaseDeposit coinbase = new MaliciousCoinbaseDeposit();
        coinbase.setAutosniperAddress(address(sniper));
        sniper.deposit{value: 2 ether}(address(coinbase));
        vm.coinbase(address(coinbase));
        vm.deal(address(coinbase), 1 ether);

        vm.startPrank(fulfiller, fulfiller);

        order = SniperOrder(
            ItemType(2),
            mockPrice,
            tip,
            coinbaseTip,
            address(coinbase),
            address(mockMarketplace),
            mockContractAddress,
            mockTokenId,
            abi.encodeWithSelector(Marketplace.buyErc721.selector, address(mock721), 1)
        );

        vm.expectRevert(FailedToPayValidator.selector);
        sniper.fulfillOrder(order, claims, 0);
    }

    function testSolSnatch() public {
        vm.deal(address(mockMarketplace), 10 ether);
        assertEq(sniper.sniperBalances(zeroBalanceSniper), 0);

        startHoax(fulfiller);

        addresses.push(address(mockMarketplace));
        calls.push(abi.encodeWithSelector(Marketplace.buyErc721.selector, address(mock721), 1));
        values.push(mockPrice);

        addresses.push(address(mockContractAddress));
        calls.push(abi.encodeWithSelector(ERC721.setApprovalForAll.selector, address(mockMarketplace), true));
        values.push(0);

        addresses.push(address(mockMarketplace));
        calls.push(abi.encodeWithSelector(Marketplace.sellErc721.selector, address(mock721), 1));
        values.push(0);

        sniper.solSnatch(addresses, calls, values, zeroBalanceSniper, coinbaseTip, tip);

        assertEq(sniper.sniperBalances(zeroBalanceSniper), 10 ether - mockPrice - coinbaseTip - tip);
    }
}
