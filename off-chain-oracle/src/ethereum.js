require('dotenv').config();
var Web3 = require('web3');

const eventProvider = new Web3.providers.WebsocketProvider(process.env.WEB3_PROVIDER_ADDRESS);
const web3 = new Web3(eventProvider);
const oracle_abi = JSON.parse(process.env.ABI);
const oracle_address = process.env.CONTRACT_ADDRESS;
const oracle_contract = new web3.eth.Contract(oracle_abi, oracle_address);

const deor_abi = JSON.parse(process.env.DEOR_ABI);
const deor_address = process.env.DEOR_ADDRESS;
const deor_contract = new web3.eth.Contract(deor_abi, deor_address);

const privateKey = process.env.PRIVATE_KEY;
const oracleName = process.env.ORACLE_NAME;
const maxSupply = 100000000 * 1e10;

const account = () => {
  return new Promise(async (resolve, reject) => {
    try {
      const account = await web3.eth.accounts.privateKeyToAccount(privateKey);
      await web3.eth.accounts.wallet.add(privateKey);

      if (web3.eth.defaultAccount == account.address) {
        resolve(account);
      }
      web3.eth.defaultAccount = account.address;

      deor_contract.methods.allowance(account.address, oracle_address).call({
        from: account.address
      }, (err, res) => {
        if (parseFloat(res) < maxSupply) {
          deor_contract.methods.approve(oracle_address, maxSupply.toString()).send({
            from: account.address,
            gas: 500000
          }, (err, res) => {
            console.log(err);
            if (!err) {
              resolve(account);
            }
            else {
              reject(err);
            }
          });
        }
        else {
          resolve(account);
        }
      });
    }
    catch (err) {
      reject(err);
    }
  });
};

module.exports.newOracle = () => {
  return new Promise((resolve, reject) => {
    account().then(account => {
      oracle_contract.methods.newOracle(oracleName).send({
        from: account.address,
        gas: 600000
      }, (err, res) => {
        if (err === null) {
          resolve(res);
        } else {
          reject(err);
        }
      });
    }).catch(error => reject(error));
  });
}

module.exports.createRequest = ({
  urlToQuery,
  attributeToFetch
}) => {
  return new Promise((resolve, reject) => {
    account().then(account => {
      oracle_contract.methods.createRequest(urlToQuery, attributeToFetch).send({
        from: account.address,
        gas: 1000000
      }, (err, res) => {
        if (err === null) {
          resolve(res);
        } else {
          reject(err);
        }
      });
    }).catch(error => reject(error));
  });
};

module.exports.updateRequest = ({
  id,
  valueRetrieved
}) => {
  return new Promise((resolve, reject) => {
    account().then(account => {
      oracle_contract.methods.updateRequest(id, valueRetrieved).send({
        from: account.address,
        gas: 1000000
      }, (err, res) => {
        if (err === null) {
          resolve(res);
        } else {
          reject(err);
        }
      });
    }).catch(error => reject(error));
  });
};

module.exports.newRequest = (callback) => {
  oracle_contract.events.NewRequest({}, callback);
};

module.exports.updatedRequest = (callback) => {
  oracle_contract.events.UpdatedRequest({}, callback);
};