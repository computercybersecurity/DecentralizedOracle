var SafeMathDEOR = artifacts.require("../contracts/library/SafeMathDEOR.sol");
var Oracle = artifacts.require("../contracts/Oracle.sol");

module.exports = function (deployer, network) {
  deployer.link(SafeMathDEOR, Oracle);
  deployer.deploy(Oracle);
};