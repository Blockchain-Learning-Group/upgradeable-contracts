pragma solidity ^0.4.11;

/**
 * @title Relay - Enable Upgradeability
 * @dev All calls from the StaticExternalInterface are routed here, invoking
 * the fallback as this contract does not implement the methods contained
 * within the upgradeable interface.
 */
contract Relay {
  /**
   * Storage
   */
  address public currentContract_;
  mapping(uint => address) contractVersions_;
  mapping(bytes4 => uint32) public returnDataSizes_;  // Req'd to delegatecall

  /**
   * @dev Constructor - Set the address of the current version.
   * @param _currentContract Address of the current contract to call.
   */
  function Relay(address _currentContract) {
    upgrade(1, _currentContract);
  }

  /**
   * @dev Add a new function signature mapped to its return size.
   * @param _funcSig The signature of the function, ie. 'getUint()'
   * @param _returnSize The size of the return data from the function.
   */
  function addReturnDataSize(
    string _funcSig,
    uint32 _returnSize
  ) external
  {
    returnDataSizes_[bytes4(sha3(_funcSig))] = _returnSize;
  }

  /**
   * @dev Upgrade to a new contract version.
   * @param _versionNumber The version to associate this address with.
   * @param  _newContract The address of the new contract.
   */
  function upgrade(
    uint _versionNumber,
    address _newContract
  ) public {
    contractVersions_[_versionNumber] = _newContract;
    currentContract_ = _newContract;
  }

  /**
   * @dev Upgrade to a new contract version.
   * @param _versionNumber The version to rollback to.
   */
  function rollback(
    uint _versionNumber
  ) external {
    currentContract_ = contractVersions_[_versionNumber];
  }

  /**
   * @dev The fallback is invoked and effectively relays the call to the correct contract.
   */
  function() external payable {
    // Note require local var as accessing storage data slot fails via currentContract__slot
    address _contractAddr = currentContract_;
    uint32 returnSize = returnDataSizes_[msg.sig];

    assembly {
      calldatacopy(0x0, 0x0, calldatasize)
      let a := delegatecall(sub(gas, 10000), _contractAddr, 0x0, calldatasize, 0, returnSize)
      return(0, returnSize)
    }
  }
}
