require("dotenv").config();

import {
  createRequest
} from "./ethereum";


const start = () => {

  let urlToQuery = process.env.URL_TO_QUERY;
  let requestMethod = process.env.REQUEST_METHOD;
  let requestBody = process.env.REQUEST_BODY;
  let attributeToFetch = process.env.ATTRIBUTE_TO_FETCH;

  createRequest({
      urlToQuery,
      requestMethod,
      requestBody,
      attributeToFetch
    })
    .then(restart)
    .catch(error);
};

const restart = () => {
  wait(process.env.TIMEOUT).then(start);
};

const wait = (milliseconds) => {
  return new Promise((resolve, reject) => setTimeout(() => resolve(), milliseconds));
};

const error = (error) => {
  console.error(error);
  restart();
};

export default start;