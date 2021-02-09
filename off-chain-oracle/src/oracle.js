require("dotenv").config();
const fetch = require("node-fetch");

import {
  updateRequest,
  newRequest,
  newOracle
} from "./ethereum";

const start = () => {
  newOracle();

  newRequest(async (error, event) => {
    console.log(error, event);
    try {
      const { id, urlToQuery, attributeToFetch } = event.returnValues;

      const rawResponse = await fetch(urlToQuery, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        }
      })

      let valueRetrieved = await rawResponse.json();
      const fetchParams = attributeToFetch.split(".");

      fetchParams.forEach((cur) => {
        valueRetrieved = valueRetrieved[cur];
      })

      updateRequest({
        id, 
        valueRetrieved: (valueRetrieved || 0).toString()
      });  
    }
    catch(error) {
      console.log(error);
    }
  });
};

export default start;