pragma solidity ^0.4.11;

import './UpgradeableInterface.sol';

/**
 * @title External Interface
 * @dev Interface all users applications, etc with interface with
 * This interface remains static and will not change.
 */
contract StaticExternalInterface {
  // "trick" this contract to thinking what lives at this address follows
  // the interface but in fact it will be the fallback invoked every time.
  UpgradeableInterface relay_;

  /**
   * @dev Constructor - Set the address of the static relay
   * @param _relay The address of the relay contract.
   */
  function StaticExternalInterface(address _relay) {
    relay_ = UpgradeableInterface(_relay);
  }

  /**
   * @dev Test function
   */
  function getUint() external returns(uint) {
    return relay_.getUint();
  }
}
