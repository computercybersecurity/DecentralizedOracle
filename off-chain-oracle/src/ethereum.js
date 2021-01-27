require("dotenv").config();

import Web3 from "web3";


const web3 = new Web3(new Web3.providers.HttpProvider(process.env.WEB3_PROVIDER_ADDRESS));
const abi = JSON.parse(process.env.ABI);
const address = process.env.CONTRACT_ADDRESS;
const contract = new web3.eth.Contract(abi, address);
const privateKey = process.env.PRIVATE_KEY;

const account = () => {
  return new Promise(async (resolve, reject) => {
    try {
      const account = await web3.eth.accounts.privateKeyToAccount(privateKey);
      resolve(account);
    }
    catch (err) {
      reject(err);
    }
  });
};

export const createRequest = ({
  requestType,
  urlToQuery,
  requestMethod,
  requestBody,
  attributeToFetch
}) => {
  return new Promise((resolve, reject) => {
    account().then(account => {
      contract.methods.createRequest(requestType, urlToQuery, requestMethod, requestBody, attributeToFetch).call({
        from: account.address,
        gas: 60000000
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

export const updateRequest = ({
  id,
  valueRetrieved,
  priceRetrieved
}) => {
  return new Promise((resolve, reject) => {
    account().then(account => {
      contract.methods.updateRequest(id, valueRetrieved, priceRetrieved).call({
        from: account,
        gas: 60000000
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

export const newRequest = (callback) => {
  contract.NewRequest((error, result) => callback(error, result));
};

export const updatedRequest = (callback) => {
  contract.UpdatedRequest((error, result) => callback(error, result));
};