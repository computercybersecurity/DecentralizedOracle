var SafeMathDEOR = artifacts.require("../contracts/library/SafeMathDEOR.sol");
var DEOR = artifacts.require("../contracts/DEOR.sol");

module.exports = function (deployer, network) {
  deployer.link(SafeMathDEOR, DEOR);
  deployer.deploy(DEOR);
};