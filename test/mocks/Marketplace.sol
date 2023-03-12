// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Marketplace {
  function buyErc721(address nftAddress, uint256 tokenId) external payable {
    IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);
  }

  function sellErc721(address nftAddress, uint256 tokenId) external {
    IERC721(nftAddress).transferFrom(msg.sender, address(this), tokenId);

    (bool success, ) = payable(msg.sender).call{value: 10 ether}("");
    if (!success) revert();
  }
}