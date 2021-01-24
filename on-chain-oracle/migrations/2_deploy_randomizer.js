var Randomizer = artifacts.require("../contracts/library/Randomizer.sol");

module.exports = function (deployer, network) {
  deployer.deploy(Randomizer)
    .then(() => Randomizer.deployed());
};