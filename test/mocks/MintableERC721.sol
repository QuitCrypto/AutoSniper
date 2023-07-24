// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MintableERC721 is ERC721 {
    constructor() ERC721("MOCK", "MOCK") {}

    function mint(address to) external {
        _mint(to, 1);
    }
}
