var fs = require('fs');
var Ownable = artifacts.require("../contracts/library/Ownable.sol");
var Randomizer = artifacts.require("../contracts/library/Randomizer.sol");
var Selection = artifacts.require("../contracts/library/Selection.sol");
var SafeMathDEOR = artifacts.require("../contracts/library/SafeMathDEOR.sol");
var Oracle = artifacts.require("../contracts/Oracle.sol");
var DEOR = artifacts.require("../contracts/DEOR.sol");
var Crowdsale = artifacts.require("../contracts/Crowdsale.sol");

module.exports = async function (deployer, network) {
  try {
		let dataParse = {};

    let ownable = await deployer.deploy(Ownable);
    await deployer.link(Ownable, [Oracle, DEOR, Crowdsale]);
    dataParse['Ownable'] = Ownable.address;
  
    let randomizer = await deployer.deploy(Randomizer);
    await deployer.link(Randomizer, Selection);
    dataParse['Randomizer'] = Randomizer.address;
  
    let selection = await deployer.deploy(Selection);
    await deployer.link(Selection, Oracle);
    dataParse['Selection'] = Selection.address;
    
    let safemath = await deployer.deploy(SafeMathDEOR);
    await deployer.link(SafeMathDEOR, [DEOR, Oracle, Crowdsale]);
    dataParse['SafeMathDEOR'] = SafeMathDEOR.address;

    let deor = await deployer.deploy(DEOR);
    dataParse['DEOR'] = DEOR.address;
  
    let crowdsale = await deployer.deploy(Crowdsale, dataParse['DEOR']);
    dataParse['Crowdsale'] = Crowdsale.address;
  
    let oracle = await deployer.deploy(Oracle, dataParse['DEOR']);  
    dataParse['Oracle'] = Oracle.address;

    const updatedData = JSON.stringify(dataParse);
		await fs.promises.writeFile('contracts.json', updatedData);
  } catch (error) {
    console.log(error);
  }
};