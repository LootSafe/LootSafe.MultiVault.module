const MultiVault = artifacts.require("./MultiVault.sol")

module.exports = function(deployer) {
  deployer.deploy(MultiVault)
};
