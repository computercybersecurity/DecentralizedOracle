require('dotenv').config();
var Web3 = require('web3');

const eventProvider = new Web3.providers.WebsocketProvider(process.env.WEB3_PROVIDER_ADDRESS);
const web3 = new Web3(eventProvider);

const contract_abi = JSON.parse(process.env.CONTRACT_ABI);
const contract_address = process.env.CONTRACT_ADDRESS;
const upgradable_contract = new web3.eth.Contract(contract_abi, contract_address);

const oracle_abi = JSON.parse(process.env.ORACLE_ABI);
let oracle_address = "";

const deor_abi = JSON.parse(process.env.DEOR_ABI);
const deor_address = process.env.DEOR_ADDRESS;
const deor_contract = new web3.eth.Contract(deor_abi, deor_address);

const privateKey = process.env.PRIVATE_KEY;
const oracleName = process.env.ORACLE_NAME;
const maxSupply = 100000000 * 1e10;

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
        gas: 500000
      });
    }
    return account.address;
  }
  catch (err) {
    console.log(err);
    return null;
  }
};

module.exports.newOracle = async () => {
  try {
    const account = await getAccount();
    const oracle_contract = new web3.eth.Contract(oracle_abi, oracle_address);
    await oracle_contract.methods.newOracle(oracleName).send({
      from: account,
      gas: 600000
    });  
  } catch (err) {
    console.log(err);
  }
}

module.exports.createRequest = async ({
  urlToQuery,
  attributeToFetch
}) => {
  try {
    const account = await getAccount();
    const oracle_contract = new web3.eth.Contract(oracle_abi, oracle_address);
    await oracle_contract.methods.createRequest(urlToQuery, attributeToFetch).send({
      from: account,
      gas: 1000000
    });  
  } catch (err) {
    console.log(err);
  }
};

module.exports.updateRequest = async ({
  id,
  valueRetrieved
}) => {
  try {
    const account = await getAccount();
    const oracle_contract = new web3.eth.Contract(oracle_abi, oracle_address);
    oracle_contract.methods.updateRequest(id, valueRetrieved).send({
      from: account,
      gas: 1000000
    }, (err, res) => {
      if (err === null) {
        resolve(res);
      } else {
        reject(err);
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
  console.log(oracle_address);
  const oracle_contract = new web3.eth.Contract(oracle_abi, oracle_address);
  oracle_contract.events.UpdatedRequest({}, callback);
};