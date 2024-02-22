// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {MockERC721, ERC721} from "soladytest/utils/mocks/MockERC721.sol";

contract ClaimableERC721 is MockERC721 {
    constructor() {}

    address tokenContract;

    function claim(uint256 tokenId) external {
        if (ERC721(tokenContract).ownerOf(tokenId) != msg.sender) revert();

        _mint(msg.sender, tokenId);
    }

    function setTokenContract(address _addy) external {
        tokenContract = _addy;
    }
}
