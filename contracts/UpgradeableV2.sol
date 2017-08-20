pragma solidity ^0.4.11;

/**
 * @title Upgrade Contract Version 2
 * @dev The contract to be upgraded.
 * Implements all methods associated in UpgradeableInterface.
 */
contract UpgradeableV2 {
  function getUint() returns(uint) {
    return 2;
  }
}
