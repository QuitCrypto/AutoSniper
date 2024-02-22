// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC721} from "forge-std/interfaces/IERC721.sol";

contract Marketplace {
    function buyErc721(address nftAddress, uint256 tokenId) external payable {
        if (msg.value < 1 ether) revert();
        IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);
        payable(msg.sender).transfer(msg.value - 1 ether);
    }

    function sellErc721(address nftAddress, uint256 tokenId) external {
        IERC721(nftAddress).transferFrom(msg.sender, address(this), tokenId);

        (bool success,) = payable(msg.sender).call{value: 10 ether}("");
        if (!success) revert();
    }
}
