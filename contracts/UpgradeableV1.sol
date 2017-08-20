pragma solidity ^0.4.11;

/**
 * @title Upgrade Contract Version 1
 * @dev The contract to be upgraded.
 * Implements all methods associated in UpgradeableInterface.
 */
contract UpgradeableV1 {
  function getUint() returns(uint) {
    return 1;
  }
}
