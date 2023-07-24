// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "openzeppelin/contracts/token/ERC721/IERC721.sol";
import "openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Marketplace {
    function buyErc721(address nftAddress, uint256 tokenId) external payable {
        IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);
    }

    function buyErc721WithErc20(
        address nftAddress,
        uint256 tokenId,
        address tokenAddress
    ) external payable {
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), 1 ether);
        IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);
    }

    function sellErc721(address nftAddress, uint256 tokenId) external {
        IERC721(nftAddress).transferFrom(msg.sender, address(this), tokenId);

        (bool success, ) = payable(msg.sender).call{value: 10 ether}("");
        if (!success) revert();
    }
}
