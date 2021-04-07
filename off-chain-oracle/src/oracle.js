require("dotenv").config();
const fetch = require("node-fetch");

import {
  updateRequest,
  newRequest,
  isOracleAvailable,
  updateOracleActiveTime
} from "./ethereum.js";

const getFetchParameters = (query) => {
  let url = "";
  let method = "GET";
  let body = undefined;
  let attributes = [];

  if (query.type === 'uniswap-v2') {
    url = "https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v2";
    method = "POST";
    body = `{\"query\":\"{\n pair(id: \"${query.pair}\"){\n token1Price\n }\n}\"}`;
    attributes = [
      {
          "type": "object",
          "object": "data"
      },
      {
          "type": "object",
          "object": "pair"
      },
      {
          "type": "object",
          "object": "token1Price"
      }
    ];
  }
  else if (query.type === 'binance') {
    url = "https://api.binance.com/api/v3/ticker/price";
    method = "GET";
    attributes=[
      {
          "type": "array",
          "searchBy": "symbol",
          "value": query.symbol
      },
      {
          "type": "object",
          "object": "price"
      }
    ];
  }

  return {
    url,
    method,
    body,
    attributes
  }
}

const start = async () => {
  let isAvailable = await isOracleAvailable();

  console.log("===== Is Available =====");
  console.log(isAvailable);

  if (isAvailable) {
    await updateOracleActiveTime();
  }

  newRequest(async (error, event) => {
    console.log(event.returnValues);
    try {
      const { id, queries } = event.returnValues;
      const queriesJSON = JSON.parse(queries);
      const idx = Math.floor(Math.random() * queriesJSON.length);
      const query = getFetchParameters(queriesJSON[idx]);

      const rawResponse = await fetch(query.url, {
        method: query.method,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: query.body
      })

      let valueRetrieved = await rawResponse.json();

      query.attributes && query.attributes.map((att) => {
        if (att["type"] === 'array') {
          if (!att["searchBy"] || att["searchBy"].length === 0) {
            valueRetrieved = valueRetrieved[att["value"]];
          }
          else {
            var updatedValue = null;
            valueRetrieved && valueRetrieved.map((curValue) => {
              if (curValue[att["searchBy"]] === att["value"]) {
                updatedValue = curValue;
              }
            })
            valueRetrieved = updatedValue;
          }
        }
        else if (att["type"] === 'object') {
          valueRetrieved = valueRetrieved[att["object"]];
        }
      })

      console.log(valueRetrieved)

      updateRequest({
        id, 
        priceRetrieved: `0x${Math.floor(parseFloat(valueRetrieved) * 1e18).toString(16)}`
      });
    }
    catch(error) {
      console.log(error);
    }
  });
};

export default start;