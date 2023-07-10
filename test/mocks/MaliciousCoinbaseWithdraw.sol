// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IAutoSniper {
  function depositSelf() external payable;
  function withdraw(uint256 amount) external;
  function sniperBalances(address) external view returns (uint256);
}

contract MaliciousCoinbaseWithdraw {
  constructor() {}

  address autoSniper;

  fallback() external payable {
    uint256 balance = IAutoSniper(autoSniper).sniperBalances(address(this));
    if (balance == 0) return;
    IAutoSniper(autoSniper).withdraw(balance);
  }

  function setAutosniperAddress(address _addy) external {
    autoSniper = _addy;
  }
}