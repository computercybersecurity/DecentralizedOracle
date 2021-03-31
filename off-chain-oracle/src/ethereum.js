require('dotenv').config();
var Web3 = require('web3');

const eventProvider = new Web3.providers.WebsocketProvider(process.env.WEB3_PROVIDER_ADDRESS);
const web3 = new Web3(eventProvider);

const contract_abi = JSON.parse(process.env.CONTRACT_ABI);
const contract_address = process.env.CONTRACT_ADDRESS;
const upgradable_contract = new web3.eth.Contract(contract_abi, contract_address);

const oracle_abi = JSON.parse(process.env.ORACLE_ABI);
let oracle_address = "";

const oracles_abi = JSON.parse(process.env.ORACLES_ABI);
const oracles_address = process.env.ORACLES_ADDRESS;

const deor_abi = JSON.parse(process.env.DEOR_ABI);
const deor_address = process.env.DEOR_ADDRESS;
const deor_contract = new web3.eth.Contract(deor_abi, deor_address);

const privateKey = process.env.PRIVATE_KEY;
const oracleName = process.env.ORACLE_NAME;
const maxSupply = 100000000 * 1e10;

const gasPrice = process.env.GAS_PRICE;

const getAccount = async () => {
  try {
    const account = await web3.eth.accounts.privateKeyToAccount(privateKey);
    await web3.eth.accounts.wallet.add(privateKey);

    oracle_address = await upgradable_contract.methods.oracle().call({from: account.address});

    if (web3.eth.defaultAccount == account.address) {
      return account.address;
    }

    web3.eth.defaultAccount = account.address;

    const allowed = await deor_contract.methods.allowance(account.address, oracle_address).call({from: account.address});

    if (parseFloat(allowed) < maxSupply) {
      await deor_contract.methods.approve(oracle_address, maxSupply.toString()).send({
        from: account.address,
        gas: 500000,
        gasPrice: web3.toWei(gasPrice, 'gwei')
      });
    }
    return account.address;
  }
  catch (err) {
    console.log(err);
    return null;
  }
};

module.exports.isOracleAvailable = async () => {
  try {
    const account = await getAccount();
    const oracles_contract = new web3.eth.Contract(oracles_abi, oracles_address);
    return await oracles_contract.methods.isOracleAvailable(account).call({
      from: account
    }); 
  } catch (err) {
    console.log(err);
  }
}

module.exports.updateOracleActiveTime = async () => {
  try {
    const account = await getAccount();
    const oracles_contract = new web3.eth.Contract(oracles_abi, oracles_address);
    await oracles_contract.methods.updateOracleLastActiveTime(account).send({
      from: account,
      gas: 50000,
      gasPrice: web3.toWei(gasPrice, 'gwei')
    }); 
  } catch (err) {
    console.log(err);
  }
}

module.exports.newOracle = async () => {
  try {
    const account = await getAccount();
    const oracle_contract = new web3.eth.Contract(oracle_abi, oracle_address);
    console.log(oracle_address);
    await oracle_contract.methods.newOracle(oracleName).send({
      from: account,
      gas: 100000,
      gasPrice: web3.toWei(gasPrice, 'gwei')
    });  
  } catch (err) {
    console.log(err);
  }
}

module.exports.createRequest = async ({
  queries,
  qtype,
  contractAddr
}) => {
  try {
    console.log('===== createRequest =====');
    console.log(queries, qtype, contractAddr)
    const account = await getAccount();
    const oracle_contract = new web3.eth.Contract(oracle_abi, oracle_address);
    oracle_contract.methods.createRequest(queries, qtype, contractAddr.length > 0 ? contractAddr : 0x01).send({
      from: account,
      gas: 1000000,
      gasPrice: web3.toWei(gasPrice, 'gwei')
    }, (err, res) => {
      if (!err) {
        console.log(res);
      } else {
        console.log(err);
      }
    });  
  } catch (err) {
    console.log(err);
  }
};

module.exports.updateRequest = async ({
  id,
  valueRetrieved,
  priceRetrieved
}) => {
  try {
    console.log('===== updateRequest =====');
    const account = await getAccount();
    const oracle_contract = new web3.eth.Contract(oracle_abi, oracle_address);
    await oracle_contract.methods.updateRequest(id, valueRetrieved, priceRetrieved).send({
      from: account,
      gas: 1000000,
      gasPrice: web3.toWei(gasPrice, 'gwei')
    }, (err, res) => {
      if (!err) {
        console.log(res);
      } else {
        console.log(err);
      }
    });
  } catch (err) {
    console.log(err);
  }
};

module.exports.newRequest = (callback) => {
  const oracle_contract = new web3.eth.Contract(oracle_abi, oracle_address);
  oracle_contract.events.NewRequest({}, callback);
};

module.exports.updatedRequest = (callback) => {
  const oracle_contract = new web3.eth.Contract(oracle_abi, oracle_address);
  oracle_contract.events.UpdatedRequest({}, callback);
};