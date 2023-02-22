// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./helpers/SniperStructs.sol";
import "./helpers/IWETH.sol";
import "./helpers/IPunk.sol";
import "openzeppelin/contracts/access/Ownable.sol";
import "openzeppelin/contracts/token/ERC721/IERC721.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/token/ERC1155/IERC1155.sol";

error InsufficientBalance();
error FailedToWithdraw();
error FailedToPayAutosniper();
error FailedToPayValidator();
error MaxTipExceeded();
error MarketplaceNotAllowed();
error TokenContractNotAllowed();
error OrderFailed();
error TipBelowMinimum();
error CallerNotFulfiller();
error ClaimFailed();
error ArrayLengthMismatch();

/// @title AutoSniper for oSnipe
/// @author 0xQuit

contract AutoSniper is Ownable {
    event Snipe(
        SniperOrder order,
        Claim[] claims
    );

    event Deposit(
        address sniper,
        uint256 amount
    );

    event Withdrawal(
        address sniper,
        uint256 amount
    );

    address private immutable WETH_ADDRESS;
    address private fulfillerAddress;
    uint256 public minimumTip = 0.005 ether;
    mapping(address => bool) public allowedMarketplaces;
    mapping(address => uint256) public sniperBalances;
    mapping(address => SniperGuardrails) public sniperGuardrails;


    /**
    * @param _fulfiller This address is controlled by the oSnipe discord bot,
    * and is responsible for fulfilling orders. Only the fulfiller can call `fulfillOrder`.
    */
    constructor(address _fulfiller, address _weth) { 
        fulfillerAddress = _fulfiller;
        wethAddress = _weth;
    }

    /**
    * @dev fulfillOrder conducts its own checks to ensure that the passed order is a valid sniper
    * before forwarding the snipe on to the appropriate marketplace. Snipers can block orders by setting
    * up guardrails that prevent orders from being fulfilled outside of allowlisted marketplaces or
    * nft contracts, or with tips that exceed a maximum tip amount. WETH is used to subsidize
    * the order in case the Sniper's deposited balance is too low. WETH must be approved in order for this to
    * work. Calculation is done off-chain and passed in via wethAmount. If for some reason there is an overpay,
    * the marketplace will refund the difference, which is added to the Sniper's balance.
    * @param wethSubsidy the amount of WETH that needs to be converted.
    * @param claims an array of claims that the sniped NFT is eligible for. Claims should be claimed and
    * transferred to the sniper
    */
    function fulfillOrder(SniperOrder calldata order, Claim[] calldata claims, uint256 wethSubsidy) external onlyFulfiller {
        if (wethSubsidy > 0) _swapWeth(wethSubsidy, order.to);
        _checkSniperGuardrails(order.tokenAddress, order.marketplace, order.autosniperTip, order.to);
        uint256 totalValue = order.value + order.autosniperTip + order.validatorTip;
        if (!allowedMarketplaces[order.marketplace]) revert MarketplaceNotAllowed();
        if (sniperBalances[order.to] < totalValue) revert InsufficientBalance();

        uint256 balanceBefore = address(this).balance;

        (bool autosniperPaid, ) = payable(fulfillerAddress).call{value: order.autosniperTip}("");
        if (!autosniperPaid) revert FailedToPayAutosniper();
        (bool orderFilled,) = order.marketplace.call{value: order.value}(order.data);
        if (!orderFilled) revert OrderFailed();
        (bool validatorPaid, ) = block.coinbase.call{value: order.validatorTip}("");
        if (!validatorPaid) revert FailedToPayValidator();

        uint256 balanceAfter = address(this).balance;
        uint256 spent = balanceBefore - balanceAfter;

        sniperBalances[order.to] -= spent;

        _claimAndTransferClaimableAssets(claims);
        _transferNftToSniper(order.tokenType, order.tokenAddress, order.tokenId, order.to);
        emit SnipeSuccessful(order.tokenAddress, order.tokenId, order.to, order.marketplace, order.value, order.autosniperTip, order.validatorTip);
    }

    /**
    * @dev deposit Ether into the contract. 
    * @param sniper is the address who's balance is affected.
    */
    function deposit(address sniper) public payable {
        sniperBalances[sniper] += msg.value;

        emit Deposit(sniper, msg.value);
    }

    /**
    * @dev deposit Ether into your own contract balance.
    */
    function depositSelf() external payable {
        deposit(msg.sender);
    }

    /**
    * @dev withdraw Ether from your contract balance
    * @param amount the amount of Ether to be withdrawn 
    */
    function withdraw(uint256 amount) external {
        if (sniperBalances[msg.sender] < amount) revert InsufficientBalance();
        sniperBalances[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert FailedToWithdraw();

        emit Withdrawal(msg.sender, amount);
    }

    /**
    * @dev set up a marketplace allowlist.
    * @param guardEnabled if false then marketplace allowlist will not be checked for this user
    * @param marketplaceAllowed boolean indicating whether the marketplace is allowed or not
    */
    function setUserAllowedMarketplaces(bool guardEnabled, bool marketplaceAllowed, address[] calldata marketplaces) external {
        sniperGuardrails[msg.sender].marketplaceGuardEnabled = guardEnabled;
        for (uint256 i = 0; i < marketplaces.length;) {
            sniperGuardrails[msg.sender].allowedMarketplaces[marketplaces[i]] = marketplaceAllowed;
            unchecked { ++i; }
        }
    }

    /**
    * @dev Set up a maximum tip guardrail (in wei). If set to 0, guardrail will be disabled.
    */
    function setUserMaxTip(uint256 maxTipInWei) external {
        if (maxTipInWei < minimumTip && maxTipInWei != 0) revert TipBelowMinimum();
        sniperGuardrails[msg.sender].maxTip = maxTipInWei;
    }

    /**
    * @dev set up NFT contract allowlist
    * @param guardEnabled if false then NFT contract allowlist will not be checked for this user
    * @param nftAllowed boolean indicating whether the NFT contract is allowed or not
    */
    function setUserAllowedNfts(bool guardEnabled, bool nftAllowed, address[] calldata nfts) external {
        sniperGuardrails[msg.sender].nftContractGuardEnabled = guardEnabled;
        for (uint256 i = 0; i < nfts.length;) {
            sniperGuardrails[msg.sender].allowedNftContracts[nfts[i]] = nftAllowed;
            unchecked { ++i; }
        }
    }

    /**
    * @dev Owner function to set up global marketplace allowlist.
    */
    function configureMarkets(address[] calldata marketplaces, bool status) external onlyOwner {
        for (uint256 i = 0; i < marketplaces.length;) {
            allowedMarketplaces[marketplaces[i]] = status;

            unchecked { ++i; }
        }
    }

    /**
    * @dev Owner function to change fulfiller address if needed.
    */
    function setFulfillerAddress(address _fulfiller) external onlyOwner {
        fulfillerAddress = _fulfiller;
    }

    /**
    * @dev Owner function to change minimum tip amount (minimum tip should
    * always be approximately enough to cover gas, which is paid by the fulfiller)
    */
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
        IWETH weth = IWETH(WETH_ADDRESS);
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
        } else if (tokenType == ItemType.ERC20) {
            IERC20 token = IERC20(tokenAddress);
            token.transfer(sniper, token.balanceOf(address(this)));
        }
    }

    function _claimAndTransferClaimableAssets(Claim[] calldata claims, address sniper) private {
        for (uint256 i = 0; i < claims.length; i++) {
            Claim memory claim = claims[i];

            (bool claimSuccess, ) = claim.tokenAddress.call(claim.claimData);
            if (!claimSuccess) revert ClaimFailed();

            _transferNftToSniper(claim.tokenType, claim.tokenAddress, claim.tokenId, sniper);
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
        IERC20 token = IERC20(asset);
        token.transfer(recipient, token.balanceOf(address(this)));
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
        if (msg.sender != fulfillerAddress) revert CallerNotFulfiller();
        _;
    }
}
