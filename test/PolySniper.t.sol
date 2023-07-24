// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/PolySniper.sol";
import "./mocks/ClaimableERC721.sol";
import "./mocks/MintableERC721.sol";
import "./mocks/Marketplace.sol";
import "./mocks/weth.sol";
import {MaliciousCoinbaseWithdraw} from "./mocks/MaliciousCoinbaseWithdraw.sol";
import {MaliciousCoinbaseDeposit} from "./mocks/MaliciousCoinbaseDeposit.sol";

interface IAutoSniper {
    function configureMarket(address marketplace, bool status) external;

    function owner() external view returns (address);

    function fulfillOrderWithTokenAsk(
        SniperOrder calldata order,
        Claim[] calldata claims,
        TokenSubsidy calldata tokenSubsidy
    ) external;

    function setUserAllowedMarketplaces(
        bool guardEnabled,
        bool marketplaceAllowed,
        address[] calldata marketplaces
    ) external;

    function setUserAllowedNfts(
        bool guardEnabled,
        bool nftAllowed,
        address[] calldata nfts
    ) external;
}

contract AutoSniperTest is Test {
    event Snipe(SniperOrder order, Claim[] claims);

    AutoSniper public sniper;
    MintableERC721 public mock721;
    ClaimableERC721 public mockClaimable;
    Marketplace public mockMarketplace;
    Weth public wmatic;

    address public seaport = 0x00000000000001ad428e4906aE43D8F9852d0dD6;
    address public quit = 0xC218D847a18E521Ae08F49F7c43882b6d1963c60;
    address public zeroBalanceSniper = address(101);

    address public autosniperContractAddress =
        0x3d326Db044A62cA554498a883B0E90a473db3C8B;
    IAutoSniper public deployedSniper = IAutoSniper(autosniperContractAddress);
    address public fulfiller = 0x7D79Bd0E4B3dC90665A3ed30Aa6C6c06c89D224E;
    address public wethContractAddress =
        0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address public wmaticContractAddress =
        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    uint72 public tip = 0.006 ether;
    uint72 public coinbaseTip = 0.006 ether;
    Claim[] public claims;

    /** MOCK CONTRACT INPUTS */
    address public mockContractAddress;
    uint256 public mockTokenId = 1;
    uint72 public mockPrice = 1 ether;

    bytes public hexData =
        hex"000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000675c9c89ef1c00000000000000000000000000038b53b1476d784f1c8392e76c99e6560a60cd30a000000000000000000000000004c00500000ad104d7dbd00e3ae0a5c00560c0000000000000000000000000059ad67e9c6a84e602bc73b3a606f731cc6df210d0000000000000000000000000000000000000000000000000000000000002218000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000064042ba200000000000000000000000000000000000000000000000000000000640820220000000000000000000000000000000000000000000000000000000000000000360c6ebe00000000000000000000000000000000000000009a36337101ac7b5f0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f00000000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f00000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000024000000000000000000000000000000000000000000000000000000000000002a0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000570a9ec4ff4000000000000000000000000000ea803944e87142d44b945b3f5a0639f442ba361b000000000000000000000000000000000000000000000000000000000000006383c628a6578d7d8dc0a622eb7da0f370ff1f33ff9364efdfa88451720f35423fe8274e4e836d7d0d028cd911ac6e554a1711be1eb4bfd692e0aa29ba3016222500000170ba582795775332f8e3a7a21d108694edc7bc785fefcb32d77f0c97c4a1fa110000000000000000000000000000000000000000000000000000000000";
    address public seaportContractAddress =
        0x59Ad67e9c6a84e602BC73B3A606F731CC6dF210d;
    uint256 public seaportTokenId = 8728;
    uint72 public seaportPrice = 490000000000000000;

    address[] public globalMarketplaces;
    address[] public userMarketplaces;
    address[] public nfts;

    address[] public addresses;
    bytes[] public calls;
    uint256[] public values;

    Claim public claim;

    SniperOrder public order;

    SniperOrder public seaportOrder =
        SniperOrder(
            ItemType(2),
            mockPrice,
            tip,
            coinbaseTip,
            address(0),
            quit,
            seaport,
            seaportContractAddress,
            seaportTokenId,
            hexData
        );

    /** ==========================================================
     *                         TESTS
     *  ==========================================================
     */
    function setUp() public {
        wmatic = new Weth();
        sniper = new AutoSniper();
        mock721 = new MintableERC721();
        mockClaimable = new ClaimableERC721();
        mockMarketplace = new Marketplace();
        mockContractAddress = address(mock721);

        mock721.mint(address(mockMarketplace));

        startHoax(sniper.owner());
        globalMarketplaces.push(seaport);
        globalMarketplaces.push(address(mockMarketplace));
        sniper.configureMarkets(globalMarketplaces, true);

        mockClaimable.setTokenContract(mockContractAddress);

        vm.stopPrank();

        order = SniperOrder(
            ItemType(2),
            mockPrice,
            tip,
            coinbaseTip,
            address(0),
            quit,
            address(mockMarketplace),
            mockContractAddress,
            mockTokenId,
            abi.encodeWithSelector(
                Marketplace.buyErc721.selector,
                address(mock721),
                1
            )
        );

        claim = Claim(
            ItemType(2),
            address(mockClaimable),
            1,
            abi.encodeWithSelector(ClaimableERC721.claim.selector, 1)
        );

        hoax(0x1eED63EfBA5f81D95bfe37d82C8E736b974F477b); // weth whale
        IERC20(wethContractAddress).transfer(quit, 2000 ether);

        startHoax(quit);
        IERC20(wethContractAddress).approve(address(sniper), type(uint256).max);
        Weth(wmaticContractAddress).deposit{value: 2500.06 ether}();
        Weth(wmaticContractAddress).approve(address(sniper), 2500.06 ether);
        vm.stopPrank();
    }

    function testInitCode() public {
        bytes32 initCode = keccak256(
            abi.encodePacked(type(AutoSniper).creationCode)
        );
        emit log_bytes32(initCode);
    }

    function testFulfillOrderMaticAskWethSubsidy() public {
        TokenSubsidy memory subsidy = TokenSubsidy(
            wethContractAddress,
            0.0005 ether,
            0.06 ether
        );

        hoax(fulfiller);
        sniper.fulfillOrderWithTokenAsk(order, claims, subsidy);
    }

    function testFulfillOrderWethAskWethSubsidy() public {
        TokenSubsidy memory subsidy = TokenSubsidy(
            wethContractAddress,
            1 ether,
            0.06 ether
        );

        order = SniperOrder(
            ItemType(2),
            mockPrice,
            tip,
            coinbaseTip,
            wethContractAddress,
            quit,
            address(mockMarketplace),
            mockContractAddress,
            mockTokenId,
            abi.encodeWithSelector(
                Marketplace.buyErc721WithErc20.selector,
                address(mock721),
                1,
                wethContractAddress
            )
        );

        hoax(fulfiller);
        sniper.fulfillOrderWithTokenAsk(order, claims, subsidy);
    }

    function testFulfillOrderWethAskWmaticSubsidy() public {
        TokenSubsidy memory subsidy = TokenSubsidy(
            wmaticContractAddress,
            2500 ether,
            0.06 ether
        );

        order = SniperOrder(
            ItemType(2),
            mockPrice,
            tip,
            coinbaseTip,
            wethContractAddress,
            quit,
            address(mockMarketplace),
            mockContractAddress,
            mockTokenId,
            abi.encodeWithSelector(
                Marketplace.buyErc721WithErc20.selector,
                address(mock721),
                1,
                wethContractAddress
            )
        );

        hoax(fulfiller);
        sniper.fulfillOrderWithTokenAsk(order, claims, subsidy);
    }

    function testFulfillOrderMaticAskWmaticSubsidy() public {
        TokenSubsidy memory subsidy = TokenSubsidy(
            wmaticContractAddress,
            1 ether,
            0.06 ether
        );

        order = SniperOrder(
            ItemType(2),
            mockPrice,
            tip,
            coinbaseTip,
            address(0),
            quit,
            address(mockMarketplace),
            mockContractAddress,
            mockTokenId,
            abi.encodeWithSelector(
                Marketplace.buyErc721.selector,
                address(mock721),
                1
            )
        );

        hoax(fulfiller);
        sniper.fulfillOrderWithTokenAsk(order, claims, subsidy);
    }

    function testExecuteAndClaim() public {
        TokenSubsidy memory subsidy = TokenSubsidy(
            wethContractAddress,
            1 ether,
            0.06 ether
        );
        hoax(fulfiller);
        claims.push(claim);
        sniper.fulfillOrderWithTokenAsk(order, claims, subsidy);
    }

    function testMarketplaceBoolean() public {
        hoax(quit);
        sniper.setUserAllowedMarketplaces(true, true, userMarketplaces);

        vm.expectRevert(MarketplaceNotAllowed.selector);
        testFulfillOrderMaticAskWethSubsidy();

        hoax(quit);
        sniper.setUserAllowedMarketplaces(false, true, userMarketplaces);
        testFulfillOrderMaticAskWethSubsidy();
    }

    function testMarketplaceArray() public {
        hoax(quit);
        sniper.setUserAllowedMarketplaces(true, true, userMarketplaces);

        vm.expectRevert(MarketplaceNotAllowed.selector);
        testFulfillOrderMaticAskWethSubsidy();
        userMarketplaces.push(address(mockMarketplace));
        hoax(quit);
        sniper.setUserAllowedMarketplaces(true, true, userMarketplaces);
        testFulfillOrderMaticAskWethSubsidy();
    }

    function testNftBoolean() public {
        hoax(quit);
        sniper.setUserAllowedNfts(true, true, nfts);

        vm.expectRevert(TokenContractNotAllowed.selector);
        testFulfillOrderMaticAskWethSubsidy();

        hoax(quit);
        sniper.setUserAllowedNfts(false, true, nfts);
        testFulfillOrderMaticAskWethSubsidy();
    }

    function testNftArray() public {
        hoax(quit);
        sniper.setUserAllowedNfts(true, true, nfts);

        vm.expectRevert(TokenContractNotAllowed.selector);
        testFulfillOrderMaticAskWethSubsidy();
        nfts.push(mockContractAddress);
        hoax(quit);
        sniper.setUserAllowedNfts(true, true, nfts);
        testFulfillOrderMaticAskWethSubsidy();
    }
}
