// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/AutoSniper.sol";
import "./mocks/ClaimableERC721.sol";
import "./mocks/MintableERC721.sol";
import "./mocks/Marketplace.sol";
import "./mocks/Weth.sol";
import {MaliciousCoinbaseWithdraw} from "./mocks/MaliciousCoinbaseWithdraw.sol";
import {MaliciousCoinbaseDeposit} from "./mocks/MaliciousCoinbaseDeposit.sol";

interface IAutoSniper {
    function snipe_2572234525(
        address[] calldata contractAddresses,
        bytes[] calldata calls,
        uint256[] calldata values,
        address sniper,
        uint256 validatorTip,
        uint256 fulfillerTip
    ) external;
    function deposit(address sniper) external payable;
    function sniperBalance(address sniper) external view returns (uint256);
    function owner() external view returns (address);
    function withdraw(uint256 mockPrice) external;
}

contract AutoSniperTest is Test {
    event Deposit(address sniper, uint256 amount);
    event Withdraw(address sniper, uint256 amount);

    AutoSniper sniper;
    MintableERC721 mock721;
    ClaimableERC721 mockClaimable;
    Marketplace mockMarketplace;
    Weth weth;

    address quit = 0xC218D847a18E521Ae08F49F7c43882b6d1963c60;
    address zeroBalanceSniper = address(101);

    address AUTOSNIPER_CONTRACT_ADDRESS = 0x3d326Db044A62cA554498a883B0E90a473db3C8B;
    IAutoSniper deployedSniper = IAutoSniper(AUTOSNIPER_CONTRACT_ADDRESS);
    address fulfiller = 0x7D79Bd0E4B3dC90665A3ed30Aa6C6c06c89D224E;

    uint72 tip = 0.006 ether;
    uint72 coinbaseTip = 0.006 ether;

    /**
     * MOCK CONTRACT INPUTS
     */
    address mockContractAddress;
    uint256 mockTokenId = 1;
    uint72 mockPrice = 1 ether;

    address[] addresses;
    bytes[] calls;
    uint256[] values;

    /**
     * ========================================================== 
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

        mockClaimable.setTokenContract(mockContractAddress);

        vm.stopPrank();
        uint256 balance = sniper.sniperBalance(quit);
        hoax(quit);
        sniper.withdraw(balance);
        sniper.deposit{value: 5 ether}(quit);
        assertEq(sniper.sniperBalance(quit), 5 ether);
    }

    function testFulfillNonCompliantMarketplaceOrder() public {
        vm.deal(fulfiller, 100 ether);
        startHoax(fulfiller);
        // FULFILL ORDER
        mockMarketplace.buyErc721{value: 1 ether}(address(mock721), mockTokenId);

        // APPROVE NFT TO AUTOSNIPER CONTRACT
        mock721.setApprovalForAll(address(sniper), true);

        // SELL TO SNIPER
        // transfer from fulfiller to sniper
        addresses.push(address(mock721));
        calls.push(abi.encodeWithSelector(ERC721.transferFrom.selector, fulfiller, quit, mockTokenId));
        values.push(0);
        sniper.snipe_2572234525(addresses, calls, values, quit, coinbaseTip, tip);

        assertEq(mock721.balanceOf(quit), 1);
    }

    function testFulfillerModifier() public {
        vm.expectRevert(AutoSniper.CallerNotFulfiller.selector);
        sniper.snipe_2572234525(addresses, calls, values, quit, coinbaseTip, tip);

        hoax(fulfiller, fulfiller);
        sniper.snipe_2572234525(addresses, calls, values, quit, coinbaseTip, tip);
    }

    function testFulfillOrder(uint256 value) public {
        vm.assume(value > 1 ether && value < 500 ether);
        vm.deal(address(sniper), value + tip + coinbaseTip);
        // buy nft
        addresses.push(address(mockMarketplace));
        calls.push(abi.encodeWithSelector(Marketplace.buyErc721.selector, address(mock721), mockTokenId));
        values.push(value);

        // transfer nft to sniper
        addresses.push(address(mock721));
        calls.push(abi.encodeWithSelector(ERC721.transferFrom.selector, address(sniper), quit, mockTokenId));
        values.push(0);

        // execute snipe_2572234525
        hoax(fulfiller, fulfiller);
        sniper.snipe_2572234525(addresses, calls, values, quit, coinbaseTip, tip);

        assertEq(mock721.balanceOf(quit), 1);
    }

    function testExecuteAndClaim() public {
        // buy nft
        addresses.push(address(mockMarketplace));
        calls.push(abi.encodeWithSelector(Marketplace.buyErc721.selector, address(mock721), mockTokenId));
        values.push(1 ether);

        // claim nft
        addresses.push(address(mockClaimable));
        calls.push(abi.encodeWithSelector(ClaimableERC721.claim.selector, mockTokenId));
        values.push(0);

        // transfer claimable nft to sniper
        addresses.push(address(mockClaimable));
        calls.push(abi.encodeWithSelector(ERC721.transferFrom.selector, address(sniper), quit, mockTokenId));
        values.push(0);

        // transfer nft to sniper
        addresses.push(address(mock721));
        calls.push(abi.encodeWithSelector(ERC721.transferFrom.selector, address(sniper), quit, mockTokenId));
        values.push(0);

        // execute snipe_2572234525
        hoax(fulfiller, fulfiller);
        sniper.snipe_2572234525(addresses, calls, values, quit, coinbaseTip, tip);

        assertEq(mock721.balanceOf(quit), 1);
        assertEq(mockClaimable.balanceOf(quit), 1);
    }

    function testRefundOnOverpay(uint256 value) public {
        vm.assume(value > 1 ether);
        uint256 balanceBefore = sniper.sniperBalance(quit);
        testFulfillOrder(value);
        assertEq(balanceBefore - sniper.sniperBalance(quit), mockPrice + tip + coinbaseTip);
    }

    function testWethSubsidy() public {
        uint256 balance = sniper.sniperBalance(quit);
        hoax(quit);
        sniper.withdraw(balance);
        assertEq(sniper.sniperBalance(quit), 0);
        hoax(quit);
        weth.deposit{value: balance}();
        assertEq(weth.balanceOf(quit), balance);

        hoax(quit);
        weth.approve(address(sniper), balance);

        // transfer weth in
        addresses.push(address(weth));
        calls.push(abi.encodeWithSelector(Weth.transferFrom.selector, quit, address(sniper), balance));
        values.push(0);

        // withdraw weth
        addresses.push(address(weth));
        calls.push(abi.encodeWithSelector(Weth.withdraw.selector, balance));
        values.push(0);

        // buy nft
        addresses.push(address(mockMarketplace));
        calls.push(abi.encodeWithSelector(Marketplace.buyErc721.selector, address(mock721), mockTokenId));
        values.push(mockPrice);

        // transfer nft to sniper
        addresses.push(address(mock721));
        calls.push(abi.encodeWithSelector(ERC721.transferFrom.selector, address(sniper), quit, mockTokenId));
        values.push(0);

        // execute snipe_2572234525
        hoax(fulfiller, fulfiller);

        vm.expectEmit(true, true, true, true, address(sniper));
        emit Deposit(quit, balance - tip - coinbaseTip - mockPrice);

        sniper.snipe_2572234525(addresses, calls, values, quit, coinbaseTip, tip);

        assertEq(weth.balanceOf(quit), 0);
    }

    function testMigrate() public {
        AutoSniper sniperv2 = new AutoSniper();

        hoax(quit);
        vm.expectRevert(AutoSniper.MigrationNotEnabled.selector);
        sniper.migrateBalance();

        hoax(sniper.owner());
        sniper.setMigrationAddress(address(sniperv2));

        assertEq(sniper.sniperBalance(quit), 5 ether);
        assertEq(sniperv2.sniperBalance(quit), 0);
        hoax(quit);
        sniper.migrateBalance();

        assertEq(sniper.sniperBalance(quit), 0);
        assertEq(sniperv2.sniperBalance(quit), 5 ether);
    }

    function testMaliciousCoinbaseAddressWithdraw() public {
        MaliciousCoinbaseWithdraw coinbase = new MaliciousCoinbaseWithdraw();
        coinbase.setAutosniperAddress(address(sniper));
        sniper.deposit{value: 5 ether}(address(coinbase));
        vm.coinbase(address(coinbase));

        vm.startPrank(fulfiller, fulfiller);

        // buy nft
        addresses.push(address(mockMarketplace));
        calls.push(abi.encodeWithSelector(Marketplace.buyErc721.selector, address(mock721), mockTokenId));
        values.push(1 ether);

        // transfer nft to sniper
        addresses.push(address(mock721));
        calls.push(abi.encodeWithSelector(ERC721.transferFrom.selector, address(sniper), quit, mockTokenId));
        values.push(0);

        vm.expectRevert(AutoSniper.FailedToPayValidator.selector);
        sniper.snipe_2572234525(addresses, calls, values, quit, coinbaseTip, tip);
    }

    function testMaliciousCoinbaseAddressDeposit() public {
        MaliciousCoinbaseDeposit coinbase = new MaliciousCoinbaseDeposit();
        coinbase.setAutosniperAddress(address(sniper));
        sniper.deposit{value: 2 ether}(address(coinbase));
        vm.coinbase(address(coinbase));
        vm.deal(address(coinbase), 1 ether);

        vm.startPrank(fulfiller, fulfiller);

        // buy nft
        addresses.push(address(mockMarketplace));
        calls.push(abi.encodeWithSelector(Marketplace.buyErc721.selector, address(mock721), mockTokenId));
        values.push(1 ether);

        // transfer nft to sniper
        addresses.push(address(mock721));
        calls.push(abi.encodeWithSelector(ERC721.transferFrom.selector, address(sniper), quit, mockTokenId));
        values.push(0);

        vm.expectRevert(AutoSniper.FailedToPayValidator.selector);
        sniper.snipe_2572234525(addresses, calls, values, quit, coinbaseTip, tip);
    }
}
