var SelectionDEOR = artifacts.require("../contracts/library/SelectionDEOR.sol");

module.exports = function (deployer, network) {
  deployer.deploy(SelectionDEOR)
    .then(() => SelectionDEOR.deployed())
};