// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./helpers/SniperStructs.sol";
import "./helpers/IWETH.sol";
import "./helpers/IPunk.sol";
import "openzeppelin/contracts/access/Ownable.sol";
import "openzeppelin/contracts/token/ERC721/IERC721.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/token/ERC1155/IERC1155.sol";

error InsufficientBalance();
error FailedToWithdraw();
error MaxTipExceeded();
error MarketplaceNotAllowed();
error TokenContractNotAllowed();
error OrderFailed();
error TipBelowMinimum();
error CallerNotFulfiller();

contract AutoSniper is Ownable {
    address private OSNIPE = 0x507c8252c764489Dc1150135CA7e41b01e10ee74;
    address private FULFILLER_ADDRESS;
    uint256 public minimumTip = 0.005 ether;
    mapping(address => bool) public allowedMarketplaces;
    mapping(address => uint256) public sniperBalances;
    mapping(address => SniperGuardrails) public sniperGuardrails;

    constructor(address _fulfiller) { 
        FULFILLER_ADDRESS = _fulfiller;
    }

    function fulfillOrder(SniperOrder calldata order, uint256 wethAmount) external onlyFulfiller {
        if (wethAmount > 0) _swapWeth(wethAmount, order.to);
        _checkSniperGuardrails(order.tokenAddress, order.marketplace, order.tip, order.to);
        uint256 totalValue = order.value + order.tip;
        if (!allowedMarketplaces[order.marketplace]) revert MarketplaceNotAllowed();
        if (sniperBalances[order.to] < totalValue) revert InsufficientBalance();

        unchecked { sniperBalances[order.to] -= totalValue; }

        (bool transferred, ) = payable(OSNIPE).call{value: order.tip}("");
        if (!transferred) revert FailedToWithdraw();

        (bool success,) = order.marketplace.call{value: order.value}(order.data);
        if (!success) revert OrderFailed();

        _transferNftToSniper(order.tokenType, order.tokenAddress, order.tokenId, order.to);
    }

    function deposit(address sniper) external payable {
        sniperBalances[sniper] += msg.value;
    }

    function withdraw(uint256 amount) external {
        if (sniperBalances[msg.sender] < amount) revert InsufficientBalance();
        unchecked { sniperBalances[msg.sender] -= amount; }
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert FailedToWithdraw();
    }

    function setUserAllowedMarketplaces(bool guardEnabled, bool marketplaceAllowed, address[] calldata marketplaces) external {
        sniperGuardrails[msg.sender].marketplaceGuardEnabled = guardEnabled;
        for (uint256 i = 0; i < marketplaces.length;) {
            sniperGuardrails[msg.sender].allowedMarketplaces[marketplaces[i]] = marketplaceAllowed;
            unchecked { ++i; }
        }
    }

    function setUserMaxTip(uint256 maxTipInWei) external {
        if (maxTipInWei < minimumTip && maxTipInWei != 0) revert TipBelowMinimum();
        sniperGuardrails[msg.sender].maxTip = maxTipInWei;
    }

    function setUserAllowedNfts(bool guardEnabled, bool nftAllowed, address[] calldata nfts) external {
        sniperGuardrails[msg.sender].nftContractGuardEnabled = guardEnabled;
        for (uint256 i = 0; i < nfts.length;) {
            sniperGuardrails[msg.sender].allowedNftContracts[nfts[i]] = nftAllowed;
            unchecked { ++i; }
        }
    }

    function configureMarket(address marketplace, bool status) external onlyOwner {
        allowedMarketplaces[marketplace] = status;
    }

    function setFulfillerAddress(address _fulfiller) external onlyOwner {
        FULFILLER_ADDRESS = _fulfiller;
    }

    function setMinimumTip(uint256 tip) external onlyOwner {
        minimumTip = tip;
    }

    // getters to simplify web3js calls
    function marketplaceApprovedBySniper(address sniper, address marketplace) external view returns (bool) {
        return sniperGuardrails[sniper].allowedMarketplaces[marketplace];
    }

    function nftContractApprovedBySniper(address sniper, address nftContract) external view returns (bool) {
        return sniperGuardrails[sniper].allowedNftContracts[nftContract];
    }

    // internal helpers
    function _swapWeth(uint256 wethAmount, address sniper) private onlyFulfiller {
        IWETH weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        weth.transferFrom(sniper, address(this), wethAmount);
        weth.withdraw(wethAmount);

        unchecked { sniperBalances[sniper] += wethAmount; }
    }

    function _transferNftToSniper(ItemType tokenType, address tokenAddress, uint256 tokenId, address sniper) private {
        if (tokenType == ItemType.ERC721) {
            IERC721(tokenAddress).transferFrom(address(this), sniper, tokenId);
        } else if (tokenType == ItemType.ERC1155) {
            IERC1155(tokenAddress).safeTransferFrom(address(this), sniper, tokenId, 1, "");
        } else if (tokenType == ItemType.CRYPTOPUNKS) {
            IPunk(tokenAddress).transferPunk(sniper, tokenId);
        }
    }

    function _checkSniperGuardrails(address tokenAddress, address marketplace, uint256 tip, address sniper) private view {
        SniperGuardrails storage guardrails = sniperGuardrails[sniper];

        if (guardrails.maxTip > 0 && tip > guardrails.maxTip) revert MaxTipExceeded();
        if (guardrails.marketplaceGuardEnabled && !guardrails.allowedMarketplaces[marketplace]) revert MarketplaceNotAllowed();
        if (guardrails.nftContractGuardEnabled && !guardrails.allowedNftContracts[tokenAddress]) revert TokenContractNotAllowed();
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return 0x150b7a02;
    }

    // Used by ERC721BasicToken.sol
    function onERC721Received(
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return 0xf0b9e5ba;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        virtual
        view
        returns (bool)
    {
        return interfaceId == this.supportsInterface.selector;
    }

    receive() external payable {}

    // Emergency function: In case any ERC20 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC20(address asset, address recipient) onlyOwner external { 
        (bool success, ) = asset.call(abi.encodeWithSelector(0xa9059cbb, recipient, IERC20(asset).balanceOf(address(this))));
        if (!success) revert FailedToWithdraw();
    }

    // Emergency function: In case any ERC721 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC721(address asset, uint256[] calldata ids, address recipient) onlyOwner external {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721(asset).transferFrom(address(this), recipient, ids[i]);
        }
    }

    // Emergency function: In case any ERC1155 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC1155(address asset, uint256[] calldata ids, uint256[] calldata amounts, address recipient) onlyOwner external {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC1155(asset).safeTransferFrom(address(this), recipient, ids[i], amounts[i], "");
        }
    }

    modifier onlyFulfiller() {
        if (msg.sender != FULFILLER_ADDRESS) revert CallerNotFulfiller();
        _;
    }
}
