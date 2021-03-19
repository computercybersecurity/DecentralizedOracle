require("dotenv").config();
const fetch = require("node-fetch");

import {
  updateRequest,
  newRequest,
  newOracle
} from "./ethereum";

const start = async () => {
  await newOracle();

  newRequest(async (error, event) => {
    console.log(event.returnValues);
    try {
      const { id, queries, qtype } = event.returnValues;
      const queriesJSON = JSON.parse(queries);
      const idx = Math.floor(Math.random() * queriesJSON.length);
      const query = queriesJSON[idx];

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
        valueRetrieved: parseInt(qtype) === 0 ? valueRetrieved.toString() : "",
        priceRetrieved: parseInt(qtype) === 1 ? `0x${Math.floor(parseFloat(valueRetrieved) * 1e18).toString(16)}` : 0
      });
    }
    catch(error) {
      console.log(error);
    }
  });
};

export default start;