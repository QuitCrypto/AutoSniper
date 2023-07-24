// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "./SniperEnums.sol";

struct SniperOrder {
    ItemType tokenType;
    uint72 value;
    uint72 autosniperTip;
    uint72 validatorTip;
    address paymentToken;
    address to;
    address marketplace;
    address tokenAddress;
    uint256 tokenId;
    bytes data;
}

struct Claim {
    ItemType tokenType;
    address tokenAddress;
    uint256 tokenId;
    bytes claimData;
}

struct SniperGuardrails {
    bool marketplaceGuardEnabled;
    bool nftContractGuardEnabled;
    bool isPaused;
    mapping(address => bool) allowedMarketplaces;
    mapping(address => bool) allowedNftContracts;
}

struct TokenSubsidy {
    address tokenAddress;
    uint128 amountToSwapForOrder;
    uint128 amountToSwapForTips;
}
