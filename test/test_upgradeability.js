const StaticExternalInterface = artifacts.require("./StaticExternalInterface.sol")
const Relay = artifacts.require("./Relay.sol")
const UpgradeableV1 = artifacts.require("./UpgradeableV1.sol")
const UpgradeableV2 = artifacts.require("./UpgradeableV2.sol")
let response

contract('Upgradeable Contracts', accounts => {

  /**
   * Non upgradeable pattern
   */
  it("should access the upgrade contract in a non upgradeable pattern!", async () => {
    const upgradeableV1 = await UpgradeableV1.new()
    const staticExternalInterface = await StaticExternalInterface.new(upgradeableV1.address)

    response = await staticExternalInterface.getUint.call()
    assert.equal(response.toNumber(), 1, 'upgrapdeable v1 incorrect')
  });

  /**
   * Upgradeable
   */
  it("should upgrade from v1 to v2", async () => {
    const upgradeableV1 = await UpgradeableV1.new()
    const relay = await Relay.new(upgradeableV1.address)
    const staticExternalInterface = await StaticExternalInterface.new(relay.address)
    await relay.addReturnDataSize('getUint()', 32)

    // First version returns 1
    response = await staticExternalInterface.getUint.call()
    assert.equal(response.toNumber(), 1, 'upgrapdeable v1 incorrect')

    // Upgrade to v2
    const upgradeableV2 = await UpgradeableV2.new()
    await relay.upgrade(2, upgradeableV2.address)

    // Second version returns 2
    response = await staticExternalInterface.getUint.call()
    assert.equal(response.toNumber(), 2, 'upgrapdeable v2 incorrect')
  });

  /**
   * Versioning
   */
  it("should upgrade from v1 to v2 and rollback to v1", async () => {
    const upgradeableV1 = await UpgradeableV1.new()
    const relay = await Relay.new(upgradeableV1.address)
    const staticExternalInterface = await StaticExternalInterface.new(relay.address)
    await relay.addReturnDataSize('getUint()', 32)

    // First version returns 1
    response = await staticExternalInterface.getUint.call()
    assert.equal(response.toNumber(), 1, 'Initial v1 incorrect')

    // Upgrade to v2
    const upgradeableV2 = await UpgradeableV2.new()
    await relay.upgrade(2, upgradeableV2.address)

    // Second version returns 2
    response = await staticExternalInterface.getUint.call()
    assert.equal(response.toNumber(), 2, 'upgrapded v2 incorrect')

    // Rollback to v1
    await relay.rollback(1, upgradeableV2.address)

    // Second version returns 2
    response = await staticExternalInterface.getUint.call()
    assert.equal(response.toNumber(), 1, 'rollback v1 incorrect')
  });
});
