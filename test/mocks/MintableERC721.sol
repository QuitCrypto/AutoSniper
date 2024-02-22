// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {MockERC721} from "soladytest/utils/mocks/MockERC721.sol";

contract MintableERC721 is MockERC721 {
    constructor() {}

    function mint(address to) external {
        _mint(to, 1);
    }
}
