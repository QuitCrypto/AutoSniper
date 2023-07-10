// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IAutoSniper {
  function depositSelf() external payable;
  function sniperBalances(address) external view returns (uint256);
}

contract MaliciousCoinbaseDeposit {
  constructor() {}

  address autoSniper;

  fallback() external payable {
    IAutoSniper(autoSniper).depositSelf{value: 1 ether}();
  }

  function setAutosniperAddress(address _addy) external {
    autoSniper = _addy;
  }
}