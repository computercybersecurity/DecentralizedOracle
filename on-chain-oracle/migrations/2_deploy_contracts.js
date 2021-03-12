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

    await deployer.deploy(Ownable, {
      gas: 1000000
    });
    await deployer.link(Ownable, [Oracle, DEOR]);
    dataParse['Ownable'] = Ownable.address;  

    await deployer.deploy(Randomizer, {
      gas: 3000000
    });
    await deployer.link(Randomizer, Selection);
    dataParse['Randomizer'] = Randomizer.address;  
  
    await deployer.deploy(Selection, {
      gas: 3000000
    });
    await deployer.link(Selection, Oracle);
    dataParse['Selection'] = Selection.address;  

    await deployer.deploy(SafeMathDEOR, {
      gas: 1000000
    });
    await deployer.link(SafeMathDEOR, [DEOR, Oracle]);
    dataParse['SafeMathDEOR'] = SafeMathDEOR.address;  

    if (!configs.DEOR) {
      await deployer.deploy(DEOR, {
        gas: 5000000
      });
      dataParse['DEOR'] = DEOR.address;  
    }
    else {
      dataParse['DEOR'] = configs.DEOR;
    }
  
    if (!configs.Oracles) {
      await deployer.deploy(Oracles, {
        gas: 5000000
      });
      dataParse['Oracles'] = Oracles.address;  
    }
    else {
      dataParse['Oracles'] = configs.Oracles;
    }

    await deployer.deploy(Oracle, dataParse['DEOR'], dataParse['Oracles'], {
      gas: 5000000
    });  
    dataParse['Oracle'] = Oracle.address;

    await deployer.deploy(Upgradable, dataParse['Oracle'], {
      gas: 1000000
    });
    dataParse['Upgradable'] = Upgradable.address;

    // await deployer.deploy(PriceFeed, dataParse['Upgradable'], "ETHUSDT", {
    //   gas: 1000000
    // });
    // dataParse['ETHUSDT'] = PriceFeed.address;

    // await deployer.deploy(DataQuery, dataParse['Upgradable'], "ETHUSDT", {
    //   gas: 1000000
    // });
    // dataParse['DataQuery'] = DataQuery.address;

    const updatedData = JSON.stringify(dataParse);
		await fs.promises.writeFile('contracts.json', updatedData);
  } catch (error) {
    console.log(error);
  }
};