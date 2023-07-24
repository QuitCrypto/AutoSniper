// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./helpers/SniperStructs.sol";
import "./helpers/IWETH.sol";
import "./helpers/IPunk.sol";
import "./helpers/SniperErrors.sol";
import "solmate/src/auth/Owned.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "openzeppelin/contracts/token/ERC721/IERC721.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title AutoSniper 3.0 for @oSnipeNFT
 * @author 0xQuit
 */

/*

        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*+=--::::::--=+*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*=:.       ......        :=*%@@@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=.    .-+*%@@@@@@@@@@@@%#+=:    -@@@@@@=:::=#@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@%+.   :=#@@@@@@@@@@@@@@@@@@@@@@@@#+#@@@@@%**+-:::-%@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@#-   :+%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%******+-::=@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@%:   =%@@@@@@@@@@@@@@@@%%%%@@@@@@@@@@@@@@%*++++++***+=+@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@=   -@@@@@@@@@@@@#+-:.         :-+%@@@@@%*+++++++++*#@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@#.  :%@@@@@@@@@%+:      ..:::::.  .*@@@%*+++++++++++#@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@*   =@@@@@@@@@#:    .=*%@@@@@@@@@@%@@@%+----======+#@@@@@%@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@+   *@@@@@@@@#:   .+%@@@@@@@@@@@@@@@@@@=-------==+#@@@@@%- -@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@#   #@@@@@@@@=   .*@@@@@@@@@#=.    .-+#+=--------*@@@@@@@%   +@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@.  =@@@@@@@@-   =@@@@@@@@@@:  -+**+-   .--=----+%@@@@@@@@@#   %@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@+  .@@@@@@@@-   +@@@@@@@@@@-  #@@@@%+-:.  :=*@#%@@@*%@@@@@@@=  -@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@.  #@@@@@@@+   =@@@@@@@@@@@:  @@@%=-----.  #@@@@@*. -@@@@@@@@   %@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@#   @@@@@@@@.  .@@@@@@@@@@@@%  :#=:::::--*+=@@@@@@-   %@@@@@@@-  +@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@+  :@@@@@@@%   =@@@@@@@@@@@@@%-:--::::-*@@@@@@@@@@*   *@@@@@@@+  :@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@=  -@@@@@@@#   +@@@@@@@@@@@@@#-:---:-*@@@@@@@@@@@@#   +@@@@@@@+  :@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@+  -@@@@@@@%   =@@@@@@*#@@@#-::---=. -@@@@@@@@@@@@*   +@@@@@@@+  :@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@#  .@@@@@@@@   .@@@@@+  #*-:::--*@@#  -@@@@@@@@@@@-   %@@@@@@@-  =@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@   #@@@@@@@+  =@@@@@%  .--:--+@@@@@=  %@@@@@@@@@#   :@@@@@@@@   %@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@=  :@@@@@@@@=%@@@@@@*:   :-*@@@@@@%. .@@@@@@@@@%    %@@@@@@@=  :@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@   +@@@@@@@@@@@@#+---:.  .=*###*-  :%@@@@@@@@#   .%@@@@@@@#   #@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@*   %@@@@@@@@@#=------*%+-      .-#@@@@@@@@%=   .%@@@@@@@@.  =@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@= .*@@@@@@@@+------=%@@@@@@%%%@@@@@@@@@@#-    +@@@@@@@@@:  :@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@#@@@@@@@@*===---=#@@@@@@@@@@@@@@@@@%*-     +@@@@@@@@@#   -@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@*=====+#%@@@@@%= .:--==--:.     .-*@@@@@@@@@@+   +@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@+--==+#@@@@@@@@=:.           :=*%@@@@@@@@@@@*.  .#@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@*===+-*@@@@@@@@@@@@@@%%#####%@@@@@@@@@@@@@@@*.   +@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@#+==#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=   .+@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@+==+%@@@@@@@@@%*%@@@@@@@@@@@@@@@@@@@@@@@@@*-    -*@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@#=%@@@@@@@@@+    -=*%@@@@@@@@@@@@@@%*+-.    :+@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%+-.      ..:::::::.      .-+#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*+=-:........:-=+*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

*/

contract AutoSniper is Owned {
    ISwapRouter public immutable swapRouter;

    string public name = "oSnipe: AutoSniper V3";

    address constant _WETH_ADDRESS = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
    address constant _WMATIC_ADDRESS =
        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address constant _SWAP_ROUTER_ADDRESS =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    uint24 constant _POOL_FEE = 3000;

    address _fulfillerAddress = 0x7D79Bd0E4B3dC90665A3ed30Aa6C6c06c89D224E;
    mapping(address => bool) public allowedMarketplaces;
    mapping(address => SniperGuardrails) public sniperGuardrails;

    constructor() Owned(0x507c8252c764489Dc1150135CA7e41b01e10ee74) {
        swapRouter = ISwapRouter(_SWAP_ROUTER_ADDRESS);
    }

    /**
     * @dev fulfillOrderWithTokenAsk conducts its own checks to ensure that the passed order is a valid sniper
     * before forwarding the snipe on to the appropriate marketplace. Snipers can block orders by setting
     * up guardrails that prevent orders from being fulfilled outside of allowlisted marketplaces or
     * nft contracts, or with tips that exceed a maximum tip amount. WETH is used to subsidize
     * the order in case the Sniper's deposited balance is too low. WETH must be approved in order for this to
     * work. Calculation is done off-chain and passed in via wethAmount. If for some reason there is an overpay,
     * the marketplace will refund the difference, which is added to the Sniper's balance.
     * @param claims an array of claims that the sniped NFT is eligible for. Claims are claimed and
     * transferred to the sniper along with the sniped NFT.
     */
    function fulfillOrderWithTokenAsk(
        SniperOrder calldata order,
        Claim[] calldata claims,
        TokenSubsidy calldata tokenSubsidy
    ) external onlyFulfiller {
        _checkGuardrails(order.tokenAddress, order.marketplace, order.to);

        // transfer `amount` of `token` to autosniper:
        _depositToken(tokenSubsidy, order.to);

        bool orderFilled;

        if (order.paymentToken == address(0)) {
            uint256 totalValue = order.value +
                order.autosniperTip +
                order.validatorTip;
            // swap `token` for wmatic (enough for totalValue)
            _swapExactOutputSingle(
                _WMATIC_ADDRESS,
                tokenSubsidy.tokenAddress,
                totalValue,
                tokenSubsidy.amountToSwapForTips +
                    tokenSubsidy.amountToSwapForOrder,
                order.to
            );

            // withdraw wmatic for matic
            IWETH(_WMATIC_ADDRESS).withdraw(totalValue);

            (orderFilled, ) = order.marketplace.call{value: order.value}(
                order.data
            );
        } else {
            uint256 totalTip = order.autosniperTip + order.validatorTip;
            // swap `token` for matic (enough for totalTip)
            _swapExactOutputSingle(
                _WMATIC_ADDRESS,
                tokenSubsidy.tokenAddress,
                totalTip,
                tokenSubsidy.amountToSwapForTips,
                order.to
            );
            IWETH(_WMATIC_ADDRESS).withdraw(totalTip);

            // swap `token` for `order.paymentToken` (enough for order.value)
            _swapExactOutputSingle(
                order.paymentToken,
                tokenSubsidy.tokenAddress,
                order.value,
                tokenSubsidy.amountToSwapForOrder,
                order.to
            );
            IERC20(order.paymentToken).approve(order.marketplace, order.value);
            (orderFilled, ) = order.marketplace.call(order.data);
        }
        if (!orderFilled) revert OrderFailed();

        (bool autosniperPaid, ) = payable(_fulfillerAddress).call{
            value: order.autosniperTip
        }("");
        if (!autosniperPaid) revert FailedToPayAutosniper();

        (bool validatorPaid, ) = block.coinbase.call{value: order.validatorTip}(
            ""
        );
        if (!validatorPaid) revert FailedToPayValidator();

        _claimAndTransferClaimableAssets(claims, order.to);
        _transferNftToSniper(
            order.tokenType,
            order.tokenAddress,
            order.tokenId,
            address(this),
            order.to
        );
    }

    /**
     * @dev set up a marketplace allowlist.
     * @param guardEnabled if false then marketplace allowlist will not be checked for this user
     * @param marketplaceAllowed boolean indicating whether the marketplace is allowed or not
     */
    function setUserAllowedMarketplaces(
        bool guardEnabled,
        bool marketplaceAllowed,
        address[] calldata marketplaces
    ) external {
        sniperGuardrails[msg.sender].marketplaceGuardEnabled = guardEnabled;
        for (uint256 i = 0; i < marketplaces.length; ) {
            sniperGuardrails[msg.sender].allowedMarketplaces[
                marketplaces[i]
            ] = marketplaceAllowed;
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev set up NFT contract allowlist
     * @param guardEnabled if false then NFT contract allowlist will not be checked for this user
     * @param nftAllowed boolean indicating whether the NFT contract is allowed or not
     */
    function setUserAllowedNfts(
        bool guardEnabled,
        bool nftAllowed,
        address[] calldata nfts
    ) external {
        sniperGuardrails[msg.sender].nftContractGuardEnabled = guardEnabled;
        for (uint256 i = 0; i < nfts.length; ) {
            sniperGuardrails[msg.sender].allowedNftContracts[
                nfts[i]
            ] = nftAllowed;
            unchecked {
                ++i;
            }
        }
    }

    function setUserIsPaused(bool isPaused) external {
        sniperGuardrails[msg.sender].isPaused = isPaused;
    }

    /**
     * @dev Owner function to set up global marketplace allowlist.
     */
    function configureMarkets(
        address[] calldata marketplaces,
        bool status
    ) external onlyOwner {
        for (uint256 i = 0; i < marketplaces.length; ) {
            allowedMarketplaces[marketplaces[i]] = status;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Owner function to change fulfiller address if needed.
     */
    function setfulfillerAddress(address _fulfiller) external onlyOwner {
        _fulfillerAddress = _fulfiller;
    }

    // getters to simplify web3js calls
    function marketplaceApprovedBySniper(
        address sniper,
        address marketplace
    ) external view returns (bool) {
        return sniperGuardrails[sniper].allowedMarketplaces[marketplace];
    }

    function nftContractApprovedBySniper(
        address sniper,
        address nftContract
    ) external view returns (bool) {
        return sniperGuardrails[sniper].allowedNftContracts[nftContract];
    }

    function _depositToken(
        TokenSubsidy calldata subsidy,
        address sniper
    ) private {
        IERC20 token = IERC20(subsidy.tokenAddress);
        token.transferFrom(
            sniper,
            address(this),
            subsidy.amountToSwapForTips + subsidy.amountToSwapForOrder
        );
    }

    function _transferNftToSniper(
        ItemType tokenType,
        address tokenAddress,
        uint256 tokenId,
        address source,
        address sniper
    ) private {
        if (tokenType == ItemType.ERC721) {
            IERC721(tokenAddress).transferFrom(source, sniper, tokenId);
        } else if (tokenType == ItemType.ERC1155) {
            IERC1155(tokenAddress).safeTransferFrom(
                source,
                sniper,
                tokenId,
                1,
                ""
            );
        } else if (tokenType == ItemType.CRYPTOPUNKS) {
            IPunk(tokenAddress).transferPunk(sniper, tokenId);
        } else if (tokenType == ItemType.ERC20) {
            IERC20 token = IERC20(tokenAddress);
            token.transfer(sniper, token.balanceOf(source));
        }
    }

    function _claimAndTransferClaimableAssets(
        Claim[] calldata claims,
        address sniper
    ) private {
        for (uint256 i = 0; i < claims.length; i++) {
            Claim memory claim = claims[i];

            (bool claimSuccess, ) = claim.tokenAddress.call(claim.claimData);
            if (!claimSuccess) revert ClaimFailed();

            _transferNftToSniper(
                claim.tokenType,
                claim.tokenAddress,
                claim.tokenId,
                address(this),
                sniper
            );
        }
    }

    /// @notice swapExactOutputSingle swaps a minimum possible amount of tokenIn for a fixed amount of WETH.
    /// @dev The calling address must approve this contract to spend its tokenIn for this function to succeed. As the amount of input tokenIn is variable,
    /// the calling address will need to approve for a slightly higher amount, anticipating some variance.
    /// @param amountOut The exact amount of tokenOut to receive from the swap.
    /// @param amountInMaximum The amount of tokenIn we are willing to spend to receive the specified amount of tokenOut.
    /// @return amountIn The amount of tokenIn actually spent in the swap.
    function _swapExactOutputSingle(
        address tokenOut,
        address tokenIn,
        uint256 amountOut,
        uint256 amountInMaximum,
        address sniper
    ) private returns (uint256 amountIn) {
        if (tokenOut == tokenIn) return amountInMaximum;
        // Approve the router to spend the specifed `amountInMaximum` of `tokenIn`.
        TransferHelper.safeApprove(
            tokenIn,
            address(swapRouter),
            amountInMaximum
        );

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: _POOL_FEE,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        amountIn = swapRouter.exactOutputSingle(params);

        // If the actual amount spent (amountIn) is less than the specified maximum amount, refund the msg.sender and approve the swapRouter to spend 0.
        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(tokenIn, address(swapRouter), 0);
            TransferHelper.safeTransfer(
                tokenIn,
                sniper,
                amountInMaximum - amountIn
            );
        }
    }

    function _checkGuardrails(
        address tokenAddress,
        address marketplace,
        address sniper
    ) private view {
        SniperGuardrails storage guardrails = sniperGuardrails[sniper];

        if (guardrails.isPaused) revert SniperIsPaused();
        if (!allowedMarketplaces[marketplace]) revert MarketplaceNotAllowed();
        if (
            guardrails.marketplaceGuardEnabled &&
            !guardrails.allowedMarketplaces[marketplace]
        ) revert MarketplaceNotAllowed();
        if (
            guardrails.nftContractGuardEnabled &&
            !guardrails.allowedNftContracts[tokenAddress]
        ) revert TokenContractNotAllowed();
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

    function supportsInterface(
        bytes4 interfaceId
    ) external view virtual returns (bool) {
        return interfaceId == this.supportsInterface.selector;
    }

    receive() external payable {}

    // Emergency function: In case any ERC20 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC20(address asset, address recipient) external onlyOwner {
        IERC20 token = IERC20(asset);
        token.transfer(recipient, token.balanceOf(address(this)));
    }

    // Emergency function: In case any ERC721 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC721(
        address asset,
        uint256[] calldata ids,
        address recipient
    ) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721(asset).transferFrom(address(this), recipient, ids[i]);
        }
    }

    // Emergency function: In case any ERC1155 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC1155(
        address asset,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        address recipient
    ) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC1155(asset).safeTransferFrom(
                address(this),
                recipient,
                ids[i],
                amounts[i],
                ""
            );
        }
    }

    modifier onlyFulfiller() {
        if (msg.sender != _fulfillerAddress) revert CallerNotFulfiller();
        _;
    }
}
