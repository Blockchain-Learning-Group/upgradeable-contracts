pragma solidity ^0.4.11;

/**
 * @title Upgradeable Interface
 * @dev This is required to trick the contract that the relay does in fact
 * possess these methods in order to invoke it's fallback and delegate
 * the call to the latest version.
 */
contract UpgradeableInterface {
  function getUint() returns(uint);
}
