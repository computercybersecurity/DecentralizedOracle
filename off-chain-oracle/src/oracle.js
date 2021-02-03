require("dotenv").config();

import {
  updateRequest,
  newRequest,
  newOracle
} from "./ethereum";

const start = () => {
  newOracle();

  newRequest(async (error, result) => {
    try {
      const { id, requestType, params } = result.args;

      if (requestType == "DataQuery") {
        if (params.length > 0 ) {
          const rawResponse = await fetch(params[0].urlToQuery, {
            method: 'GET',
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json'
            }
          })
    
          let valueRetrieved = await rawResponse.json();
          const fetchParams = params[0].attributeToFetch.split(".");
    
          fetchParams.forEach((cur) => {
            valueRetrieved = valueRetrieved[cur];
          })

          updateRequest({
            id, 
            valueRetrieved: (valueRetrieved || 0).toString(),
            priceRetrieved: 0
          });  
        }
      }
      else if (requestType == "PriceFeed") {
        var sum = 0.0;
        params.length > 0 && params.map(async (param) => {
          const rawResponse = await fetch(param.urlToQuery, {
            method: 'GET',
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json'
            }
          })
    
          let valueRetrieved = await rawResponse.json();
          const fetchParams = param.attributeToFetch.split(".");
    
          fetchParams.forEach((cur) => {
            valueRetrieved = valueRetrieved[cur];
          })

          sum += parseFloat(valueRetrieved);
        })

        updateRequest({
          id,
          valueRetrieved: "",
          priceRetrieved: Math.floor(sum * Math.pow(10, 18) / params.length)
        });
      }
    }
    catch(error) {
      console.log(error);
    }
  });
};

export default start;