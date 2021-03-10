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
    console.log(error, event);
    try {
      const { id, queries, qtype } = event.returnValues;
      const idx = Math.floor(Math.random() * queries.length);
      const query = queries[idx];

      const rawResponse = await fetch(query.url, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        }
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
              if (cur[att["searchBy"]] === att["value"]) {
                updatedValue = curValue;
                break;
              }
            })
            valueRetrieved = updatedValue;
          }
        }
        else if (att["type"] === 'array') {
          valueRetrieved = valueRetrieved[att["object"]];
        }
      })

      updateRequest({
        id, 
        valueRetrieved: qtype === 0 ? valueRetrieved.toString() : "",
        priceRetrieved: qtype === 1 ? Math.floor(parseFloat(valueRetrieved) * 1e18) : 0
      });
    }
    catch(error) {
      console.log(error);
    }
  });
};

export default start;