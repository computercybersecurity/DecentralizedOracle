var SafeMathDEOR = artifacts.require("../contracts/library/SafeMathDEOR.sol");

module.exports = function (deployer, network) {
  deployer.deploy(SafeMathDEOR);
};