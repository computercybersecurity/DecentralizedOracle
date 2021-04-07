var fs = require('fs');
var Ownable = artifacts.require("../contracts/library/Ownable.sol");
var Randomizer = artifacts.require("../contracts/library/Randomizer.sol");
var Selection = artifacts.require("../contracts/library/Selection.sol");
var SafeMathDEOR = artifacts.require("../contracts/library/SafeMathDEOR.sol");
var PriceOracle = artifacts.require("../contracts/PriceOracle.sol");
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
    await deployer.link(Ownable, [PriceOracle, DEOR]);
    dataParse['Ownable'] = Ownable.address;  

    await deployer.deploy(Randomizer, {
      gas: 3000000
    });
    await deployer.link(Randomizer, Selection);
    dataParse['Randomizer'] = Randomizer.address;  
  
    await deployer.deploy(Selection, {
      gas: 3000000
    });
    await deployer.link(Selection, PriceOracle);
    dataParse['Selection'] = Selection.address;  

    await deployer.deploy(SafeMathDEOR, {
      gas: 1000000
    });
    await deployer.link(SafeMathDEOR, [DEOR, PriceOracle]);
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

    if (!configs.PriceOracle) {
      await deployer.deploy(PriceOracle, dataParse['DEOR'], dataParse['Oracles'], {
        gas: 5000000
      });  
      dataParse['PriceOracle'] = PriceOracle.address;
    }
    else {
      dataParse['PriceOracle'] = configs.PriceOracle;
    }

    if (!configs.Upgradable) {
      await deployer.deploy(Upgradable, dataParse['PriceOracle'], {
        gas: 1000000
      });
      dataParse['Upgradable'] = Upgradable.address;
    }
    else {
      dataParse['Upgradable'] = configs.Upgradable;
    }

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