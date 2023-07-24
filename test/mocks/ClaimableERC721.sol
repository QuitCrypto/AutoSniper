// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ClaimableERC721 is ERC721 {
    constructor() ERC721("MOCK", "MOCK") {}

    address tokenContract;

    function claim(uint256 tokenId) external {
        if (IERC721(tokenContract).ownerOf(tokenId) != msg.sender) revert();

        _mint(msg.sender, tokenId);
    }

    function setTokenContract(address _addy) external {
        tokenContract = _addy;
    }
}
