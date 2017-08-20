# Upgradeable Contract Examples

## Basic Upgradeable Conract Example
Note this is a minimal implementation inteneded for clarity and ease of explanation, excluding permissioning, pre-condition / sanity checks etc.

### Contracts
__1. [StaticExternalInterface.sol](https://github.com/Blockchain-Learning-Group/upgradeable-contracts/blob/master/contracts/StaticExternalInterface.sol)__

This is the interface that will remain constant and exposed to the outside world. This is the contract that will server as the entry point. This interface is not upgradeable but the logic behind it sure is!

__2. [UpgradeableInterface.sol](https://github.com/Blockchain-Learning-Group/upgradeable-contracts/blob/master/contracts/UpgradeableInterfac.sol)__

The interface that all upgradeable contracts must follow.  These are the methods that will be called by StaticExternalInterface.sol and therefore must be implmented by all versions of your upgradeable contracts.  This interface is a very important piece and is what enables the "tricking" of the static interface into believing that the relay in fact implements these methods itself when in reality it does not.

__3. [Relay.sol](https://github.com/Blockchain-Learning-Group/upgradeable-contracts/blob/master/contracts/Relay.sol)__

The contract that relays all calls to the current version of the contract.  This is the connector between the external world and the current version of the contract logic to interact with.

__4. [UpgradeableV1](https://github.com/Blockchain-Learning-Group/upgradeable-contracts/blob/master/contracts/UpgradeableV1.sol) / [V2.sol](https://github.com/Blockchain-Learning-Group/upgradeable-contracts/blob/master/contracts/UpgradeableV2.sol)__

Arbitrary contracts demonstrating various versions of logic may be deployed.

### Architecture
StaticExternalInterface communicates with Relay which 'relays' all messages to the correct contract version, UpgradeableV1 / V2.

__1. Setup__

  a. Deploy the current version of your contract, UpgradeableV1.sol here.
  ```
  // test_upgradeable.js
  const upgradeableV1 = await UpgradeableV1.new()
  ```
  b. Deploy Relay.sol and tell it of the first version of the contract, located at UpgradeableV1.address. The relay thus sets the current version, will route all messages here.
  ```
  // test_upgradeable.js
  const relay = await Relay.new(upgradeableV1.address)

  // Relay.sol
  function Relay(address _currentContract) {
    upgrade(1, _currentContract);
  }
  ```
  c. Deploy StaticExternalInterface.sol and pass in the now deployed relay address. By passing in the address of a Relay.sol contract instead of an UpgradeableVX.sol we are able to effectively "trick" the compiler into thinking that this contract in fact possesses the methods we will be calling.  But in fact the relay does not and it will be it's fallback that receives all messages.
  ```
  // test_upgradeable.js
  const staticExternalInterface = await StaticExternalInterface.new(relay.address)

  // StaticExternalInterface.sol
  UpgradeableInterface relay_;

  function StaticExternalInterface(address _relay) {
    relay_ = UpgradeableInterface(_relay);
  }
  ```
  d. Add the return data size for all methods you wish to invoke. Before a method can be invoked we must also tell the relay the size of its return data in order to return the data back throuh to the calling contract, StaticExternalInterface.sol.  So we pass in the function signature and define the return size.
  ```
  // test_upgradeable.js
  await relay.addReturnDataSize('getUint()', 32)

  // Relay.sol
  function addReturnDataSize(
    string _funcSig,
    uint32 _returnSize
  ) external
  {
    returnDataSizes_[bytes4(sha3(_funcSig))] = _returnSize;
  }
  ```

__2. Message Flow__

All external calls begin by entering at StaticExternalInterface.sol.  All traffic goes through this contract which then looks to reach out to the current version of it's logic to execute.

Finding the current version is handled by Relay.sol.  This is effectively the "man in the middle" connecting requests with the current version of the contract, or simply the current version, in the case of rollbacks.

a. A method within StaticExternalInterface.getUint() is invoked.  
```
// test_upgradeable.js
response = await staticExternalInterface.getUint.call()
```
b. StaticExternalInterface.sol forwards this call to the relay.
```
// StaticExternalInterface.sol
function getUint() external returns(uint) {
  return relay_.getUint();
}
```
c. The relay does not actually have a getUint() method and therefore it's fallback method is invoked which then delegates this call to the current version of the contract.
```
// Relay.sol
function() external payable {
  address _contractAddr = currentContract_;
  uint32 returnSize = returnDataSizes_[msg.sig];

  assembly {
    calldatacopy(0x0, 0x0, calldatasize)
    let a := delegatecall(sub(gas, 10000), _contractAddr, 0x0, calldatasize, 0, returnSize)
    return(0, returnSize)
  }
}
```
d. Finally the current version of UpgradeableVX.getUint() is called and the value returned right through to the calling contract, StaticExternalInterface.sol
```
// UpgradeableV1.sol
function getUint() returns(uint) {
  return 1;
}
```

__3. Upgrades and Rollbacks__

All upgrades and rollbacks are executed by calling the relay direct. Relay.sol is the central location to handle the current version of the contract being interacted with.

a. Upgrade to a new contract version. Current contract address updated and version number saved.
```
// test_upgradeable.js
await relay.upgrade(2, upgradeableV2.address)

// Relay.sol
function upgrade(
  uint _versionNumber,
  address _newContract
) public {
  contractVersions_[_versionNumber] = _newContract;
  currentContract_ = _newContract;
}
```

b. Rollback to an existing version. Current contract address updated to a version number that exists.
```
// test_upgradeable.js
await relay.rollback(1, upgradeableV2.address)

// Relay.sol
function rollback(
  uint _versionNumber
) external {
  currentContract_ = contractVersions_[_versionNumber];
}
```
