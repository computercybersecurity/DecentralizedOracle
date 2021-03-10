var fs = require('fs');
var Ownable = artifacts.require("../contracts/library/Ownable.sol");
var Randomizer = artifacts.require("../contracts/library/Randomizer.sol");
var Selection = artifacts.require("../contracts/library/Selection.sol");
var SafeMathDEOR = artifacts.require("../contracts/library/SafeMathDEOR.sol");
var Oracle = artifacts.require("../contracts/Oracle.sol");
var Oracles = artifacts.require("../contracts/Oracles.sol");
var DEOR = artifacts.require("../contracts/DEOR.sol");
var Upgradable = artifacts.require("../contracts/Upgradable.sol");
var PriceFeed = artifacts.require("../contracts/PriceFeed.sol");
var DataQuery = artifacts.require("../contracts/DataQuery.sol");

const configs = require("../config.json");

module.exports = async function (deployer, network) {
  try {
		let dataParse = {};

    await deployer.deploy(Ownable);
    await deployer.link(Ownable, [Oracle, DEOR]);
    dataParse['Ownable'] = Ownable.address;  

    await deployer.deploy(Randomizer);
    await deployer.link(Randomizer, Selection);
    dataParse['Randomizer'] = Randomizer.address;  
  
    await deployer.deploy(Selection);
    await deployer.link(Selection, Oracle);
    dataParse['Selection'] = Selection.address;  

    await deployer.deploy(SafeMathDEOR);
    await deployer.link(SafeMathDEOR, [DEOR, Oracle]);
    dataParse['SafeMathDEOR'] = SafeMathDEOR.address;  

    if (!configs.DEOR) {
      await deployer.deploy(DEOR);
      dataParse['DEOR'] = DEOR.address;  
    }
    else {
      dataParse['DEOR'] = configs.DEOR;
    }
  
    if (!configs.Oracles) {
      await deployer.deploy(Oracles);
      dataParse['Oracles'] = Oracles.address;  
    }
    else {
      dataParse['Oracles'] = configs.Oracles;
    }

    await deployer.deploy(Oracle, dataParse['DEOR'], dataParse['Oracles']);  
    dataParse['Oracle'] = Oracle.address;

    await deployer.deploy(Upgradable, dataParse['Oracle']);
    dataParse['Upgradable'] = Upgradable.address;

    await deployer.deploy(PriceFeed, "ETHUSDT");
    dataParse['ETHUSDT'] = PriceFeed.address;

    await deployer.deploy(DataQuery, "ETHUSDT");
    dataParse['DataQuery'] = DataQuery.address;

    const updatedData = JSON.stringify(dataParse);
		await fs.promises.writeFile('contracts.json', updatedData);
  } catch (error) {
    console.log(error);
  }
};