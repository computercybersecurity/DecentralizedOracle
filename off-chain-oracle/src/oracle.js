require("dotenv").config();

import {
  updateRequest,
  newRequest
} from "./ethereum";

const start = () => {

  newRequest(async (error, result) => {
    try {
      const { id, requestType, urlToQuery, requestMethod, requestBody, attributeToFetch } = result.args;

      const rawResponse = await fetch(urlToQuery, {
        method: requestMethod,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: requestBody
      })

      let valueRetrieved = await rawResponse.json();
      const params = attributeToFetch.split(".");

      params.forEach((param) => {
        valueRetrieved = valueRetrieved[param];
      })

      if (requestType == "DataQuery") {
        updateRequest({
          id, 
          valueRetrieved: (valueRetrieved || 0).toString(),
          priceRetrieved: 0
        });
      }
      else if (requestType == "PriceFeed") {
        updateRequest({
          id,
          valueRetrieved: "",
          priceRetrieved: Math.floor(parseFloat(valueRetrieved) * Math.pow(10, 18))
        });
      }
    }
    catch(error) {
      console.log(error);
    }
  });
};

export default start;